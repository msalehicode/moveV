#include "subtitleextractor.h"
#include <QProcess>
#include <QStandardPaths>
#include <QFile>
#include <QDebug>
#include <QDir>
#include <QCoreApplication>


#include <QTextStream>



SubtitleExtractor::SubtitleExtractor(QObject *parent) : QObject(parent)
{
}

QString SubtitleExtractor::extractSubtitle(const QString &videoPath, int subtitleIndex)
{
    // Path to bundled FFmpeg binary
    QString ffmpegBinary = "/usr/bin/ffmpeg"; // Linux
    // or "C:/ffmpeg/bin/ffmpeg.exe" on Windows
    // QString ffmpegBinary = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/ffmpeg";

    // Make sure FFmpeg is executable (only needed on Android)
#ifdef Q_OS_ANDROID
    QFile ff(ffmpegBinary);
    if (!ff.exists()) {
        qWarning() << "FFmpeg binary not found in sandbox";
        return QString();
    }
    chmod(ffmpegBinary.toUtf8().constData(), 0755);
#endif

    // Build arguments: extract the specified subtitle track, output SRT to stdout
    QStringList args;
    args << "-i" << videoPath
         << "-map" << QString("0:s:%1").arg(subtitleIndex)
         << "-f" << "srt" << "-";

    QProcess ffmpeg;
    ffmpeg.start(ffmpegBinary, args);
    if (!ffmpeg.waitForStarted()) {
        qWarning() << "Failed to start FFmpeg process";
        return QString();
    }

    if (!ffmpeg.waitForFinished(-1)) {
        qWarning() << "FFmpeg process failed";
        return QString();
    }

    QByteArray output = ffmpeg.readAllStandardOutput();
    QString subtitleText = QString::fromUtf8(output);

    if (subtitleText.isEmpty())
        qWarning() << "No subtitle extracted. Check track index or video file.";

    return subtitleText;
}

QString SubtitleExtractor::loadSrtFile(const QString &srtPath)
{
    QFile file(srtPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qWarning() << "Failed to open SRT file:" << srtPath;
        return QString();
    }

    QTextStream in(&file);
    QString content = in.readAll();
    file.close();

    return content;
}
