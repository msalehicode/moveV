#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QGuiApplication>
#include <QCursor>
#include "customcursor.h"
#include "settingsmanager.h"
#include "BluetoothControl/chatserver.h"
#include <QDebug>


//bluetooth server
#include <QBluetoothHostInfo>
#include <QPermissions>
#include <QBluetoothSocket>
#include <QBluetoothDeviceInfo>
#include <QBluetoothLocalDevice>
#include <QBluetoothUuid>
#include "BluetoothControl/chatserver.h"


#include "commandhandler.h"

using namespace Qt::StringLiterals;

enum BtStatus //host
{
    Unknown=-1,

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

struct RemoteUsers
{
    UserConnectionStatus status;
    UserAccess access;
    QBluetoothSocket* socket;

    // RemoteUsers() : status(UserConnectionStatus::UnknownStatus), access(UserAccess::Normal), socket(nullptr)
    // {

    // }
};


class Backend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(BtStatus btStatus READ btStatus WRITE setBtStatus NOTIFY btStatusChanged)
    // Q_PROPERTY(QList<QBluetoothHostInfo> btLocalAdapters READ btLocalAdapters WRITE setBtLocalAdapters NOTIFY btLocalAdaptersChanged)


public:
    explicit Backend(const SettingsManager* const settings,QGuiApplication* app, QObject *parent = nullptr);



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


    QList<RemoteUsers*> users() const;
    RemoteUsers* findUser(QBluetoothSocket* userSocket) const;
    void setUsers(const QList<RemoteUsers*>& newUsers);
    void addUser(RemoteUsers* newUser);

signals:
    //properties
    void btStatusChanged();
    void btLocalAdaptersChanged();


    void sendMessage(const QString &message);
    void sendMessage(QBluetoothSocket *receiver, const QString &message);
public slots:
    void clientConnected(QBluetoothSocket *  sender);
    void clientDisconnected( QBluetoothSocket *  sender);
    void messageReceived( QBluetoothSocket*  sender, const QString &message);



private:
    void initBluetoothServer();
    void processCommand(RemoteUsers* user,const QString& message);

    QGuiApplication* m_app;
    const SettingsManager* const m_settings;
    CustomCursor cc;

    //bluetooth host
    ChatServer* m_btServer = nullptr;
    QList<QBluetoothHostInfo> m_btLocalAdapters;
    QString m_btLocalName = "empty!";
    BtStatus m_btStatus = BtStatus::Inactive;
    void setBtStatus(BtStatus status);
    int indexCurrentAdaptor = 0;
    QList<RemoteUsers*> m_users;

    CommandHandler ch;

};

#endif // BACKEND_H
