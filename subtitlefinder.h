#ifndef SUBTITLEFINDER_H
#define SUBTITLEFINDER_H

#include <QObject>

#include <QString>
#include <QStringList>

struct SubtitleMatch {
    QString path;
    int score;
};

class SubtitleFinder : public QObject {
    Q_OBJECT
public:
    explicit SubtitleFinder(QObject *parent = nullptr);

    Q_INVOKABLE QStringList findMatchingSubtitles(const QString &videoPath);

private:
    QString extractSeasonEpisode(const QString &fileName);
    QString detectQualityTag(const QString &fileName);
    int computeMatchScore(const QString &subtitleName, const QString &videoName,
                          const QString &videoQuality);
};


#endif // SUBTITLEFINDER_H


