// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "chatserver.h"

#include <QBluetoothServer>
#include <QBluetoothSocket>

using namespace Qt::StringLiterals;

//! [Service UUID]
static constexpr auto serviceUuid = "e8e10f95-1a70-4b27-9ccf-02010264e9c8"_L1;
//! [Service UUID]

ChatServer::ChatServer(QObject *parent)
    :   QObject(parent) , m_alwaysDiscoverable(true)
{
    if (m_localDevice.isValid())
    {
        qDebug() << "Bluetooth adapter initialized.";
        // Connect to the stateChanged signal
        connect(&m_localDevice, &QBluetoothLocalDevice::hostModeStateChanged,
                this, &ChatServer::onBluetoothStateChanged);

        onBluetoothStateChanged(m_localDevice.hostMode());//
    } else {
        qDebug() << "Failed to initialize Bluetooth adapter.";
    }
}

ChatServer::~ChatServer()
{
    stopServer();
}

bool ChatServer::startServer(const QBluetoothAddress& localAdapter, int maxConnectionsCount)
{
    //! [Create the server]

    if (rfcommServer)
    {
        qDebug() << "startServer called, but rfcommServer already exists.";
        return false;
    }

    rfcommServer = new QBluetoothServer(QBluetoothServiceInfo::RfcommProtocol, this);

    connect(rfcommServer, &QBluetoothServer::newConnection,
            this, QOverload<>::of(&ChatServer::clientConnected));

    //set max before listening
    rfcommServer->setMaxPendingConnections(maxConnectionsCount);

    bool result = rfcommServer->listen(localAdapter);
    if (!result)
    {
        qWarning() << "Cannot bind chat server to" << localAdapter.toString();
        return false;
    }
    //! [Create the server]




    qInfo() << "trying to start server with serviceUuid=" << serviceUuid;
    qInfo() << "server info: " << rfcommServer->serverAddress() << " P:" << rfcommServer->serverPort() << " , type: " << rfcommServer->serverType();
    qInfo() << "max peding coonection: " << rfcommServer->maxPendingConnections() << " sec flags:" << rfcommServer->securityFlags();

    //serviceInfo.setAttribute(QBluetoothServiceInfo::ServiceRecordHandle, (uint)0x00010010);

    QBluetoothServiceInfo::Sequence profileSequence;
    QBluetoothServiceInfo::Sequence classId;
    classId << QVariant::fromValue(QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort));
    classId << QVariant::fromValue(quint16(0x100));
    profileSequence.append(QVariant::fromValue(classId));
    serviceInfo.setAttribute(QBluetoothServiceInfo::BluetoothProfileDescriptorList,
                             profileSequence);


    classId.clear();
    classId << QVariant::fromValue(QBluetoothUuid(serviceUuid));
    classId << QVariant::fromValue(QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort));

    serviceInfo.setAttribute(QBluetoothServiceInfo::ServiceClassIds, classId);

    //! [Service name, description and provider]
    serviceInfo.setAttribute(QBluetoothServiceInfo::ServiceName, tr("Bt Chat Server"));
    serviceInfo.setAttribute(QBluetoothServiceInfo::ServiceDescription,
                             tr("Example bluetooth chat server"));
    serviceInfo.setAttribute(QBluetoothServiceInfo::ServiceProvider, tr("qt-project.org"));
    //! [Service name, description and provider]

    //! [Service UUID set]
    serviceInfo.setServiceUuid(QBluetoothUuid(serviceUuid));
    //! [Service UUID set]


    //! [Service Discoverability]
    const auto groupUuid = QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::PublicBrowseGroup);
    QBluetoothServiceInfo::Sequence publicBrowse;
    publicBrowse << QVariant::fromValue(groupUuid);
    serviceInfo.setAttribute(QBluetoothServiceInfo::BrowseGroupList, publicBrowse);
    //! [Service Discoverability]

    //! [Protocol descriptor list]
    QBluetoothServiceInfo::Sequence protocolDescriptorList;
    QBluetoothServiceInfo::Sequence protocol;
    protocol << QVariant::fromValue(QBluetoothUuid(QBluetoothUuid::ProtocolUuid::L2cap));
    protocolDescriptorList.append(QVariant::fromValue(protocol));
    protocol.clear();
    protocol << QVariant::fromValue(QBluetoothUuid(QBluetoothUuid::ProtocolUuid::Rfcomm))
             << QVariant::fromValue(quint8(rfcommServer->serverPort()));
    protocolDescriptorList.append(QVariant::fromValue(protocol));
    serviceInfo.setAttribute(QBluetoothServiceInfo::ProtocolDescriptorList,
                             protocolDescriptorList);
    //! [Protocol descriptor list]

    bool res = serviceInfo.registerService(localAdapter);

    qInfo() << " service info channel: " << serviceInfo.serverChannel() << "completed?: " << serviceInfo.isComplete()  <<
        " Availability: " << serviceInfo.serviceAvailability();
    qInfo() << " isvalid? " <<serviceInfo.isValid() << " registered?" << serviceInfo.isRegistered(); //<< "device:" << serviceInfo.device();
    qInfo() << " protocol" << serviceInfo.serviceDescription() << " provider" << serviceInfo.serviceProvider();
    qInfo() << " name:" << serviceInfo.serviceName() << " uuid" << serviceInfo.serviceUuid();
    qInfo() << "socketprotocl" << serviceInfo.socketProtocol();
    //! [Register service]
    return res;
    //! [Register service]
}

//! [stopServer]
void ChatServer::stopServer()
{
    //disconnect all connected usrs;
    for(QBluetoothSocket* socket : clientSockets)
    {
        socket->disconnectFromService();
        // socket->waitForDisconnected();

        emit clientDisconnected(socket);

        socket->deleteLater();
    }

    //clear lists
    clientSockets.clear();
    clientNames.clear();


    // Unregister service
    serviceInfo.unregisterService();

    // Close sockets
    qDeleteAll(clientSockets);
    clientNames.clear();

    // Close server
    delete rfcommServer;
    rfcommServer = nullptr;
}
//! [stopServer]

//! [sendMessage]
void ChatServer::sendMessage(const QString &message)
{
    QByteArray text = message.toUtf8() + '\n';

    for (QBluetoothSocket *socket : std::as_const(clientSockets))
        socket->write(text);
}

void ChatServer::sendMessage(QBluetoothSocket * receiver, const QString &message)
{
    QByteArray text = message.toUtf8() + '\n';

    receiver->write(text);
}
//! [sendMessage]

//! [clientConnected]
void ChatServer::clientConnected()
{
    QBluetoothSocket *socket = rfcommServer->nextPendingConnection();
    if (!socket)
        return;

    connect(socket, &QBluetoothSocket::readyRead, this, &ChatServer::readSocket);
    connect(socket, &QBluetoothSocket::disconnected,
            this, QOverload<>::of(&ChatServer::clientDisconnected));
    clientSockets.append(socket);
    clientNames[socket] = socket->peerName();
    emit clientConnected(socket);
}
//! [clientConnected]

//! [clientDisconnected]
void ChatServer::clientDisconnected()
{
    QBluetoothSocket *socket = qobject_cast<QBluetoothSocket *>(sender());
    if (!socket)
        return;

    emit clientDisconnected(socket);

    clientSockets.removeOne(socket);
    clientNames.remove(socket);

    socket->deleteLater();
}
//! [clientDisconnected]

//! [readSocket]
void ChatServer::readSocket()
{
    QBluetoothSocket *socket = qobject_cast<QBluetoothSocket *>(sender());
    if (!socket)
        return;

    while (socket->canReadLine()) {
        QByteArray line = socket->readLine().trimmed();
        emit messageReceived(socket,
                             QString::fromUtf8(line.constData(), line.length()));
    }
}

void ChatServer::onBluetoothStateChanged(QBluetoothLocalDevice::HostMode state)
{
    m_btState=state;
    qDebug() << QDateTime::currentDateTime().toString() <<" - Bluetooth HostMode changed to:" << m_btState;

    //try to turn on bluetooth. but on different platforms may fail.
    // if(state==QBluetoothLocalDevice::HostMode::HostPoweredOff)
    // {
        // qInfo() << "bluetooth device is powered off . try to turn it on.";
        // m_localDevice.powerOn();
        // bool re = m_localDevice.hostMode()==QBluetoothLocalDevice::HostPoweredOff ? false : true;
        // qInfo() << "could powere on? " << re;
    // }

    //check for discoverablity e.g on ubuntu 24.4 it turn to connectable (hidden) after approx 3 minutes being discoverable
    if(m_btState==QBluetoothLocalDevice::HostConnectable && m_alwaysDiscoverable) //make it always discoverable
    {
        qInfo() << "hsot state is connectable lets try make it discoverable again..";
        m_localDevice.setHostMode(QBluetoothLocalDevice::HostDiscoverable);
        bool re = m_localDevice.hostMode()==QBluetoothLocalDevice::HostDiscoverable ? true : false;
        qInfo() << "could make discoverable? " << re;
    }

    emit btStateChanged(m_btState);
}

void ChatServer::setAlwaysDiscoverable(bool newAlwaysDiscoverable)
{
    //currenly is not discoverable make it discoverable
    if(!m_alwaysDiscoverable)
    {
        m_localDevice.setHostMode(QBluetoothLocalDevice::HostDiscoverable);
        qInfo() << "now device set to discoverable.";
    }

    m_alwaysDiscoverable = newAlwaysDiscoverable;
}

void ChatServer::disconnectClient(QBluetoothSocket *target)
{
    if(target)
        target->disconnectFromService();
    else
        qInfo()<<"invalid client to disconnect";
}

QBluetoothLocalDevice::HostMode ChatServer::btState() const
{
    return m_btState;
}

QMap<QBluetoothSocket *, QString> ChatServer::getClientNames() const
{
    return clientNames;
}
//! [readSocket]
