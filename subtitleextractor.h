#ifndef SUBTITLEEXTRACTOR_H
#define SUBTITLEEXTRACTOR_H

#include <QObject>
#include <QString>

class SubtitleExtractor : public QObject
{
    Q_OBJECT
public:
    explicit SubtitleExtractor(QObject *parent = nullptr);

    Q_INVOKABLE QString extractSubtitle(const QString &videoPath, int subtitleIndex);
    Q_INVOKABLE QString loadSrtFile(const QString &srtPath);

};


#endif // SUBTITLEEXTRACTOR_H
