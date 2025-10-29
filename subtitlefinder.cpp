#include "subtitlefinder.h"
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QDebug>

static const QStringList qualityPreference = {
    "bluray", "bdrip", "brrip", "web-dl", "webrip", "hdtv", "dvdrip", "pdtv"
};

SubtitleFinder::SubtitleFinder(QObject *parent)
    : QObject(parent)
{
}

QString SubtitleFinder::extractSeasonEpisode(const QString &fileName)
{
    QRegularExpression re("(S\\d{1,2}E\\d{1,2})", QRegularExpression::CaseInsensitiveOption);
    auto match = re.match(fileName);
    if (match.hasMatch())
        return match.captured(1).toLower();

    QRegularExpression re2("(\\d{1,2}x\\d{1,2})", QRegularExpression::CaseInsensitiveOption);
    match = re2.match(fileName);
    if (match.hasMatch())
        return match.captured(1).toLower();

    return {};
}

QString SubtitleFinder::detectQualityTag(const QString &fileName)
{
    QString lower = fileName.toLower();
    for (const QString &tag : qualityPreference) {
        if (lower.contains(tag))
            return tag;
    }
    return QString();
}

int SubtitleFinder::computeMatchScore(const QString &subtitleName, const QString &videoName,
                                      const QString &videoQuality)
{
    QString lowerSub = subtitleName.toLower();
    QString lowerVid = videoName.toLower();

    int score = 0;

    // ✅ Boost score if show name tokens match (ignoring dots and spaces)
    QString baseVid = lowerVid;
    baseVid.replace('.', ' ').replace('_', ' ');
    if (lowerSub.contains(baseVid.section(' ', 0, 1)))  // partial title match
        score += 5;

    // ✅ Bonus if subtitle contains same quality tag
    if (!videoQuality.isEmpty() && lowerSub.contains(videoQuality))
        score += 10;

    // ✅ Otherwise, approximate based on distance in qualityPreference
    if (!videoQuality.isEmpty()) {
        for (int i = 0; i < qualityPreference.size(); ++i) {
            if (lowerSub.contains(qualityPreference[i])) {
                int diff = std::abs(i - qualityPreference.indexOf(videoQuality));
                score += std::max(0, 8 - diff);  // closer = higher
                break;
            }
        }
    }

    // ✅ Bonus if subtitle name also contains same resolution (e.g., 720p, 1080p)
    QRegularExpression resRe("(480p|576p|720p|1080p|2160p)");
    auto match = resRe.match(lowerVid);
    if (match.hasMatch() && lowerSub.contains(match.captured(1)))
        score += 6;

    return score;
}

QStringList SubtitleFinder::findMatchingSubtitles(const QString &videoPath)
{
    QString filePath = videoPath;
    if (filePath.startsWith("file://"))
        filePath = filePath.mid(7);

    QFileInfo info(filePath);
    QString dirPath = info.absolutePath();
    QString fileName = info.fileName();

    QString episodeCode = extractSeasonEpisode(fileName);
    QString videoQuality = detectQualityTag(fileName);

    if (episodeCode.isEmpty()) {
        qDebug() << "No season/episode info found in:" << fileName;
        return {};
    }

    // qDebug() << "Looking for exact patterns around:" << episodeCode
             // << " videoQuality:" << videoQuality;

    // Equivalent patterns
    QStringList possiblePatterns;
    possiblePatterns << episodeCode;

    QRegularExpression sRe("s(\\d{1,2})e(\\d{1,2})", QRegularExpression::CaseInsensitiveOption);
    auto match = sRe.match(episodeCode);
    if (match.hasMatch()) {
        int season = match.captured(1).toInt();
        int episode = match.captured(2).toInt();
        possiblePatterns << QString("%1x%2").arg(season).arg(episode, 2, 10, QChar('0'));
        possiblePatterns << QString("%1x%2").arg(season).arg(episode);
    }

    QDir dir(dirPath);
    QStringList filters = {"*.srt", "*.sub"};
    QFileInfoList list = dir.entryInfoList(filters, QDir::Files);

    QList<SubtitleMatch> foundSubs;

    for (const QFileInfo &f : list) {
        QString lower = f.fileName().toLower();

        for (const QString &pat : possiblePatterns) {
            QString regexPattern = QString("(^|[ ._\\-\\[\\(])%1($|[ ._\\-\\]\\)])")
            .arg(QRegularExpression::escape(pat));
            QRegularExpression re(regexPattern, QRegularExpression::CaseInsensitiveOption);

            if (re.match(lower).hasMatch()) {
                int score = computeMatchScore(f.fileName(), fileName, videoQuality);
                foundSubs.append({f.absoluteFilePath(), score});
                // qDebug() << "Subtitle match:" << f.absoluteFilePath() << "score=" << score;
                break;
            }
        }
    }

    // Sort best → worst
    std::sort(foundSubs.begin(), foundSubs.end(), [](const SubtitleMatch &a, const SubtitleMatch &b) {
        return a.score > b.score;
    });

    QStringList result;
    for (const auto &m : foundSubs)
        result << m.path;

    return result;
}
