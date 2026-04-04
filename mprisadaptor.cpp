#include "mprisadaptor.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QMetaObject>
#include <QDebug>

MprisAdaptor::MprisAdaptor(QObject *parent, const QString &objectPath)
    : QDBusAbstractAdaptor(parent)
    , m_objectPath(objectPath)
{
    //initial to avoid return neither 0 nor 1 to dbus (this can cause crash!)
    control.canControl = true;
    control.canGoNext = true;
    control.canGoPrevious = true;
    control.canPause = true;
    control.canPlay = true;

    // setPlaybackStatus("Paused");
}

void MprisAdaptor::updateMetadata(bool isPlaying,
                                  const QString &title,
                                  const QString &artist,
                                  const QString &trackId)
{
    m_metadata.clear();
    m_metadata["mpris:trackid"] = trackId;
    m_metadata["xesam:title"] = title;
    m_metadata["xesam:artist"] = artist;
    m_metadata["xesam:album"] = "Album Name";  // Optional, but might help with some clients
    m_metadata["xesam:trackNumber"] = 1;      // Optional, but sometimes required


    emit MetadataChanged();

    // Also notify via PropertiesChanged for MPRIS clients
    m_changed.clear();
    m_changed["Metadata"] = m_metadata;
    m_changed["PlaybackStatus"] = (isPlaying? "Playing" : "Paused");
    emit PropertiesChanged(m_changed, {});



    //force
    m_changedProps.clear();
    m_changedProps.insert("Metadata", m_metadata);
    m_changedProps.insert("PlaybackStatus", (isPlaying? "Playing" : "Paused"));
    m_changedProps.insert("CanGoNext", control.canGoNext);
    m_changedProps.insert("CanGoPrevious", control.canGoPrevious);
    m_changedProps.insert("CanControl", control.canControl);
    m_changedProps.insert("CanPlay", control.canPlay);
    m_changedProps.insert("CanPause", control.canPause);

    m_msg = QDBusMessage::createSignal(
        m_objectPath,
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged"
        );
    m_msg << "org.mpris.MediaPlayer2.Player" << m_changedProps << QStringList();
    if(QDBusConnection::sessionBus().send(m_msg))
        qInfo() << "updated mprisMetaData has sent to QDBUS successfully.";
    else
        qWarning() << "failed to send updated mprisMetaData to QDBUS.";
}

// void MprisAdaptor::setPlaybackStatus(const QString &newPlaybackStatus)
// {
//     if (m_playbackStatus == newPlaybackStatus)
//         return;
//     m_playbackStatus = newPlaybackStatus;
//     emit PlaybackStatusChanged();
// }
