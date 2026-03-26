// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef CHATSERVER_H
#define CHATSERVER_H

#include <QObject>

#include <QBluetoothAddress>
#include <QBluetoothServiceInfo>

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

public slots:
    void sendMessage(const QString &message);
    void sendMessage(QBluetoothSocket *receiver, const QString &message);

signals:
    void messageReceived(QBluetoothSocket* sender, const QString &message);
    void clientConnected( QBluetoothSocket*  sender);
    void clientDisconnected( QBluetoothSocket*  sender);

private slots:
    void clientConnected();
    void clientDisconnected();
    void readSocket();

private:
    QBluetoothServer *rfcommServer = nullptr;
    QBluetoothServiceInfo serviceInfo;
    QList<QBluetoothSocket *> clientSockets;
    QMap<QBluetoothSocket *, QString> clientNames;
};
//! [declaration]

#endif // CHATSERVER_H
