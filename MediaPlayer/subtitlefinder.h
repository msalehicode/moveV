#ifndef SUBTITLEFINDER_H
#define SUBTITLEFINDER_H

#include <QObject>

class SubtitleFinder : public QObject
{
    Q_OBJECT
public:
    explicit SubtitleFinder(QObject *parent = nullptr);

signals:
};

#endif // SUBTITLEFINDER_H
