#include "logger.h"

QFile Logger::logFile;
QMutex Logger::mutex;

void Logger::install(const QString &filePath)
{
    logFile.setFileName(filePath);
    if(!logFile.open(QIODevice::Append | QIODevice::Text))
        qWarning() << "could not open logFile.";
    qInstallMessageHandler(Logger::messageHandler);
}

void Logger::messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    QMutexLocker locker(&mutex);

    if(!logFile.isOpen())
    {
        qWarning() << "could not open logFile to write log message..";
        return;
    }


    QString level;
    switch(type)
    {
        case QtDebugMsg: level="DEBUG"; break;
        case QtInfoMsg: level="INFO"; break;
        case QtWarningMsg: level="WARNING"; break;
        case QtCriticalMsg: level="CRITICAL"; break;
        case QtFatalMsg: level="FATAL"; break;
        default: level="Unknown QtMsg";
    }


    QString line = QString("[%1] [%2] (%3:%4): %5\n")
                       .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz"))
                       .arg(level)
                       .arg(ctx.file ? ctx.file : "")
                       .arg(ctx.line)
                       .arg(msg);
    QTextStream out(&logFile);
    out << line;
    out.flush();

    if(type== QtFatalMsg)
        abort();
}
