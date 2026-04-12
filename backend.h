#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QGuiApplication>
#include <QCursor>
#include "customcursor.h"
#include "settingsmanager.h"
#include "BluetoothControl/chatserver.h"
#include <QDebug>
#include <QSet>

//bluetooth server
#include <QBluetoothHostInfo>
#include <QPermissions>
#include <QBluetoothSocket>
#include <QBluetoothDeviceInfo>
#include <QBluetoothLocalDevice>
#include <QBluetoothUuid>
#include "BluetoothControl/chatserver.h"
#include "NetworkControl/netserver.h"

#include <QDateTime>
#include <QTimer>

#include "commandhandler.h"


//handle pause play... commands from handsfree, and gnome notification to manage media and show metadata of media
#include <QDBusConnection>
#include <QDBusError>
#include "mprisadaptor.h"
#include "mprisrootadaptor.h"

#include <QElapsedTimer>

#include "config.h"

using namespace Qt::StringLiterals;

enum class NetStatus
{
    Unknown=-1,

    Starting=0,

    AdapterNotFound=10,
    Failed,

    Inactive=30,
    Loading,
    Active
};

enum BtStatus //host
{
    Unknown=-1,

    Starting=0,

    AdapterNotFound=10,
    Failed,


    DeniedPermission=20,
    AskingPermission,
    GrantedPermission,


    Inactive=30,
    Discoverable,
    Loading,
    Active
};


//clients
enum class UserConnectionStatus
{
    UnknownStatus=-1,
    Connected,
    ConnectionLost, //will way some seconds and if not retunred/responsed will disconnect him.
    Disconnected
};

enum class UserAccess
{
    Admin,
    Normal
};

enum UserConnectionType
{
    Bluetooth,
    Network
};

struct RemoteUsers
{
    QString name;
    QString address;
    UserConnectionStatus status;    
    UserAccess access;
    QBluetoothSocket* btSocket;
    QTcpSocket* netSocket;
    QDateTime connectedAt;
    UserConnectionType connectionType;
    qint64 pingMs;

    short connectionLostCounter;
    QElapsedTimer pingTimer;
    QTimer connectionLostTimer;

    RemoteUsers(QString uName, QString uAddressPort, UserConnectionType connType,
                QTcpSocket* networkSocket=nullptr,
                QBluetoothSocket* bluetoothSocket=nullptr)
        : name(uName) , address(uAddressPort), connectionType(connType)
        , btSocket(bluetoothSocket), netSocket(networkSocket)
        , status(UserConnectionStatus::Connected), pingMs(0) , connectionLostCounter(0)
        , access(UserAccess::Normal), connectedAt(QDateTime::currentDateTime())
    {


    }


    QString convertUserAccess() const;

    QString convertConnectionType(bool shortForm=false) const;

    QString convertConnectionStatus() const;

    QList<QString> getAsStringList() const;
};


class Backend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(BtStatus btStatus READ btStatus WRITE setBtStatus NOTIFY btStatusChanged)
    // Q_PROPERTY(QList<QBluetoothHostInfo> btLocalAdapters READ btLocalAdapters WRITE setBtLocalAdapters NOTIFY btLocalAdaptersChanged)

    Q_PROPERTY(QVariantList connectedUsersList READ connectedUsersAsVariantList NOTIFY connectedUsersListChanged)
    Q_PROPERTY(QString btLocalName READ btLocalName NOTIFY btLocalNameChanged) //current adapter name [ADDRESS] which is hosting now

    Q_PROPERTY(QStringList bannedUsers READ bannedUsers NOTIFY bannedUsersChanged)
    Q_PROPERTY(QBluetoothLocalDevice::HostMode bluetoothHostModeState READ bluetoothHostModeState NOTIFY bluetoothHostModeStateChanged)

    Q_PROPERTY(int btMaxConnectionUser READ btMaxConnectionUser WRITE setBtMaxConnectionUser NOTIFY btMaxConnectionUserChanged FINAL)
    Q_PROPERTY(bool btAlwaysDiscoverable READ btAlwaysDiscoverable WRITE setBtAlwaysDiscoverable NOTIFY btAlwaysDiscoverableChanged FINAL)

public:
    explicit Backend(SettingsManager* settings,QGuiApplication* app, QObject *parent = nullptr);

    //to be able call qml functions and init MPRIS
    void initMpris();

    void initConnectionLost(RemoteUsers* user);

    //------------------------ call qml functiosn
    void runQmlFunction(const QString& functionName);
    QVariant runQmlFunction(const QString& functionName, QVariant argum);


    void btCheckPermission();


    //cursor
    Q_INVOKABLE bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    Q_INVOKABLE bool restoreCursor();
    Q_INVOKABLE void changeCursor(const QString& mode="");


    //net
    Q_INVOKABLE void netServer(const bool& status);

    //bluetooth
    Q_INVOKABLE void bluetoothServer(const bool& status);
    Q_INVOKABLE void refreshBluetoothAdapters();
    BtStatus btStatus() const;
    // QList<QBluetoothHostInfo> btLocalAdapters() const;
    void setBtLocalAdapters(const QList<QBluetoothHostInfo>& list);
    Q_INVOKABLE QVariantList btLocalAdapters() const;


    //users bluetooth either net
    QList<RemoteUsers*> users() const;
    RemoteUsers* findUser(QBluetoothSocket* userSocket) const;
    RemoteUsers* findUser(QTcpSocket* userSocket) const;
    RemoteUsers* findUser(QString& address);
    void setUsers(const QList<RemoteUsers*>& newUsers);
    void addUser(RemoteUsers* newUser);
    QVariantList connectedUsersAsVariantList() const;//expose connected users (either bluetooth/Network) to qml


    QString btLocalName() const;
    void setBtLocalName(const QString &newBtLocalName);

    QBluetoothLocalDevice::HostMode bluetoothHostModeState();
    void setBluetoothHostModeState(QBluetoothLocalDevice::HostMode state);


    int btMaxConnectionUser() const;
    void setBtMaxConnectionUser(int newBtMaxConnectionUser);

    bool btAlwaysDiscoverable() const;
    void setBtAlwaysDiscoverable(bool newAlwaysDiscoverable);


    QStringList bannedUsers() const;
    Q_INVOKABLE void unbanUser(QString address);
    Q_INVOKABLE void kickUser(QString address);
    Q_INVOKABLE void banUser(QString address);

    void setRootObject(QObject *newRootObject);

    bool mprisControl() const;
    void setMprisControl(bool newMprisControl);

    bool IsDBusConnectionOk() const;
    void setIsDBusConnectionOk(bool newIsDBusConnectionOk);

    NetStatus ntStatus() const;
    void setNtStatus(NetStatus newNetStatus);

    QString netLocalName() const;
    void setNetLocalName(const QString &newNetLocalName);

signals:
    //properties
    void btStatusChanged();
    void btLocalAdaptersChanged();
    void connectedUsersListChanged();
    void btLocalNameChanged();
    void bluetoothHostModeStateChanged();


    //bluetooth singals
    void sendMessage(const QString &message);//later remove it becasue of confusion
    void sendMessage(QBluetoothSocket *receiver, const QString &message);
    void sendMessage(QBluetoothSocket *receiver, const QByteArray& data);


    //net signals
    void sendMessage(QTcpSocket *receiver, const QString &message);
    void sendMessage(QTcpSocket *receiver, const QByteArray& data);

    void bannedUsersChanged();

    void btMaxConnectionUserChanged();

    void btAlwaysDiscoverableChanged();

    void mprisControlChanged();

    void IsDBusConnectionOkChanged();

    void ntStatusChanged();

    void netLocalNameChanged();

public slots:
    //bluetooth slots
    void clientConnected(QBluetoothSocket *  sender);
    void clientDisconnected( QBluetoothSocket *  sender);
    void messageReceived(QBluetoothSocket* sender, QByteArray data);

    //net slots
    void clientConnected(QTcpSocket *  sender);
    void clientDisconnected(QTcpSocket *  sender);
    void messageReceived(QTcpSocket* sender, QByteArray data);

    void bluetoothStateChanged(QBluetoothLocalDevice::HostMode state);


    //handle mpris signals
    void mprisPlayNext();
    void mprisPlayPrevious();
    void mprisPlay();
    void mprisPause();
    void mprisPlayPause();

private:
    void initBluetoothServer();
    void initNetServer();
    void processCommand(RemoteUsers *user, QByteArray *data,
                            CommandHandler::Command mprisCommand=CommandHandler::Command::CurrentMediaName);
    void sendPingToAllUsers();

    QString toPureIPv4(const QHostAddress &addr); //sender->peerAddress() contains ipv6 and ipv4 (::::ff127.0.01) so this removes that ipv6

    void doProcessPing(RemoteUsers* user);
    QGuiApplication* m_app;
    SettingsManager* m_settings;
    CustomCursor cc;

    //net host
    NetServer* m_netServer;
    QString m_netLocalName;
    Q_PROPERTY(QString netLocalName READ netLocalName WRITE setNetLocalName NOTIFY netLocalNameChanged FINAL)
    NetStatus m_ntStatus;
    Q_PROPERTY(NetStatus ntStatus READ ntStatus WRITE setNtStatus NOTIFY ntStatusChanged FINAL)

    //bluetooth host
    ChatServer* m_btServer;
    QList<QBluetoothHostInfo> m_btLocalAdapters;
    QString m_btLocalName;
    BtStatus m_btStatus;
    void setBtStatus(BtStatus status);
    int indexCurrentAdaptor;
    QList<RemoteUsers*> m_users;

    QBluetoothLocalDevice::HostMode m_bluetoothHostModeState;

    QSet<QString> m_bannedUsers;

    CommandHandler m_commandHandler;

    bool m_btAlwaysDiscoverable;
    int m_btMaxConnectionUser;


    QTimer m_pingUsersTimer;
    QObject* m_rootObject;//to call qml functions and run mpris stuff

    MprisAdaptor* m_mprisAdaptor;

    bool m_mprisControl;
    bool m_IsDBusConnectionOk;//status of dbus connection if failed dont allow user to change mprisControl status
    Q_PROPERTY(bool mprisControl READ mprisControl WRITE setMprisControl NOTIFY mprisControlChanged FINAL)
    Q_PROPERTY(bool IsDBusConnectionOk READ IsDBusConnectionOk WRITE setIsDBusConnectionOk NOTIFY IsDBusConnectionOkChanged FINAL)

};

#endif // BACKEND_H
