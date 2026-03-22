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
#include <QBluetoothDeviceInfo>
#include <QBluetoothLocalDevice>
#include <QBluetoothUuid>
#include "BluetoothControl/chatserver.h"

using namespace Qt::StringLiterals;

enum BtStatus
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

class Backend : public QObject
{
    Q_OBJECT


public:
    explicit Backend(const SettingsManager* const settings,QGuiApplication* app, QObject *parent = nullptr);


    Q_PROPERTY(BtStatus btStatus READ btStatus WRITE setBtStatus NOTIFY btStatusChanged)
    // Q_PROPERTY(QList<QBluetoothHostInfo> btLocalAdapters READ btLocalAdapters WRITE setBtLocalAdapters NOTIFY btLocalAdaptersChanged)

    Q_INVOKABLE bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    Q_INVOKABLE bool restoreCursor();
    Q_INVOKABLE void changeCursor(const QString& mode="");


    //bluetooth
    Q_INVOKABLE void bluetoothServer(const bool& status);
    Q_INVOKABLE void refreshBluetoothAdapters();
    BtStatus btStatus() const;
    // QList<QBluetoothHostInfo> btLocalAdapters() const;

    void setBtLocalAdapters(const QList<QBluetoothHostInfo>& list);



    Q_INVOKABLE QVariantList btLocalAdapters() const
    {
        QVariantList qmlList;
        for (const auto& adapterInfo : m_btLocalAdapters) {
            QVariantMap map;
            map.insert("name", adapterInfo.name());
            map.insert("address", adapterInfo.address().toString());
            qmlList.append(map);
        }
        return qmlList;
    }


signals:
    //properties
    void btStatusChanged();
    void btLocalAdaptersChanged();


    void sendMessage(const QString &message);
public slots:
    void clientConnected(const QString &name);
    void clientDisconnected(const QString &name);
    void messageReceived(const QString &sender, const QString &message);


private:
    void initBluetoothServer();

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

};

#endif // BACKEND_H
