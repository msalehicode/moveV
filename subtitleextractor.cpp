#include "subtitleextractor.h"

#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <QStringList>
#include <QRegularExpression>

    // FFmpeg
    extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}


// ------------------------------------------------------------
// Convert milliseconds to SRT timestamp:
//
// 3723 ms -> 00:00:03,723
// ------------------------------------------------------------
static QString millisecondsToSrt(qint64 milliseconds)
{
    if (milliseconds < 0)
        milliseconds = 0;

    qint64 hours = milliseconds / 3600000;
    milliseconds %= 3600000;

    qint64 minutes = milliseconds / 60000;
    milliseconds %= 60000;

    qint64 seconds = milliseconds / 1000;
    milliseconds %= 1000;

    return QString("%1:%2:%3,%4")
        .arg(hours,   2, 10, QChar('0'))
        .arg(minutes, 2, 10, QChar('0'))
        .arg(seconds, 2, 10, QChar('0'))
        .arg(milliseconds, 3, 10, QChar('0'));
}


// ------------------------------------------------------------
// Remove ASS/SSA formatting from dialogue text.
//
// Example:
//
// {\an8}Hello {\i1}world{\i0}
//
// becomes:
//
// Hello world
// ------------------------------------------------------------
static QString cleanAssText(QString text)
{
    // Remove ASS override tags:
    // {\...}
    QRegularExpression assTags(R"(\{[^}]*\})");
    text.remove(assTags);

    // ASS uses \N for a forced line break.
    text.replace("\\N", "\n");
    text.replace("\\n", "\n");

    // ASS uses \h for a non-breaking space.
    text.replace("\\h", " ");

    return text.trimmed();
}


// ------------------------------------------------------------
// Extract the actual dialogue text from an ASS event.
//
// FFmpeg commonly gives ASS subtitles like:
//
// 0,0,Default,,0,0,0,,Hello world
//
// The text is everything after the final ","
// ------------------------------------------------------------
static QString extractAssDialogueText(const QString &ass)
{
    int separator = ass.lastIndexOf(',');

    if (separator >= 0)
        return cleanAssText(
            ass.mid(separator + 1)
            );

    return cleanAssText(ass);
}


// ------------------------------------------------------------

SubtitleExtractor::SubtitleExtractor(QObject *parent)
    : QObject(parent)
{
}


// ------------------------------------------------------------

QString SubtitleExtractor::extractSubtitle(
    const QString &videoPath,
    int subtitleIndex)
{
    AVFormatContext *formatContext = nullptr;

    const QByteArray path = videoPath.toUtf8();

    // --------------------------------------------------------
    // Open media file
    // --------------------------------------------------------

    int ret = avformat_open_input(
        &formatContext,
        path.constData(),
        nullptr,
        nullptr
        );

    if (ret < 0) {
        qWarning()
        << "FFmpeg: failed to open:"
        << videoPath;

        return QString();
    }


    // --------------------------------------------------------
    // Read stream information
    // --------------------------------------------------------

    ret = avformat_find_stream_info(
        formatContext,
        nullptr
        );

    if (ret < 0) {
        qWarning()
        << "FFmpeg: failed to read stream information";

        avformat_close_input(&formatContext);

        return QString();
    }


    // --------------------------------------------------------
    // Find subtitle stream
    //
    // subtitleIndex is:
    //
    // 0 = first subtitle
    // 1 = second subtitle
    // 2 = third subtitle
    //
    // It is NOT the absolute FFmpeg stream index.
    // --------------------------------------------------------

    int subtitleStreamIndex = -1;
    int currentSubtitleIndex = 0;

    for (unsigned int i = 0;
         i < formatContext->nb_streams;
         ++i)
    {
        AVStream *stream =
            formatContext->streams[i];

        if (stream->codecpar->codec_type
            != AVMEDIA_TYPE_SUBTITLE)
        {
            continue;
        }

        if (currentSubtitleIndex == subtitleIndex) {
            subtitleStreamIndex =
                static_cast<int>(i);

            break;
        }

        ++currentSubtitleIndex;
    }


    if (subtitleStreamIndex < 0) {
        qWarning()
        << "FFmpeg: subtitle stream not found:"
        << subtitleIndex;

        avformat_close_input(&formatContext);

        return QString();
    }


    qDebug()
        << "FFmpeg: using subtitle stream:"
        << subtitleStreamIndex
        << "subtitle index:"
        << subtitleIndex;


    // --------------------------------------------------------
    // Subtitle codec
    // --------------------------------------------------------

    AVStream *subtitleStream =
        formatContext->streams[
            subtitleStreamIndex
    ];

    AVCodecParameters *codecParameters =
        subtitleStream->codecpar;


    const AVCodec *codec =
        avcodec_find_decoder(
            codecParameters->codec_id
            );

    if (!codec) {
        qWarning()
        << "FFmpeg: no subtitle decoder found for codec:"
        << codecParameters->codec_id;

        avformat_close_input(&formatContext);

        return QString();
    }


    // --------------------------------------------------------
    // Allocate decoder context
    // --------------------------------------------------------

    AVCodecContext *codecContext =
        avcodec_alloc_context3(codec);

    if (!codecContext) {
        qWarning()
        << "FFmpeg: failed to allocate codec context";

        avformat_close_input(&formatContext);

        return QString();
    }


    ret = avcodec_parameters_to_context(
        codecContext,
        codecParameters
        );

    if (ret < 0) {
        qWarning()
        << "FFmpeg: failed to copy codec parameters";

        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);

        return QString();
    }


    // --------------------------------------------------------
    // Open decoder
    // --------------------------------------------------------

    ret = avcodec_open2(
        codecContext,
        codec,
        nullptr
        );

    if (ret < 0) {
        qWarning()
        << "FFmpeg: failed to open subtitle decoder";

        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);

        return QString();
    }


    // --------------------------------------------------------
    // Allocate packet
    // --------------------------------------------------------

    AVPacket *packet =
        av_packet_alloc();

    if (!packet) {
        qWarning()
        << "FFmpeg: failed to allocate packet";

        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);

        return QString();
    }


    // --------------------------------------------------------
    // Build SRT result
    // --------------------------------------------------------

    QString result;

    int subtitleNumber = 1;


    // --------------------------------------------------------
    // Read packets
    // --------------------------------------------------------

    while (av_read_frame(
               formatContext,
               packet) >= 0)
    {
        if (packet->stream_index
            != subtitleStreamIndex)
        {
            av_packet_unref(packet);
            continue;
        }


        AVSubtitle subtitle{};

        int gotSubtitle = 0;


        ret = avcodec_decode_subtitle2(
            codecContext,
            &subtitle,
            &gotSubtitle,
            packet
            );


        // Save packet timing before unref.
        qint64 packetPts =
            packet->pts;


        av_packet_unref(packet);


        if (ret < 0)
            continue;

        if (!gotSubtitle)
            continue;


        // ----------------------------------------------------
        // Calculate subtitle start/end time.
        //
        // AVSubtitle timestamps are in milliseconds relative
        // to the packet timing used by the decoder.
        // ----------------------------------------------------

        qint64 startMs =
            subtitle.pts != AV_NOPTS_VALUE
                ? subtitle.pts / 1000
                : packetPts / 1000;

        startMs += subtitle.start_display_time;

        qint64 endMs =
            startMs +
            subtitle.end_display_time;


        // ----------------------------------------------------
        // Make sure end is after start.
        //
        // Some subtitle formats may have zero duration.
        // Give them a reasonable fallback.
        // ----------------------------------------------------

        if (endMs <= startMs)
            endMs = startMs + 3000;


        // ----------------------------------------------------
        // Process subtitle rectangles
        // ----------------------------------------------------

        for (unsigned int i = 0;
             i < subtitle.num_rects;
             ++i)
        {
            AVSubtitleRect *rect =
                subtitle.rects[i];

            if (!rect)
                continue;


            QString text;


            // ------------------------------------------------
            // Normal text subtitle
            // ------------------------------------------------

            if (rect->text) {

                text =
                    QString::fromUtf8(
                        rect->text
                        ).trimmed();
            }


            // ------------------------------------------------
            // ASS / SSA subtitle
            // ------------------------------------------------

            else if (rect->ass) {

                QString ass =
                    QString::fromUtf8(
                        rect->ass
                        );

                text =
                    extractAssDialogueText(
                        ass
                        );
            }


            if (text.isEmpty())
                continue;


            // ------------------------------------------------
            // Generate SRT block
            // ------------------------------------------------

            result += QString::number(
                subtitleNumber++
                );

            result += '\n';

            result += millisecondsToSrt(
                startMs
                );

            result += " --> ";

            result += millisecondsToSrt(
                endMs
                );

            result += '\n';

            result += text;

            result += "\n\n";
        }


        avsubtitle_free(&subtitle);
    }


    // --------------------------------------------------------
    // Cleanup
    // --------------------------------------------------------

    av_packet_free(&packet);

    avcodec_free_context(
        &codecContext
        );

    avformat_close_input(
        &formatContext
        );


    if (result.isEmpty()) {

        qWarning()
        << "FFmpeg: no subtitle text extracted.";

    } else {

        qDebug()
        << "FFmpeg: extracted"
        << subtitleNumber - 1
        << "subtitle entries.";
    }


    return result;
}


// ------------------------------------------------------------

QString SubtitleExtractor::loadSrtFile(
    const QString &srtPath)
{
    QFile file(srtPath);

    if (!file.open(
            QIODevice::ReadOnly |
            QIODevice::Text))
    {
        qWarning()
        << "Failed to open SRT file:"
        << srtPath;

        return QString();
    }


    QTextStream in(&file);

    QString content =
        in.readAll();

    file.close();

    return content;
}
