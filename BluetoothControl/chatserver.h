// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef CHATSERVER_H
#define CHATSERVER_H

#include <QObject>

#include <QBluetoothAddress>
#include <QBluetoothServiceInfo>

#include <QBluetoothLocalDevice> //to get device bluetooth is off or on

QT_FORWARD_DECLARE_CLASS(QBluetoothServer)
QT_FORWARD_DECLARE_CLASS(QBluetoothSocket)

//! [declaration]
class ChatServer : public QObject
{
    Q_OBJECT

public:
    explicit ChatServer(QObject *parent = nullptr);
    ~ChatServer();

    bool startServer(const QBluetoothAddress &localAdapter = QBluetoothAddress());
    void stopServer();

    QMap<QBluetoothSocket *, QString> getClientNames() const;

    QBluetoothLocalDevice::HostMode btState() const;

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
};
//! [declaration]

#endif // CHATSERVER_H
