// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef CHATSERVER_H
#define CHATSERVER_H

#include <QObject>

#include <QBluetoothAddress>
#include <QBluetoothServiceInfo>

#include <QBluetoothLocalDevice> //to get device bluetooth is off or on
#include <QDateTime>

QT_FORWARD_DECLARE_CLASS(QBluetoothServer)
QT_FORWARD_DECLARE_CLASS(QBluetoothSocket)

//! [declaration]
class ChatServer : public QObject
{
    Q_OBJECT

public:
    explicit ChatServer(QObject *parent = nullptr);
    ~ChatServer();

    bool startServer(const QBluetoothAddress &localAdapter = QBluetoothAddress(), int maxConnectionsCount=1);
    void stopServer();

    QMap<QBluetoothSocket *, QString> getClientNames() const;

    QBluetoothLocalDevice::HostMode btState() const;

    void setAlwaysDiscoverable(bool newAlwaysDiscoverable);

public slots:
    void sendMessage(const QString &message);
    void sendMessage(QBluetoothSocket *receiver, const QString &message);

signals:
    void messageReceived(QBluetoothSocket* sender, const QString &message);
    void clientConnected( QBluetoothSocket*  sender);
    void clientDisconnected( QBluetoothSocket*  sender);

    void btStateChanged(QBluetoothLocalDevice::HostMode state);

private slots:
    void clientConnected();
    void clientDisconnected();
    void readSocket();

    void onBluetoothStateChanged(QBluetoothLocalDevice::HostMode state);
private:
    QBluetoothServer *rfcommServer = nullptr;
    QBluetoothServiceInfo serviceInfo;
    QList<QBluetoothSocket *> clientSockets;
    QMap<QBluetoothSocket *, QString> clientNames;

    QBluetoothLocalDevice m_localDevice; //get blueooth state is on/off..
    QBluetoothLocalDevice::HostMode m_btState; //store state, because on initial may not emit btStateChanged correctly. can read from this to know initial state.
    bool m_alwaysDiscoverable; //after e.g 3min may device hostMode change from Discover to connectable, so would not list on scanned devices for users. if it's gone connectable we make it discoverable again.
};
//! [declaration]

#endif // CHATSERVER_H
