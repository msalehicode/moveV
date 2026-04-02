#pragma once

#include <QDBusAbstractAdaptor>
#include <QObject>

class MprisRootAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2")

    Q_PROPERTY(bool CanQuit READ CanQuit)
    Q_PROPERTY(bool CanRaise READ CanRaise)
    Q_PROPERTY(QString Identity READ Identity)

public:
    explicit MprisRootAdaptor(QObject *parent)
        : QDBusAbstractAdaptor(parent)
    {

    }

    bool CanQuit() const { return false; }
    bool CanRaise() const { return false; }
    QString Identity() const
    {
        return QString::fromUtf8(MPRIS_IDENTITY);
        // return "splayer";
    }

public slots:
    void Raise() {}
    void Quit() {}
};
