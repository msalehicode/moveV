#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <QCoreApplication>
#include <QDebug>
#include <QStandardPaths>
#include <QSize>

class SettingsManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantMap value READ value WRITE setValue NOTIFY valueChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);
    ~SettingsManager();

    QVariantMap value() const;

    void setValue(const QVariantMap &settings);

    Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);

    Q_INVOKABLE QVariant getSetting(const QString &key, const QVariant &defaultValue) const;

signals:
    void valueChanged();

    void settingChanged(const QString &key);

private:
    void loadSettings();
    // void saveSettings(); // QSettings handles saving implicitly

    QSettings m_settings;
    QVariantMap m_value; // Holds all current settings

};

#endif // SETTINGSMANAGER_H
