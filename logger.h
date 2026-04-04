#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QFile>
#include <QMutex>
#include <QDateTime>
#include <QTextStream>

class Logger : public QObject
{
    Q_OBJECT
public:
    static void install(const QString &filePath);
    static void messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString& msg);
signals:

private:
    static QFile logFile;
    static QMutex mutex;
};

#endif // LOGGER_H
