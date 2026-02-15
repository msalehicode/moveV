// #ifndef BLUEZMEDIAPLAYER_H
// #define BLUEZMEDIAPLAYER_H

// #include <QObject>
// #include <QtDBus/QDBusAbstractAdaptor>

// class BluezMediaPlayer : public QDBusAbstractAdaptor
// {
//     Q_OBJECT
//     Q_CLASSINFO("D-Bus Interface", "org.bluez.MediaPlayer1")

//     Q_PROPERTY(QString Status READ status)
//     Q_PROPERTY(QString Track READ track)
// public:
//     explicit BluezMediaPlayer(QObject *parent) : QDBusAbstractAdaptor(parent) {}

//     QString status() const { return m_status; }
//     QString track() const { return m_track; }

// public slots:
//     void Play() { QMetaObject::invokeMethod(parent(), "playVideo"); m_status = "Playing"; emitPropertiesChanged(); }
//     void Pause() { QMetaObject::invokeMethod(parent(), "pauseVideo"); m_status = "Paused"; emitPropertiesChanged(); }
//     void Next() { QMetaObject::invokeMethod(parent(), "nextVideo"); }
//     void Previous() { QMetaObject::invokeMethod(parent(), "previousVideo"); }

// signals:
//     void PropertiesChanged(const QVariantMap &changed, const QStringList &invalidated);

// private:
//     void emitPropertiesChanged() {
//         QVariantMap changed;
//         changed["Status"] = m_status;
//         changed["Track"] = m_track;
//         emit PropertiesChanged(changed, {});
//     }

//     QString m_status = "Stopped";
//     QString m_track;
// };


// #endif // BLUEZMEDIAPLAYER_H
