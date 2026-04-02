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


#include <QDateTime>
#include <QTimer>

#include "commandhandler.h"


//handle pause play... commands from handsfree, and gnome notification to manage media and show metadata of media
#include <QDBusConnection>
#include <QDBusError>
#include "mprisadaptor.h"
#include "mprisrootadaptor.h"


using namespace Qt::StringLiterals;

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
    Wifi
};

struct RemoteUsers
{
    QString name;
    QString address;
    UserConnectionStatus status;    
    UserAccess access;
    QBluetoothSocket* socket;
    //QWifiSocket* wSocket;
    QDateTime connectedAt;
    UserConnectionType connectionType;

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
    void initMpris(QDBusConnection sessionBus);

    //------------------------ call qml functiosn
    void runQmlFunction(const QString& functionName);
    QVariant runQmlFunction(const QString& functionName, QVariant argum);


    void btCheckPermission();


    //cursor
    Q_INVOKABLE bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    Q_INVOKABLE bool restoreCursor();
    Q_INVOKABLE void changeCursor(const QString& mode="");


    //bluetooth
    Q_INVOKABLE void bluetoothServer(const bool& status);
    Q_INVOKABLE void refreshBluetoothAdapters();
    BtStatus btStatus() const;
    // QList<QBluetoothHostInfo> btLocalAdapters() const;
    void setBtLocalAdapters(const QList<QBluetoothHostInfo>& list);
    Q_INVOKABLE QVariantList btLocalAdapters() const;


    //bluetooth users
    QList<RemoteUsers*> users() const;
    RemoteUsers* findUser(QBluetoothSocket* userSocket) const;
    RemoteUsers* findUser(QString& address);
    void setUsers(const QList<RemoteUsers*>& newUsers);
    void addUser(RemoteUsers* newUser);
    QVariantList connectedUsersAsVariantList() const;//expose connected users (either bluetooth/wifi) to qml


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

signals:
    //properties
    void btStatusChanged();
    void btLocalAdaptersChanged();
    void connectedUsersListChanged();
    void btLocalNameChanged();
    void bluetoothHostModeStateChanged();

    void sendMessage(const QString &message);
    void sendMessage(QBluetoothSocket *receiver, const QString &message);

    void bannedUsersChanged();

    void btMaxConnectionUserChanged();

    void btAlwaysDiscoverableChanged();

public slots:
    void clientConnected(QBluetoothSocket *  sender);
    void clientDisconnected( QBluetoothSocket *  sender);
    void messageReceived( QBluetoothSocket*  sender, const QString &message);

    void bluetoothStateChanged(QBluetoothLocalDevice::HostMode state);


    //handle mpris signals
    void mprisPlayNext();
    void mprisPlayPrevious();
    void mprisPlay();
    void mprisPause();
    void mprisPlayPause();

private:
    void initBluetoothServer();
    void processCommand(RemoteUsers* user,const QString& message);

    QGuiApplication* m_app;
    SettingsManager* m_settings;
    CustomCursor cc;

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

    QObject* m_rootObject;//to call qml functions and run mpris stuff
    QDBusConnection* m_connection;

    MprisAdaptor* m_mprisAdaptor;
};

#endif // BACKEND_H
