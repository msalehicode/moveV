#include "mprisadaptor.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QMetaObject>
#include <QDebug>

MprisAdaptor::MprisAdaptor(QObject *parent, const QString &objectPath)
    : QDBusAbstractAdaptor(parent)
    , m_objectPath(objectPath)
{
    setPlaybackStatus("Paused");
}

void MprisAdaptor::setPlaybackStatus(const QString &status)
{
    if (m_playbackStatus == status)
        return;

    m_playbackStatus = status;

    QVariantMap changedProps;
    changedProps.insert("PlaybackStatus", m_playbackStatus);

    QDBusMessage msg = QDBusMessage::createSignal(
        m_objectPath,  // <- use stored object path
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged"
        );
    msg << "org.mpris.MediaPlayer2.Player" << changedProps << QStringList();
    QDBusConnection::sessionBus().send(msg);

    emit PlaybackStatusChanged();
}

void MprisAdaptor::Next()
{
    QMetaObject::invokeMethod(parent(), "nextVideo");
    qInfo() << "next called";
    setPlaybackStatus("Playing");

    updateMetadata("Next Video", "Artist Name", "/org/mpris/MediaPlayer2/track/1");

}

void MprisAdaptor::updateMetadata(const QString &title, const QString &artist, const QString &trackId) {
    m_metadata.clear();
    m_metadata["mpris:trackid"] = trackId;
    m_metadata["xesam:title"] = title;
    m_metadata["xesam:artist"] = artist;
    m_metadata["xesam:album"] = "Album Name";  // Optional, but might help with some clients
    m_metadata["xesam:trackNumber"] = 1;      // Optional, but sometimes required


    emit MetadataChanged();

    // Also notify via PropertiesChanged for MPRIS clients
    QVariantMap changed;
    changed["Metadata"] = m_metadata;
    changed["PlaybackStatus"] = m_playbackStatus;
    emit PropertiesChanged(changed, {});



    //force
    QVariantMap changedProps;
    changedProps.insert("Metadata", m_metadata);
    changedProps.insert("PlaybackStatus", m_playbackStatus);
    changedProps.insert("CanGoNext", true);
    changedProps.insert("CanGoPrevious", true);
    changedProps.insert("CanControl", true);

    QDBusMessage msg = QDBusMessage::createSignal(
        m_objectPath,
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged"
        );
    msg << "org.mpris.MediaPlayer2.Player" << changedProps << QStringList();
    QDBusConnection::sessionBus().send(msg);

}

void MprisAdaptor::Previous()
{
    QMetaObject::invokeMethod(parent(), "previousVideo");
    setPlaybackStatus("Playing");

    qInfo() << "previous called";
    updateMetadata("Previ Video", "Artist Name", "/org/mpris/MediaPlayer2/track/1");

}


void MprisAdaptor::Play()
{
    qDebug() << "MPRIS Play called";
    QMetaObject::invokeMethod(parent(), "playVideo");
    setPlaybackStatus("Playing");

    updateMetadata("My Video", "Artist Name", "/org/mpris/MediaPlayer2/track/1");

}

void MprisAdaptor::Pause()
{
    qDebug() << "MPRIS Pause called";
    QMetaObject::invokeMethod(parent(), "pauseVideo");
    setPlaybackStatus("Paused");

}

void MprisAdaptor::PlayPause()
{
    qDebug() << "MPRIS PlayPause called";
    QMetaObject::invokeMethod(parent(), "togglePlayPause");
    setPlaybackStatus((m_playbackStatus == "Playing") ? "Paused" : "Playing");
}
