#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QGuiApplication>
#include <QCursor>

class Backend : public QObject
{
    Q_OBJECT
public:
    explicit Backend(QObject *parent = nullptr);
    explicit Backend(QGuiApplication* app);


    Q_INVOKABLE bool setAppCursor(int cursor);

private:
    QGuiApplication* m_app;
signals:
};

#endif // BACKEND_H
