// sudo apt install playerctl
// playerctl --player=myplayer pause
//playerctl -l
//pactl list sink-inputs
// pactl set-sink-input-volume 603 100%   //603 is id

#pragma once
#include <QDBusAbstractAdaptor>
#include <QObject>
#include <QVariantMap>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QMap>
#include <QVariant>


struct ControlMpris
{
    bool canPlay;
    bool canPause;
    bool canControl;
    bool canGoPrevious;
    bool canGoNext;
};

class MprisAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")

    Q_PROPERTY(QVariantMap Metadata READ Metadata NOTIFY MetadataChanged)
    Q_PROPERTY(bool CanPlay READ CanPlay)
    Q_PROPERTY(bool CanPause READ CanPause)
    Q_PROPERTY(bool CanControl READ CanControl)
    Q_PROPERTY(bool CanGoNext READ CanGoNext)
    Q_PROPERTY(bool CanGoPrevious READ CanGoPrevious)
    // Q_PROPERTY(QString PlaybackStatus READ PlaybackStatus NOTIFY PlaybackStatusChanged)


public:
    explicit MprisAdaptor(QObject *parent, const QString &objectPath = "/org/mpris/MediaPlayer2");

    //modify these by backend
    ControlMpris control;
    void updateMetadata(bool isPlaying, const QString &title,
                        const QString &artist, const QString &trackId);


    //mpris getters
    QVariantMap Metadata() const { return m_metadata; }
    bool CanPlay() const
    {
        return control.canPlay;
    }
    bool CanPause() const
    {
        return control.canPause;
    }
    bool CanControl() const
    {
        return control.canControl;
    }
    bool CanGoNext() const
    {
        return control.canGoNext;
    }
    bool CanGoPrevious() const
    {
        return control.canGoPrevious;
    }
    // QString PlaybackStatus() const { return m_playbackStatus; }

    // void setPlaybackStatus(const QString &newPlaybackStatus);

public slots:
    void Play() { emit sPlay(); }
    void Pause() { emit sPause(); }
    void PlayPause() { emit sPlayPause(); }
    void Next() { emit sPlayNext(); }
    void Previous() { emit sPlayPrevious(); }

signals:
    //to notify backend
    void sPlayNext();
    void sPlayPrevious();
    void sPlay();
    void sPause();
    void sPlayPause();

    // D-Bus standard signal for property changes
    void PropertiesChanged(const QVariantMap &changed,
                           const QStringList &invalidated);
    void MetadataChanged();
    // void PlaybackStatusChanged();


private:
    // QString m_playbackStatus = "Paused";
    QVariantMap m_metadata;
    QString m_objectPath;
    QDBusMessage m_msg;
    QVariantMap m_changedProps;
    QVariantMap m_changed;
};
