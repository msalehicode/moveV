// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef NETSERVER_H
#define NETSERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>

#include <QNetworkInformation>

#include <QDateTime>

//to get ip addresses of server.
#include <QtNetwork>

//! [declaration]
class NetServer : public QObject
{
    Q_OBJECT

public:
    explicit NetServer(QObject *parent = nullptr);
    ~NetServer();

    bool startServer(quint16 port=5002); //later add select adapter feature
    void stopServer();
    QString getServerIpPort();

    QNetworkInformation::Reachability netState() const;

    void disconnectClient(QTcpSocket *target);

public slots:
    void sendMessage(QTcpSocket *receiver, const QString &message);
    void sendMessage(QTcpSocket *receiver, const QByteArray& data);

signals:
    void messageReceived(QTcpSocket* sender, QByteArray data);
    void clientConnected( QTcpSocket*  sender);
    void clientDisconnected( QTcpSocket*  sender);
    // void netStateChanged(QNetworkInformation::Reachability state);

private slots:
    void onClientConnected();
    void onClientDisconnected();
    void onReadSocket();

    // void onNetStateChanged(QNetworkInformation::Reachability state);
private:
    //get net state (is on or off?)
    // bool backendLoaded;
    // QNetworkInformation* info;
    // QNetworkInformation::Reachability m_netState;

    QTcpServer* m_server = nullptr;
    QList<QTcpSocket*> m_clientSockets;
};
//! [declaration]

#endif // NETSERVER_H
