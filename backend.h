#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QGuiApplication>
#include <QCursor>
#include "customcursor.h"

class Backend : public QObject
{
    Q_OBJECT
    CustomCursor cc;

public:
    explicit Backend(QObject *parent = nullptr);
    explicit Backend(QGuiApplication* app);



    Q_INVOKABLE bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    Q_INVOKABLE bool restoreCursor();
    Q_INVOKABLE void changeCursor(const QString& mode="");
    Q_INVOKABLE void setCustomCursorStatus(int status);
    bool customCursorStatus() const;

private:
    QGuiApplication* m_app;
    bool m_customCursorStatus;
signals:
};

#endif // BACKEND_H
