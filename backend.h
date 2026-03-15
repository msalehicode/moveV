#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QGuiApplication>
#include <QCursor>
#include "customcursor.h"
#include "settingsmanager.h"

class Backend : public QObject
{
    Q_OBJECT
    CustomCursor cc;

public:
    explicit Backend(const SettingsManager* const settings,QObject *parent = nullptr);

    Q_INVOKABLE bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    Q_INVOKABLE bool restoreCursor();
    Q_INVOKABLE void changeCursor(const QString& mode="");

private:
    QGuiApplication* m_app;
    const SettingsManager* const m_settings;

signals:
};

#endif // BACKEND_H
