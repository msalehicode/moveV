#include "netserver.h"


NetServer::NetServer(QObject *parent)
{

    //to get state
    // backendLoaded = QNetworkInformation::loadDefaultBackend();
    // info == QNetworkInformation::instance();
    // connect(info, &QNetworkInformation::reachabilityChanged,
    //         this, &NetServer::onNetStateChanged);
}

NetServer::~NetServer()
{
    if(m_server->isListening())
    {
        stopServer();
    }
}

bool NetServer::startServer(quint16 port)
{
    if(m_server)
    {
        qCritical()<< "cant start server m_server exists";
        return false;
    }

    m_server = new QTcpServer(this);
    if(m_server->listen(QHostAddress::Any, port))
    {
        connect(m_server, &QTcpServer::newConnection,
                this,  &NetServer::onClientConnected);

        qInfo() << "netserver: listining " << m_server->serverAddress().toString()
                << ":" << m_server->serverPort();
        return true;
    }
    else
    {
        qCritical() << "failed to start net server on HostAddressAny, port=" << port
                    << " errorMessage:" << m_server->errorString();
    }
    return false;
}

void NetServer::stopServer()
{
    //disconnect all connected usrs;
    for(QTcpSocket* socket : m_clientSockets)
    {
        disconnectClient(socket);
    }

    //clear lists
    m_clientSockets.clear();

    // Close sockets
    qDeleteAll(m_clientSockets);

    // Close server
    m_server->close();
    // delete m_server;
    // m_server = nullptr;
}

QString NetServer::getServerIpPort()
{
    QString ipList; //= m_server->serverAddress().toString(); //local address
    QString port = ":"+QString::number(m_server->serverPort());
    // find out IP addresses of this machine
    const QList<QHostAddress> ipAddressesList = QNetworkInterface::allAddresses();
    // add non-localhost addresses
    for (const QHostAddress &entry : ipAddressesList)
    {
        if (!entry.isLoopback())
            ipList+= "\n"+entry.toString() + port;
    }
    // if(ipList.isEmpty())
    // {
        ipList+= "(LOCAL): ";
        // add localhost addresses
        for (const QHostAddress &entry : ipAddressesList)
        {
            if (entry.isLoopback())
                ipList+= "\n"+entry.toString() + port;
        }
    // }




    if(m_server->isListening())
        return ipList;

    return "ip:port";
}

void NetServer::disconnectClient(QTcpSocket *target)
{
    if(target)
    {
        target->disconnectFromHost();
    }
    else
        qInfo()<<"invalid client to disconnect.";
}

void NetServer::sendMessage(QTcpSocket *receiver, const QString &message)
{
    QByteArray text = message.toUtf8() + '\n';
    // qDebug() << "ntSocket sendingMEssage QSTring: " << message << "data=" << text;
    receiver->write(text);
}

void NetServer::sendMessage(QTcpSocket *receiver, const QByteArray &data)
{
    // qDebug() << "ntSocket sendingMEssage QByteArray: " << data;
    receiver->write(data);
}

void NetServer::onClientConnected()
{
    QTcpSocket* socket = m_server->nextPendingConnection();
    if (!socket)
        return;

    qDebug() << "client connected name:" << socket->peerName()
             << "address=" << socket->peerAddress().toString()
             << ":" << socket->peerPort();

    connect(socket, &QTcpSocket::readyRead,
            this, &NetServer::onReadSocket);

    connect(socket, &QTcpSocket::disconnected,
            this, &NetServer::onClientDisconnected);

    m_clientSockets.append(socket);
    emit clientConnected(socket);
}

void NetServer::onClientDisconnected()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket *>(sender());
    if (!socket)
        return;

    emit clientDisconnected(socket);

    m_clientSockets.removeOne(socket);

    socket->deleteLater();
}

void NetServer::onReadSocket()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket *>(sender());
    if (!socket)
        return;

    while(socket->canReadLine())
    {
        QByteArray line = socket->readLine().trimmed();
        // QString::fromUtf8(line.constData(), line.length()));
        emit messageReceived(socket, line);
    }
}

// void NetServer::onNetStateChanged(QNetworkInformation::Reachability state)
// {
//     qDebug() << "netState changed: " << state;
//     if(m_netState!=state)
//     {
//         m_netState = state;
//         emit netStateChanged(state);
//     }
// }
