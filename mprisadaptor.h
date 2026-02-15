// sudo apt install playerctl
// playerctl --player=myplayer pause
//playerctl -l
//pactl list sink-inputs

#pragma once
#include <QDBusAbstractAdaptor>
#include <QObject>
#include <QVariantMap>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QMap>
#include <QVariant>


class MprisAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")

    Q_PROPERTY(QString PlaybackStatus READ PlaybackStatus NOTIFY PlaybackStatusChanged)
    Q_PROPERTY(bool CanPlay READ CanPlay)
    Q_PROPERTY(bool CanPause READ CanPause)
    Q_PROPERTY(bool CanControl READ CanControl)
    Q_PROPERTY(bool CanGoNext READ CanGoNext)
    Q_PROPERTY(bool CanGoPrevious READ CanGoPrevious)
    QVariantMap m_metadata;
    Q_PROPERTY(QVariantMap Metadata READ Metadata NOTIFY MetadataChanged)

    void updateMetadata(const QString &title, const QString &artist, const QString &trackId);

public:
    explicit MprisAdaptor(QObject *parent, const QString &objectPath = "/org/mpris/MediaPlayer2");

    QVariantMap Metadata() const { return m_metadata; }
    QString PlaybackStatus() const { return m_playbackStatus; }
    bool CanPlay() const { return true; }
    bool CanPause() const { return true; }
    bool CanControl() const { return true; }
    bool CanGoNext() const { return true; }
    bool CanGoPrevious() const { return true; }

public slots:
    void Play();
    void Pause();
    void PlayPause();
    void setPlaybackStatus(const QString &status);
    void Next();
    void Previous();

signals:
    void PlaybackStatusChanged();

    // D-Bus standard signal for property changes
    void PropertiesChanged(const QVariantMap &changed, const QStringList &invalidated);

    void MetadataChanged();


private:
    QString m_playbackStatus = "Paused";
    QString m_objectPath;
};
