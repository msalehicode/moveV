#include "backend.h"

Backend::Backend(SettingsManager* settings, QGuiApplication *app, QObject *parent)
    : m_settings(settings),
    m_app(app),
    QObject{parent},
    m_btServer{nullptr},
    m_btMaxConnectionUser(2),
    m_btLocalName("empty"),
    m_btStatus(BtStatus::Unknown),
    indexCurrentAdaptor(0),
    m_IsDBusConnectionOk(false),
    m_netServer(nullptr),
    m_ntStatus(NetStatus::Unknown),
    m_netLocalName("empty"),
    m_hostPassword(""),
    m_hostPasswordStatus(false),
    m_isTherePreviousTrack(false),
    m_isThereNextTrack(false),
    m_mprisAdaptor(nullptr)

{
    QThread* t= QThread::currentThread();
    qDebug() << "backend constructor on Thread:" << t;

    //read mprisControl status from settings
    QVariant settingVariant = m_settings->getSetting("App/mprisControl",false);
    bool status = settingVariant.value<bool>();
    setMprisControl(status);


    //read hostPasswrodStauts from settings.
    settingVariant = m_settings->getSetting("App/hostPasswordStatus",false);
    status = settingVariant.value<bool>();
    setHostPasswordStatus(status);

    //read password..
    settingVariant = m_settings->getSetting("App/hostPassword","");
    setHostPassword(settingVariant.value<QString>());


    //setup ping users
    m_pingUsersTimer.setInterval(SERVER_PING_USERS_TIMER_INTERVAL);
    connect(&m_pingUsersTimer, &QTimer::timeout,
            this, &Backend::sendPingToAllUsers);

}

void Backend::initMpris()
{
    qInfo() << "initilizing mpris...";

    // Create BOTH adaptors
    new MprisRootAdaptor(m_rootObject);
    if(!m_mprisAdaptor) //if mprisAdapter doesnt exists otherwise use old mprisAdaptor
        m_mprisAdaptor = new MprisAdaptor(m_rootObject, "/org/mpris/MediaPlayer2");


    QDBusConnection connection = QDBusConnection::sessionBus();

    connection.registerService("org.mpris.MediaPlayer2.myplayer");


    if (!connection.registerObject("/org/mpris/MediaPlayer2",
                                   m_rootObject,
                                   QDBusConnection::ExportAdaptors))
    {
        qWarning() << "Failed to register D-Bus object:" << connection.lastError().message()
        << "Error name:" << connection.lastError().name();
        setIsDBusConnectionOk(false);
        setMprisControl(false);
        return;
    }
    else
    {
        qInfo() << "D-Bus object registered successfully.";
    }


    if (!connection.registerService("org.mpris.MediaPlayer2.myplayer"))
    {
        qWarning() << "Failed to register D-Bus service:" << connection.lastError().message();
        setIsDBusConnectionOk(false);
        setMprisControl(false);
        return;
    }
    else
        qInfo() << "D-BUS service registered successfully.";




    //connect mpris signals to back slots
    connect(m_mprisAdaptor, &MprisAdaptor::sPlay,
            this , &Backend::mprisPlay);

    connect(m_mprisAdaptor, &MprisAdaptor::sPause,
            this , &Backend::mprisPause);

    connect(m_mprisAdaptor, &MprisAdaptor::sPlayNext,
            this , &Backend::mprisPlayNext);

    connect(m_mprisAdaptor, &MprisAdaptor::sPlayPause,
            this , &Backend::mprisPlayPause);

    connect(m_mprisAdaptor, &MprisAdaptor::sPlayPrevious,
            this , &Backend::mprisPlayPrevious);

    setIsDBusConnectionOk(true);
}

void Backend::closeMpris()
{
    qInfo() << "closing mpris..";
    QDBusConnection connection = QDBusConnection::sessionBus();
    if (connection.isConnected())
    {
        qInfo() << "Unregistering D-Bus object and service...";

        // Unregister the object
        connection.unregisterObject("/org/mpris/MediaPlayer2");

        // Unregister the service name
        connection.unregisterService("org.mpris.MediaPlayer2.myplayer");

        qInfo() << "D-Bus object and service unregistered.";
    }
}

void Backend::runQmlFunction(const QString &functionName)
{
    if(m_rootObject)
        QMetaObject::invokeMethod(m_rootObject, functionName.toLatin1().data());
    else
        qCritical() <<"m_rootObject is null can't run qml function";
}

QVariant Backend::runQmlFunction(const QString &functionName, QVariant argum)
{
    QVariant returnedValue;
    if(m_rootObject)
    {

        QMetaObject::invokeMethod(m_rootObject, functionName.toLatin1().data(),
                                  Q_RETURN_ARG(QVariant, returnedValue),
                                  Q_ARG(QVariant, argum));
        //qDebug() << "runQmlFunction: Retuerend value: " << returnedValue.toString();
    }
    else
        qCritical() <<"m_rootObject is null can't run qml function";

    return returnedValue;
}

void Backend::btCheckPermission()
{
#if QT_CONFIG(permissions)
    QBluetoothPermission permission{};
    switch (m_app->checkPermission(permission))
    {
        case Qt::PermissionStatus::Undetermined:
        {
            qInfo() << "user hasn't been asked or hasn't responded to the permission request yet";
            qDebug() << "lets ask for permission";
            setBtStatus(BtStatus::AskingPermission);
            m_app->requestPermission(permission, this, &Backend::initBluetoothServer); //permission requests are asynchronous.
        }return;
        case Qt::PermissionStatus::Denied:
        {
            qInfo() << "user has explicitly refused to grant the Bluetooth permission.";
            qDebug() << "Permissions are needed to use Bluetooth. "
                       "Please grant the permissions to this "
                       "application in the system settings.";
            setBtStatus(BtStatus::DeniedPermission);
            // m_app->quit();
        }return;
        case Qt::PermissionStatus::Granted:
        {
            qInfo() <<"bluetooth permission is fine. we proceed to stuff";
            setBtStatus(BtStatus::GrantedPermission);
            initBluetoothServer();
        }return;
    }

#endif // QT_CONFIG(permissions)
    return;
}

bool Backend::setupCustomCursor(const QUrl &imageUrl, int width, int height, int hotX, int hotY)
{
    return cc.setupCustomCursor(imageUrl,width,height,hotX,hotY);
}

bool Backend::restoreCursor()
{
    cc.restoreDefaultCursor();
    return true;
}

void Backend::changeCursor(const QString &mode)
{
    if(mode=="arrow")
    {
        cc.setCursor(0);
    }
    else if(mode=="blank")
    {
        cc.setCursor(10);
    }
    else if(mode=="wait")
    {
        cc.setCursor(3);
    }
    else if(mode=="hand")
    {
        cc.setCursor(13);
    }
    else if(mode=="verReposition")
    {
        cc.setCursor(5);
    }
    else if(mode=="horReposition")
    {
        cc.setCursor(6);
    }
    else if(mode=="custom")
    {
        if(cc.isCustomSet())
            cc.loadCustom();
    }
    else
    {
        QVariant settingVariant = m_settings->getSetting("App/customCursorStatus",false);
        bool status = settingVariant.value<bool>();
        if(cc.isCustomSet() && status)
            cc.loadCustom();
        else
            QGuiApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));
    }
}

void Backend::netServer(const bool &status)
{
    if(status)
    {
        setNtStatus(NetStatus::Starting); //when status is starting, on QML start/stop button will be disabled untill we change it to something else

        //a delay before starting, assuming server was last second on. to prevent any probelms..
        if(m_netServer)
        {
            qInfo() << "net tcp server is on, stopping before statring....";
            m_netServer->stopServer();
        }
        qInfo() << "net tcp server will try to start next 2s.";
        QTimer::singleShot(2000, [this]()
                           {
                               qInfo() << "starting net tcp server...";
                               initNetServer();
                           });

    }
    else
    {
        if(m_netServer)
        {
            qInfo() << "stopping net tcp server.";
            m_netServer->stopServer();


            //disconnect signal slots. to avoid duplicate call
            disconnect(m_netServer, &NetServer::clientConnected,
                    this, QOverload<QTcpSocket *>::of(&Backend::clientConnected));

            disconnect(m_netServer, &NetServer::clientDisconnected,
                    this,  QOverload<QTcpSocket *>::of(&Backend::clientDisconnected));

            disconnect(m_netServer, &NetServer::messageReceived,
                    this,   QOverload<QTcpSocket *, QByteArray>::of(&Backend::messageReceived));


            disconnect(this, QOverload<QTcpSocket*, const QString &>::of(&Backend::sendMessage),
                    m_netServer, QOverload<QTcpSocket*, const QString &>::of(&NetServer::sendMessage));

            disconnect(this, QOverload<QTcpSocket*, const QByteArray &>::of(&Backend::sendMessage),
                    m_netServer, QOverload<QTcpSocket*, const QByteArray &>::of(&NetServer::sendMessage));



            setNtStatus(NetStatus::Inactive);
        }

    }
}


void Backend::bluetoothServer(const bool &status)
{
    if(status)
    {
        setBtStatus(BtStatus::Starting); //when status is starting, on QML start/stop button will be disabled untill we change it to something else

        //a delay before starting, assuming server was last second on. to prevent any probelms..
        if(m_btServer)
        {
            qInfo() << "blutooth server is on, stopping before statring....";
            m_btServer->stopServer();
        }
        qInfo() << "bluetooth server will try to start next 2s.";
        QTimer::singleShot(2000, [this]()
        {
            qInfo() << "starting blutooth server...";
            btCheckPermission();
        });

    }
    else
    {
        if(m_btServer)
        {
            qInfo() << "stopping blutooth server.";
            m_btServer->stopServer();

            //disconnect signal slots. to avoid duplicate call
            disconnect(m_btServer, QOverload<QBluetoothLocalDevice::HostMode>::of(&ChatServer::btStateChanged),
                    this, &Backend::bluetoothStateChanged);

            disconnect(m_btServer, QOverload<QBluetoothSocket *>::of(&ChatServer::clientConnected),
                    this, QOverload<QBluetoothSocket *>::of(&Backend::clientConnected));

            disconnect(m_btServer, QOverload<QBluetoothSocket *>::of(&ChatServer::clientDisconnected),
                    this,  QOverload<QBluetoothSocket *>::of(&Backend::clientDisconnected));


            disconnect(m_btServer, &ChatServer::messageReceived,
                    this,  QOverload<QBluetoothSocket *,QByteArray >::of(&Backend::messageReceived));


            disconnect(this, QOverload<const QString &>::of(&Backend::sendMessage),
                    m_btServer, QOverload<const QString &>::of(&ChatServer::sendMessage));

            // Connection for sending a message to a specific client
            disconnect(this, QOverload<QBluetoothSocket*, const QString &>::of(&Backend::sendMessage),
                    m_btServer, QOverload<QBluetoothSocket*, const QString &>::of(&ChatServer::sendMessage));

            //send qbytearray directly to receiver.
            disconnect(this, QOverload<QBluetoothSocket*, const QByteArray &>::of(&Backend::sendMessage),
                    m_btServer, QOverload<QBluetoothSocket*, const QByteArray &>::of(&ChatServer::sendMessage));


            setBtStatus(BtStatus::Inactive);
        }

    }
}


void Backend::clientConnected( QBluetoothSocket*  sender)
{
    QString userAddress = sender->peerAddress().toString()+":"+QString::number(static_cast<int>(sender->peerPort()));
    QString userName = sender->peerName();

    //check if user exists refuse connetion
    if(findUser(userAddress))
    {
        qInfo() << userName << " ("<< userAddress << ") tried to connect to server but refused (address exists!).";
        m_btServer->disconnectClient(sender);
        return;
    }

    if(!m_bannedUsers.contains(userAddress))
    {
        //add him to our clinets list
        RemoteUsers* user = new RemoteUsers(userName,userAddress,
                                            UserConnectionType::Bluetooth,nullptr,sender);
        addUser(user);


        initConnectionLost(user);


        qInfo() <<  userName << " has conncted to server.\n";

        //if passwrod is required ask him enter password.
        if(m_hostPasswordStatus)
            emit sendMessage(sender,m_commandHandler.pack(CommandHandler::Command::EnterPassword,""));
    }
    else
    {
        qInfo() << userName << " ("<< userAddress << ") tried to connect to server but refused (banned).";
        sendMessage(sender,m_commandHandler.pack(CommandHandler::Command::Banned,""));
        m_btServer->disconnectClient(sender);
    }
}

void Backend::clientDisconnected(QBluetoothSocket *  sender)
{
    RemoteUsers* user = findUser(sender);
    if(user)
    {
        qInfo() <<  user->name <<  " (using " << user->convertConnectionType() <<  ") has disconnected from server.\n";

        //delete that socket/user
        m_users.removeOne(user);

        emit connectedUsersListChanged();
    }

}

void Backend::doProcessPing(RemoteUsers* user)
{
    if(user->pingTimer.isValid())
    {
        user->pingMs = user->pingTimer.elapsed();

        //set proper status for user
        user->status = UserConnectionStatus::Connected;

        //reset connection lost counter and timer.
        user->connectionLostCounter=0;
        user->connectionLostTimer.stop();

        emit connectedUsersListChanged();//tell qml data changed
    }
    else
        qDebug() << "user pingTimer is not valid.";
}

bool Backend::isTherePreviousTrack() const
{
    return m_isTherePreviousTrack;
}

void Backend::setIsTherePreviousTrack(bool newIsTherePreviousTrack)
{
    if (m_isTherePreviousTrack == newIsTherePreviousTrack)
        return;
    m_isTherePreviousTrack = newIsTherePreviousTrack;
    emit isTherePreviousTrackChanged();
}

bool Backend::isThereNextTrack() const
{
    return m_isThereNextTrack;
}

void Backend::setIsThereNextTrack(bool newIsThereNextTrack)
{
    if (m_isThereNextTrack == newIsThereNextTrack)
        return;
    m_isThereNextTrack = newIsThereNextTrack;
    emit isThereNextTrackChanged();
}

bool Backend::hostPasswordStatus() const
{
    return m_hostPasswordStatus;
}

void Backend::setHostPasswordStatus(bool newHostPasswordStatus)
{
    if (m_hostPasswordStatus == newHostPasswordStatus)
        return;
    m_hostPasswordStatus = newHostPasswordStatus;

    //save status at settings file
    m_settings->setSetting("App/hostPasswordStatus",newHostPasswordStatus);
    emit hostPasswordStatusChanged();
}

bool Backend::setHostPassword(QString pass)
{
    if(pass.length()>0 && pass.length()<200)
    {
        m_hostPassword=pass;
        m_settings->setSetting("App/hostPassword",pass);
        return true;
    }
    return false;
}

void Backend::messageReceived(QBluetoothSocket* sender, QByteArray data)
{
    qDebug() << "message received from("  << sender->peerName() << "): "
            << data;

    //who is this sender?!
    RemoteUsers* user = findUser(sender);
    if(user)
    {
        //check if its pong message or not
        if(data==CommandHandler::PONG_DATA)
            doProcessPing(user);
        else
            processCommand(user,&data);

    }
    else
        qInfo() << "coult not pass received message to process due to user/sender isn't valid (not found)";

}


QString Backend::toPureIPv4(const QHostAddress &addr)
{
    auto ipv6 = addr.toIPv6Address();
    quint32 ipv4 =
        (ipv6.c[12] << 24) |
        (ipv6.c[13] << 16) |
        (ipv6.c[14] << 8)  |
        ipv6.c[15];

    return QHostAddress(ipv4).toString();
}


QString Backend::getPlayerLatestStatus()
{
    QList<QVariant> dataToPack;
    // dataToPack << QString("subtitle1Status") << 45;
    qInfo() << "getPlayerLatestStatus";

    for (const QString &key : CommandHandler::commandKeyMap.keys())
    {
        if(key.length()>1) //avoid get setting for not exists keys.
            dataToPack << m_settings->getSetting(key, "");
        else //for specific keys which doesnt exist on settings so m_settings(getSetting) won't be able find their value, set them manually
            if(key=="1")
            {
                QList<QVariant> metadata;
                qInfo() << "currentmedia " << m_currentMedia.name << " "<< m_currentMedia.length;
                metadata.append(m_currentMedia.name);
                metadata.append(m_currentMedia.length);
                QString dd = m_commandHandler.packPayload(metadata);
                qInfo() << "dd=" << dd;
                dataToPack << dd;
            }

    }

    QString payload = m_commandHandler.packPayload(dataToPack);

    // qDebug() << "Packed Payload:" << payload;
    /* -------- LATER ADD TO PAYLOAD-- -- - -- - -
                current media (name, total time, played time)
                Audio Output Devices List (names)
                selected audio output device index. 0
                repeated (no repeat, repeat this one, repeat list)
                fullscreen,
                isPlaying,
                shuffeled,
                brightness, volume
                current audio output
            */
    return payload;
}



void Backend::clientConnected(QTcpSocket *sender)
{
    QString userIpv4 = toPureIPv4(sender->peerAddress());
    QString userAddress = userIpv4+":"+QString::number(static_cast<int>(sender->peerPort()));
    QString userName = sender->peerName();

    //check if user exists refuse connetion
    if(findUser(userAddress))
    {
        qInfo() << userName << " ("<< userAddress << ") tried to connect to server but refused (address exists!).";
        sendMessage(sender,m_commandHandler.pack(CommandHandler::Command::AlreadyConnected,""));
        m_netServer->disconnectClient(sender);
        return;
    }


    if(!m_bannedUsers.contains(userIpv4))
    {
        //add him to our clinets list
        RemoteUsers* user = new RemoteUsers(userName,userAddress,
                                            UserConnectionType::Network,sender,nullptr);
        addUser(user);

        initConnectionLost(user);

        qInfo() <<  userName << " has conncted to server.\n";

        //if passwrod is required ask him enter password.
        if(m_hostPasswordStatus)
            emit sendMessage(sender,m_commandHandler.pack(CommandHandler::Command::EnterPassword,""));
    }
    else
    {
        qInfo() << userName << " ("<< userIpv4 << ") tried to connect to server but refused (banned).";
        emit sendMessage(sender,m_commandHandler.pack(CommandHandler::Command::Banned,""));
        m_netServer->disconnectClient(sender);
    }
}
void Backend::initConnectionLost(RemoteUsers* user)
{
    if(user)
    {
        user->connectionLostTimer.setInterval(CLIENT_CONNECTIONLOST_TIMER_INTERVAL);
        connect(&(user->connectionLostTimer), &QTimer::timeout,
                [user]()
                {
                    // qInfo() << "user connetionlost timer timeout . counter:" << user->connectionLostCounter;
                    if(user->pingMs==DEFAULT_CLIENT_PING)
                        user->connectionLostCounter++;
                });
    }
    else
        qInfo()<< "failed to ini connection lost for nullptr user.";
}

void Backend::clientDisconnected(QTcpSocket *sender)
{
    RemoteUsers* user = findUser(sender);
    if(user)
    {
        qInfo() <<  user->name <<  " (using " << user->convertConnectionType() <<  ") has disconnected from server.\n";

        //delete that socket/user
        m_users.removeOne(user);

        emit connectedUsersListChanged();
    }

}

void Backend::messageReceived(QTcpSocket *sender, QByteArray data)
{
    qDebug() << "message received from("  << sender->peerName() << "): "
             << data;

    //who is this sender?!
    RemoteUsers* user = findUser(sender);
    if(user)
    {
        //check if its pong message or not
        if(data==CommandHandler::PONG_DATA)
            doProcessPing(user);
        else
            processCommand(user,&data);

    }
    else
        qInfo() << "coult not pass received message to process due to user/sender isn't valid (not found)";

}





void Backend::bluetoothStateChanged(QBluetoothLocalDevice::HostMode state)
{
    switch (state)
    {
        case QBluetoothLocalDevice::HostPoweredOff:
            qDebug() << "hostMode state is powered off";
            break;
        case QBluetoothLocalDevice::HostConnectable:
            qDebug() <<  "hostMode state is connectable";
            break;
        case QBluetoothLocalDevice::HostDiscoverable:
            qDebug() << "hostMode state is discoverable";
            break;
        case QBluetoothLocalDevice::HostDiscoverableLimitedInquiry:
            qDebug() <<  "hostMode state is discoveralbe limited inquiry";
            break;
        default:
            qCritical() << "hostMode state is unkown hostmode state. state=" << state;
            break;
    }
    setBluetoothHostModeState(state);
}

void Backend::mprisPlayNext()
{
    if(m_mprisControl)
        processCommand(nullptr,nullptr,CommandHandler::Command::NextToggle);
}

void Backend::mprisPlayPrevious()
{
    if(m_mprisControl)
        processCommand(nullptr,nullptr,CommandHandler::Command::PreviousToggle);
}

void Backend::mprisPlay()
{
    if(m_mprisControl)
        processCommand(nullptr,nullptr,CommandHandler::Command::Play);
}

void Backend::mprisPause()
{
    if(m_mprisControl)
        processCommand(nullptr,nullptr,CommandHandler::Command::Pause);
}

void Backend::mprisPlayPause()
{
    if(m_mprisControl)
        processCommand(nullptr,nullptr,CommandHandler::Command::PlayToggle);
}

void Backend::initBluetoothServer()
{

    setBtLocalAdapters(QBluetoothLocalDevice::allDevices());

    if (m_btLocalAdapters.isEmpty())
    {
        qWarning("Local adapter is not found.");
        setBtStatus(BtStatus::AdapterNotFound);
    }
    else
    {
        //print adapters
        qDebug()<<"adaptor list:";
        for(const auto& item : m_btLocalAdapters)
        {
            qDebug() << "Name:" << item.name()
            << "Address=" << item.address().toString()
            << " (Raw Address Object:" << item.address() << ")";
        }


        // make discoverable, we assume selecte device index is
        QBluetoothLocalDevice adapter(m_btLocalAdapters.at(indexCurrentAdaptor).address());
        adapter.setHostMode(QBluetoothLocalDevice::HostDiscoverable);//it's tempoerary as discoverable, will turn to Connectable after a while...
        setBtStatus(BtStatus::Discoverable);

        //! [Create Chat Server]

        setBtStatus(BtStatus::Loading);
        m_btServer = new ChatServer(this);

        connect(m_btServer, QOverload<QBluetoothLocalDevice::HostMode>::of(&ChatServer::btStateChanged),
                this, &Backend::bluetoothStateChanged);

        connect(m_btServer, QOverload<QBluetoothSocket *>::of(&ChatServer::clientConnected),
                this, QOverload<QBluetoothSocket *>::of(&Backend::clientConnected));

        connect(m_btServer, QOverload<QBluetoothSocket *>::of(&ChatServer::clientDisconnected),
                this,  QOverload<QBluetoothSocket *>::of(&Backend::clientDisconnected));


        connect(m_btServer, &ChatServer::messageReceived,
                this,  QOverload<QBluetoothSocket *,QByteArray >::of(&Backend::messageReceived));


        connect(this, QOverload<const QString &>::of(&Backend::sendMessage),
                m_btServer, QOverload<const QString &>::of(&ChatServer::sendMessage));

        // Connection for sending a message to a specific client
        connect(this, QOverload<QBluetoothSocket*, const QString &>::of(&Backend::sendMessage),
                m_btServer, QOverload<QBluetoothSocket*, const QString &>::of(&ChatServer::sendMessage));

        //send qbytearray directly to receiver.
        connect(this, QOverload<QBluetoothSocket*, const QByteArray &>::of(&Backend::sendMessage),
                m_btServer, QOverload<QBluetoothSocket*, const QByteArray &>::of(&ChatServer::sendMessage));



        if(m_btLocalAdapters.size() < indexCurrentAdaptor)
        {
            qWarning () << "invalid indexCurrentAdaptor (index isn't < localAdaptorsList.size)";
            setBtStatus(BtStatus::AdapterNotFound);
        }
        else
        {
            if(!m_btServer->startServer(m_btLocalAdapters.at(indexCurrentAdaptor).address(), m_btMaxConnectionUser))
            {
                qWarning() << "btServer starting failed.";
                setBtStatus(BtStatus::Failed);
            }
            else
            {
                setBtStatus(BtStatus::Active);

                //load and set bluetooth always disoverable
                QVariant settingVariant = m_settings->getSetting("App/bluetoothHostAlwaysDiscoverable",false);
                bool status = settingVariant.value<bool>();
                qDebug() << "bluetooth always discoverable read from settings is: " << status;
                setBtAlwaysDiscoverable(status);


            }


            //anyway we set (status, name) to show client what is status
            setBluetoothHostModeState(m_btServer->btState());
        }

        //! [Create Chat Server]
    }


    qDebug() << "init bluetooth server finished, status=" << btStatus();
}

void Backend::initNetServer()
{

    setNtStatus(NetStatus::Loading);
    m_netServer = new NetServer(this);

    //later net status
    // connect(m_netServer, QOverload<QBluetoothLocalDevice::HostMode>::of(&NetServer::netStateChanged),
    //         this, &Backend::bluetoothStateChanged);

    connect(m_netServer, &NetServer::clientConnected,
            this, QOverload<QTcpSocket *>::of(&Backend::clientConnected));

    connect(m_netServer, &NetServer::clientDisconnected,
            this,  QOverload<QTcpSocket *>::of(&Backend::clientDisconnected));

    connect(m_netServer, &NetServer::messageReceived,
            this,   QOverload<QTcpSocket *, QByteArray>::of(&Backend::messageReceived));


    connect(this, QOverload<QTcpSocket*, const QString &>::of(&Backend::sendMessage),
            m_netServer, QOverload<QTcpSocket*, const QString &>::of(&NetServer::sendMessage));

    connect(this, QOverload<QTcpSocket*, const QByteArray &>::of(&Backend::sendMessage),
            m_netServer, QOverload<QTcpSocket*, const QByteArray &>::of(&NetServer::sendMessage));



    if(!m_netServer->startServer(SERVER_NETWORK_HOST_PORT))
    {
        qWarning() << "net tcp server starting failed.";
        setNtStatus(NetStatus::Failed);
    }
    else
    {
        qInfo() <<"net tcp server started fine.";
        setNtStatus(NetStatus::Active);
    }

    //we set (server ip: server port) to show client what is ip:port
    //if server failed to start will set LocalName to (ip:port)
    setNetLocalName(m_netServer->getServerIpPort());
}



void Backend::processCommand(RemoteUsers *user, QByteArray *data,
                             CommandHandler::Command localCommand,QString thePayload)
{
    QString response = "default response";
    CommandHandler::Command cmd;
    QString value;


    if(user==nullptr || data==nullptr) //its a command by local (mpris/kyeboardmouse)
    {
        qDebug() << "processing from mpris/localControl(mouse,keyboard), command=" << localCommand;
        cmd=localCommand;
        value=thePayload;

        /*
         *  m_mprisAdaptor->control.canPlay=true;
            m_mprisAdaptor->control.canPause=true;
            m_mprisAdaptor->control.canGoNext=false;
            m_mprisAdaptor->control.canGoPrevious=true;
            m_mprisAdaptor->control.canControl=true;
            m_mprisAdaptor->updateMetadata(true,"title playing media"
                                           ,"artist is not"
                                           ,"1");
         */
    }
    else
    {
        QByteArray ba = *data;
        cmd = m_commandHandler.unpack(ba,value);

        //process received clientInfo
        if(cmd==CommandHandler::Command::ClientInfo)
        {
            qDebug() << "client info received: " << value;


            QList<QVariant> unpackedPayloads = m_commandHandler.unpackPayload(value);
            // qDebug() << "unpackedPayloads.size()=" << unpackedPayloads.size();
            user->versionCode = unpackedPayloads[static_cast<int>(CommandHandler::ClientInfoIndexes::CI_VERSION_CODE)].toInt();
            if(user->versionCode<MINIMUM_ALLOWED_VERSION_CODE_REMOTE)
            {
                qInfo() << "client version is not allowed, versionCode:" << user->versionCode << " connection refused.";
                sendResponse(user,m_commandHandler.pack(CommandHandler::Command::VersionIsOutDated,""));
                if(user->connectionType==UserConnectionType::Bluetooth)
                    m_btServer->disconnectClient(user->btSocket);
                else if(user->connectionType==UserConnectionType::Network)
                    m_netServer->disconnectClient(user->netSocket);

                return;//version error has sent dont proceed
            }
            user->name = unpackedPayloads[static_cast<int>(CommandHandler::ClientInfoIndexes::CI_MACHINE_HOST_NAME)].toString();
            user->platform = unpackedPayloads[static_cast<int>(CommandHandler::ClientInfoIndexes::CI_PLATFORM)].toString();
            user->info = unpackedPayloads; //store it for future uses.

            //send mediaplayer latest info to client (becauuse authentication is off.)
            if(!m_hostPasswordStatus)
                sendResponse(user,m_commandHandler.pack(CommandHandler::Command::MediaPlayerData,getPlayerLatestStatus()));
            //else send mediaplaer latest info would done after authentication.

            emit connectedUsersListChanged();
            return;//info extracted so no need to proceed.
        }
        else if(user->versionCode==0)//check user version is (0) which is default.
        {
            qInfo() << "user didnt provide clientInfo properly connection closed due to invalid version";
            sendResponse(user,m_commandHandler.pack(CommandHandler::Command::VersionNotProvided,""));
            if(user->connectionType==UserConnectionType::Bluetooth)
                m_btServer->disconnectClient(user->btSocket);
            else if(user->connectionType==UserConnectionType::Network)
                m_netServer->disconnectClient(user->netSocket);
            return;//version is not provided
        }

        //if password is required, check for password.
        if(m_hostPasswordStatus && !user->authenticated)
        {
            //check for command maybe he is trying to login
            if(cmd==CommandHandler::Command::EnterPassword)
            {
                if(value==m_hostPassword)
                {
                    qInfo() << "user " <<  user->name << " authenticated successfully.";
                    user->authenticated=true;
                    sendResponse(user,m_commandHandler.pack(CommandHandler::Command::AthenticatedFine,""));

                    //send mediaplayer latest info to client (becauuse authentication is done.)
                    sendResponse(user,m_commandHandler.pack(CommandHandler::Command::MediaPlayerData,getPlayerLatestStatus()));

                    emit connectedUsersListChanged();
                }
                else
                {
                    qInfo() << "user " <<  user->name << " entered wrong password!";
                    //later add CLIENT_MAX_INCORRECT_PASSWORD_ATTEMPS and ban user if attempts exceeded.
                    sendResponse(user,m_commandHandler.pack(CommandHandler::Command::WrongPassword,""));
                }
            }
            else
            {
                qDebug() << "unathenticated user. asking him enter password...";
                sendResponse(user,m_commandHandler.pack(CommandHandler::Command::EnterPassword,""));
            }
            return;//response sent no need to proceed
        }



        if(user->connectionType == UserConnectionType::Bluetooth)
        {
            qDebug() << "processing command using bluetooth, from:"<< user->btSocket->peerName() << "cmd=" << cmd << "val="
                     << "cmd-int:" << static_cast<int>(cmd) << value <<" data:" << data;
        }
        else if(user->connectionType == UserConnectionType::Network)
        {
            qDebug() << "processing command using network, from:"<< user->netSocket->peerName() << "cmd=" << cmd << "val="
                     << "cmd-int:" << static_cast<int>(cmd) << value <<" data:" << data;
        }
    }

    if(m_settings->getSetting("App/showControlsWhenRemoteCommand",true).toBool())
        emit mediaPlayerDataChange(CommandHandler::Command::ShowControls, "");


    bool updateMprisAdaptor=false;
    switch (cmd)
    {
        //no need to action, qml slot would act.
        case CommandHandler::Command::StartSpeeding:
        case CommandHandler::Command::StopSpeeding:
        case CommandHandler::Command::SeekBack:
        case CommandHandler::Command::SeekForth:
        case CommandHandler::Command::ShuffleToggle:
        case CommandHandler::Command::FullscreenToggle:
        case CommandHandler::Command::RepeatToggle:
        case CommandHandler::Command::PreviousToggle:
        case CommandHandler::Command::NextToggle:
        case CommandHandler::Command::ModifyBrightness:
        case CommandHandler::Command::ModifyPlayRate:
        case CommandHandler::Command::ModifyPosition:
        case CommandHandler::Command::ModifyVolume:
        case CommandHandler::Command::VolumeDown:
        case CommandHandler::Command::VolumeUp:
        case CommandHandler::Command::BrightnessDown:
        case CommandHandler::Command::BrightnessUp:
        case CommandHandler::Command::SpeedDown:
        case CommandHandler::Command::SpeedUp:
        case CommandHandler::Command::ShowControls:
            break; //dont check others
        case CommandHandler::Command::PlayToggle:
            m_unstoredMPdata.isPlaying = !m_unstoredMPdata.isPlaying;
            updateMprisAdaptor=true;
            break;
        case CommandHandler::Command::Play: //only called by mpris
            m_unstoredMPdata.isPlaying=true;
            updateMprisAdaptor=true;
            break;
        case CommandHandler::Command::Pause: //only called by mpris
            m_unstoredMPdata.isPlaying=false;
            updateMprisAdaptor=true;
            break;

        //handled here. no need QML action
        case CommandHandler::Command::Subtitle1Status: m_settings->setSetting("Subtitle1/status",value); break;
        case CommandHandler::Command::Subtitle1TranslateWordByClick: m_settings->setSetting("Subtitle1/translateWordByClick",value); break;
        case CommandHandler::Command::Subtitle1WordByWord: m_settings->setSetting("Subtitle1/wordByWord",value); break;
        case CommandHandler::Command::Subtitle1WordByWordChunks: m_settings->setSetting("Subtitle1/wordByWordChunks",value); break;
        case CommandHandler::Command::Subtitle1TextSize: m_settings->setSetting("Subtitle1/textSize",value); break;
        case CommandHandler::Command::Subtitle1Offset: m_settings->setSetting("Subtitle1/offset",value); break;
        case CommandHandler::Command::Subtitle1TextColor: m_settings->setSetting("Subtitle1/textColor",value); break;
        case CommandHandler::Command::Subtitle1BackColor: m_settings->setSetting("Subtitle1/backColor",value); break;
        case CommandHandler::Command::Subtitle1Opacity: m_settings->setSetting("Subtitle1/backOpacity",value); break;
        //sub2
        case CommandHandler::Command::Subtitle2Status: m_settings->setSetting("Subtitle2/status",value); break;
        case CommandHandler::Command::Subtitle2TranslateWordByClick: m_settings->setSetting("Subtitle2/translateWordByClick",value); break;
        case CommandHandler::Command::Subtitle2WordByWord: m_settings->setSetting("Subtitle2/wordByWord",value); break;
        case CommandHandler::Command::Subtitle2WordByWordChunks: m_settings->setSetting("Subtitle2/wordByWordChunks",value); break;
        case CommandHandler::Command::Subtitle2TextSize: m_settings->setSetting("Subtitle2/textSize",value); break;
        case CommandHandler::Command::Subtitle2Offset: m_settings->setSetting("Subtitle2/offset",value); break;
        case CommandHandler::Command::Subtitle2TextColor: m_settings->setSetting("Subtitle2/textColor",value); break;
        case CommandHandler::Command::Subtitle2BackColor: m_settings->setSetting("Subtitle2/backColor",value); break;
        case CommandHandler::Command::Subtitle2Opacity: m_settings->setSetting("Subtitle2/backOpacity",value); break;

        case CommandHandler::Command::SteadyAudioDeviceToggle:
            m_settings->setSetting("App/steadyAudioDevice",value=="true"?true:false);
            break;

        case CommandHandler::Command::SubRemoveDomainsToggle:
            m_settings->setSetting("Media/sub_removeDomains",value=="true"?true:false);
            break;

        case CommandHandler::Command::SubIgnoreHtmlTagToggle:
            m_settings->setSetting("Media/sub_ignoreHTMLtags",value=="true"?true:false);
            break;

        case CommandHandler::Command::SubCleanSubtitleToggle:
            m_settings->setSetting("Media/sub_cleanSubtitle",value=="true"?true:false);
            break;

        case CommandHandler::Command::SubRemoveExtraInfoToggle:
            m_settings->setSetting("Media/sub_removeExtraInfo",value=="true"?true:false);
            break;

        case CommandHandler::Command::CustomCursorStatusToggle:
            m_settings->setSetting("App/customCursorStatus",value=="true"?true:false);
            //fore to update cursor
            changeCursor(); //let it choose blank or pointer/pixelImage
            break;

        case CommandHandler::Command::MprisControlToggle:
        {
            bool status = (value=="true"?true:false);
            setMprisControl(status);
            m_settings->setSetting("App/mprisControl",status);
            if(m_mprisControl)
                initMpris();
            else
                closeMpris();
        }break;

        case CommandHandler::Command::CurrentMediaMeta:
            m_currentMedia.name=value.split("`").at(1);
            m_currentMedia.length=value.split("`").at(2).toInt();
            // qDebug() << "name: " << value.split("`").at(1) << " duration:" << value.split("`").at(2);

            // qDebug() << m_currentMedia.name << " " << m_currentMedia.length;
            m_unstoredMPdata.isPlaying=true;
            updateMprisAdaptor=true;
            break;

        case CommandHandler::Command::SNSspeed:
        {
            m_settings->setSetting("SNS/speed",value);
        }break;

        case CommandHandler::Command::MuteToggle:
        {
            m_settings->setSetting("Media/muted", !m_settings->getSetting("Media/muted",false).toBool());
        }break;


        case CommandHandler::Command::Subtitle1PosY:
        {
            m_settings->setSetting("Subtitle1/posY", value);
            qDebug() << "subtitle1posy" << value;
        }break;

        case CommandHandler::Command::Subtitle2PosY:
        {
            m_settings->setSetting("Subtitle2/posY", value);
        }break;

        case CommandHandler::Command::HostPasswordStatusToggle:
        {
            setHostPasswordStatus(value=="true"?true:false);
        }break;



        //also QML will apply to element
        case CommandHandler::Command::ModifyRotation:
        {
            m_settings->setSetting("Media/rotationAngle",value);
        }break;

        case CommandHandler::Command::SNSToggle:
        {
            m_settings->setSetting("SNS/status",value);
        }break;


        //etc
        // case CommandHandler::Command::SNSsecBeforeSpeedup: //has loop problem
        // {
        //     m_settings->setSetting("SNS/secBeforeSpeedup",value);
        // }break;
        // case CommandHandler::Command::SNSsecAfterSpeedup: //has loop problem
        // {
        //     m_settings->setSetting("SNS/secAfterSpeedup",value);
        // }break;

        default:
            qInfo()<<"action hasn't provided. can't process this command :" << cmd << " value=" << value;
            return; //dont broadcast.
    }

    //update mpris adaptor
    if(updateMprisAdaptor)
    {
        m_mprisAdaptor->control.canPlay=true;
        m_mprisAdaptor->control.canPause=true;
        m_mprisAdaptor->control.canGoNext=true;
        m_mprisAdaptor->control.canGoPrevious=true;
        m_mprisAdaptor->control.canControl=true;
        m_mprisAdaptor->updateMetadata(m_unstoredMPdata.isPlaying
                                       ,m_currentMedia.name
                                       ,"artist is not"
                                       ,"1");
    }

    //broadcast to connected clients
    sendResponseToAll(m_commandHandler.pack(cmd,value));

    //apply into mediaplayer
    emit mediaPlayerDataChange(cmd, value);
}

void Backend::processCommand(CommandHandler::Command cmd, QString payload)
{
    processCommand(nullptr,nullptr, cmd,payload);
}

void Backend::sendResponse(RemoteUsers* user, const QString& response)
{
    if(user)
    {
        qInfo()<< "sending reponse to user from processCommand.";
        if(user->connectionType == UserConnectionType::Bluetooth)
        {
            emit sendMessage(user->btSocket, response);//maybe later broadcast  to all connected users.
        }
        else if(user->connectionType == UserConnectionType::Network)
        {
            emit sendMessage(user->netSocket, response);//maybe later broadcast  to all connected users.
        }
        else
            qDebug() << "user connection type undefined could not send resposne.";
    }

    else
        qCritical() << "cant send response to nullptr user";
}

void Backend::sendResponse(RemoteUsers* user, QByteArray response)
{
    if(user)
    {
        qInfo()<< "sending reponse to user from processCommand.";
        if(user->connectionType == UserConnectionType::Bluetooth)
        {
            emit sendMessage(user->btSocket, response);//maybe later broadcast  to all connected users.
        }
        else if(user->connectionType == UserConnectionType::Network)
        {
            emit sendMessage(user->netSocket, response);//maybe later broadcast  to all connected users.
        }
        else
            qDebug() << "user connection type undefined could not send resposne.";
    }

    else
        qCritical() << "cant send response to nullptr user";
}

void Backend::sendResponseToAll(QByteArray response)
{
    qDebug() << "send repsonse to all response:" << response;
    if(m_users.isEmpty())
    {
        qDebug() << "no user found. cant sendResponseToAll.";
        return;
    }

    for (RemoteUsers* user : m_users)
    {
        // Check if user is actually connected and has a socket
        if(user->btSocket != nullptr || user->netSocket != nullptr)
        {
            if(user->connectionType == UserConnectionType::Bluetooth)
            {
                emit sendMessage(user->btSocket,response);
            }
            else if(user->connectionType == UserConnectionType::Network)
            {
                emit sendMessage(user->netSocket,response);
            }
        }
        else
            qDebug() << "user has no socket cant sendResponseToAll for him.";
    }
}


void Backend::sendPingToAllUsers()
{
    if(m_users.isEmpty())
    {
        m_pingUsersTimer.stop();
        qDebug() << "no user found. stoppping timer for now.";
        return;
    }

    //send ping
    // qDebug() << "Sending pings to all connected clients...";
    for (RemoteUsers* user : m_users)
    {
        // Check if user is actually connected and has a socket
        if(user->btSocket != nullptr || user->netSocket != nullptr)
        {
            user->pingTimer.restart();

            user->pingMs = DEFAULT_CLIENT_PING;

            //to find out wether user is connection lost or not.
            if(user->connectionLostCounter==0)
                user->connectionLostTimer.start();
            else //user is on connecton lost stage!
            {
                //set proper status for user
                user->status = UserConnectionStatus::ConnectionLost;

                //check if user connection lost counter exceed from MAX or not
                if(user->connectionLostCounter>CLIENT_MAX_CONNECTIONLOST_COUNT)
                {
                    qInfo() << "user exceed max connection lost count. disconencting him...";
                    user->connectionLostTimer.stop();

                    sendResponse(user,m_commandHandler.pack(CommandHandler::Command::ConnectionLost,""));
                    if(user->connectionType == UserConnectionType::Bluetooth)
                        m_btServer->disconnectClient(user->btSocket);
                    else if(user->connectionType == UserConnectionType::Network)
                        m_netServer->disconnectClient(user->netSocket);

                }
            }


            emit connectedUsersListChanged();

            if(user->connectionType == UserConnectionType::Bluetooth)
            {
                // qDebug()<< "sending ping for bluetooth.";
                emit sendMessage(user->btSocket,CommandHandler::PING_DATA);
            }

            else if(user->connectionType == UserConnectionType::Network)
            {
                // qDebug()<< "sending ping for network.";
                emit sendMessage(user->netSocket,CommandHandler::PING_DATA);
            }


            // qDebug() << "Sent ping to" << user->name << " (" << user->address << ") PING_DATA=(" << CommandHandler::PING_DATA << ")";
        }
    }

}

void Backend::init()
{
    QThread* t= QThread::currentThread();
    qDebug() << "backend init on Thread:" << t;
}

QString Backend::netLocalName() const
{
    return m_netLocalName;
}

void Backend::setNetLocalName(const QString &newNetLocalName)
{
    if (m_netLocalName == newNetLocalName)
        return;
    m_netLocalName = newNetLocalName;
    emit netLocalNameChanged();
}

QString Backend::btLocalName() const
{
    return m_btLocalName;
}

void Backend::setBtLocalName(const QString &newBtLocalName)
{
    if (m_btLocalName == newBtLocalName)
        return;
    m_btLocalName = newBtLocalName;
    emit btLocalNameChanged();
}

QBluetoothLocalDevice::HostMode Backend::bluetoothHostModeState()
{
    return m_bluetoothHostModeState;
}

void Backend::setBluetoothHostModeState(QBluetoothLocalDevice::HostMode state)
{
    m_bluetoothHostModeState = state;

    //set lable (name of device or error message) for qml
    QString hostModeInfo;
    switch(m_bluetoothHostModeState)
    {
    case QBluetoothLocalDevice::HostPoweredOff:
        hostModeInfo= "Bluetooth is OFF";
        break;
    case QBluetoothLocalDevice::HostConnectable:
        hostModeInfo="Only Direct Connections";
        break;
    case QBluetoothLocalDevice::HostDiscoverable:
        hostModeInfo="Discoverable";
        break;
    case QBluetoothLocalDevice::HostDiscoverableLimitedInquiry:
        hostModeInfo= "Limited inquiry";
    default:
        setBtLocalName("Unkown State: "+QString::number(state));
    }

    setBtLocalName(m_btLocalAdapters.at(indexCurrentAdaptor).name()
                   + " [" + m_btLocalAdapters.at(indexCurrentAdaptor).address().toString() + "]"
                   + " (" + hostModeInfo + ")");

    emit bluetoothHostModeStateChanged();
}

void Backend::setBtStatus(BtStatus status)
{
    m_btStatus = status;
    emit btStatusChanged();
}

bool Backend::IsDBusConnectionOk() const
{
    return m_IsDBusConnectionOk;
}

void Backend::setIsDBusConnectionOk(bool newIsDBusConnectionOk)
{
    if (m_IsDBusConnectionOk == newIsDBusConnectionOk)
        return;
    m_IsDBusConnectionOk = newIsDBusConnectionOk;
    emit IsDBusConnectionOkChanged();
}

NetStatus Backend::ntStatus() const
{
    return m_ntStatus;
}

void Backend::setNtStatus(NetStatus newNetStatus)
{
    if(m_ntStatus==newNetStatus)
        return;
    m_ntStatus=newNetStatus;
    emit ntStatusChanged();
}

bool Backend::mprisControl() const
{
    return m_mprisControl;
}

void Backend::setMprisControl(bool newMprisControl)
{
    if(!m_IsDBusConnectionOk) //limit changes if dbus connection failed.
        return;

    if (m_mprisControl == newMprisControl)
        return;

    m_mprisControl = newMprisControl;
    emit mprisControlChanged();
}

void Backend::retryMprisConnection()
{
    closeMpris();
    initMpris();
}

void Backend::setRootObject(QObject *newRootObject)
{
    m_rootObject = newRootObject;
}

bool Backend::btAlwaysDiscoverable() const
{
    return m_btAlwaysDiscoverable;
}

void Backend::setBtAlwaysDiscoverable(bool newAlwaysDiscoverable)
{
    m_btAlwaysDiscoverable = newAlwaysDiscoverable;
    if(m_btServer)
        m_btServer->setAlwaysDiscoverable(m_btAlwaysDiscoverable);
    emit btAlwaysDiscoverableChanged();
}

QStringList Backend::bannedUsers() const
{
     return m_bannedUsers.values(); // convert QSet -> QStringList
}

void Backend::unbanUser(QString address)
{
    if(m_bannedUsers.contains(address))
    {
        m_bannedUsers.remove(address);
        emit bannedUsersChanged();
    }
    else
        qInfo()<<"invalid address to unban.";
}

int Backend::btMaxConnectionUser() const
{
    return m_btMaxConnectionUser;
}

void Backend::setBtMaxConnectionUser(int newBtMaxConnectionUser)
{
    if (m_btMaxConnectionUser == newBtMaxConnectionUser)
        return;

    m_btMaxConnectionUser = newBtMaxConnectionUser;
    qInfo()<< "bt maxConnection changed. server need to restart.";

    //start server (has a delay e.g singleshot 5s so no worries before start) (if server is on will stop first)
    bluetoothServer(true);

    emit btMaxConnectionUserChanged();
}



QList<RemoteUsers *> Backend::users() const
{
    return m_users;
}

RemoteUsers* Backend::findUser(QTcpSocket* userSocket) const
{
    if (!userSocket)
    {
        qInfo() << "unable to findUser socket is nullptr";
        return nullptr;
    }

    for (RemoteUsers* user : m_users)
    {
        if (user->netSocket == userSocket)
        {
            // qDebug() << "userFound from m_users";
            return user;
        }
    }

    return nullptr;
}



RemoteUsers* Backend::findUser(QBluetoothSocket *userSocket) const
{
    if (!userSocket)
    {
        qInfo() << "unable to findUser socket is nullptr";
        return nullptr;
    }

    for (RemoteUsers* user : m_users)
    {
        if (user->btSocket == userSocket)
        {
            // qDebug() << "userFound from m_users";
            return user;
        }
    }

    return nullptr;
}

RemoteUsers *Backend::findUser(QString &address)
{
    if(address.isEmpty())
        return nullptr;

    for (RemoteUsers* user : m_users)
    {
        if (user->address == address)
        {
            // qDebug() << "userFound from m_users";
            return user;
        }
    }

    return nullptr;
}

void Backend::setUsers(const QList<RemoteUsers*> &newUsers)
{
    m_users = newUsers;
}

void Backend::addUser(RemoteUsers *newUser)
{
    m_users.append(newUser);

    if(!m_pingUsersTimer.isActive())
    {
        qDebug() << "a user found, starting ping timer.";
        m_pingUsersTimer.start();
    }


    emit connectedUsersListChanged();
}

QVariantList Backend::connectedUsersAsVariantList() const
{
    // qDebug() << "running connectedUsersAsVariantList. User count:" << m_users.size();

    QVariantList variantList;
    for (const RemoteUsers* user : m_users)
    {
        if (!user)
            continue;

        QList<QString> userInfo = user->getAsStringList();
        QVariantMap userMap;
        userMap["name"] = userInfo.at(0);
        userMap["address"] = userInfo.at(1);
        userMap["status"] = userInfo.at(2);
        userMap["access"] = userInfo.at(3);
        userMap["connectedAt"] = userInfo.at(4);
        userMap["using"] = userInfo.at(5);
        userMap["ping"] = userInfo.at(6);
        userMap["authenticated"] = userInfo.at(7);
        userMap["version"] = userInfo.at(8);
        userMap["platform"] = userInfo.at(9);
        variantList.append(userMap);
    }
    return variantList;
}

void Backend::kickUser(QString address)
{
    RemoteUsers* user = findUser(address);
    if(user)
    {
        qInfo() << "user " << user->name << "(" << user->address << ") has been kicked.";
        sendResponse(user,m_commandHandler.pack(CommandHandler::Command::Kicked,""));
        if(user->connectionType==UserConnectionType::Bluetooth)
        {
            m_btServer->disconnectClient(user->btSocket);
            //assuming bterver will run clientDisconnected and user would remove from m_users
        }

        else if(user->connectionType==UserConnectionType::Network)
        {
            m_netServer->disconnectClient(user->netSocket);
            //assuming m_netServer will run clientDisconnected and user would remove from m_users
        }
    }
    else
        qInfo() << "invalid user to kick";
}

void Backend::banUser(QString address)
{
    RemoteUsers* user = findUser(address);
    if(user)
    {
        if(user->connectionType==UserConnectionType::Bluetooth)
        {
            //add user's address to banList
            if(!m_bannedUsers.contains(user->address))
            {
                m_bannedUsers.insert(user->address);
                emit bannedUsersChanged();
                qInfo() << "user " << user->name << "(" << user->address << ") has been banned.";
                sendResponse(user,m_commandHandler.pack(CommandHandler::Command::Banned,""));
                //disconnect him
                m_btServer->disconnectClient(user->btSocket);
                //assuming bterver will run clientDisconnected and user would remove from m_users
            }
            else
                qInfo() << "user has already banned.";
        }
        else if(user->connectionType==UserConnectionType::Network)
        {
            //remove user ip from user->address ipv4:port
            QString userIp = user->address.split(':').first();
            //check wether address has already banned or not
            if(!m_bannedUsers.contains(userIp))
            {
                //add user's address to banList
                m_bannedUsers.insert(userIp);
                qInfo() << "user " << user->name << "(" << userIp << ") has been banned.";
                sendResponse(user,m_commandHandler.pack(CommandHandler::Command::Banned,""));
                emit bannedUsersChanged();

                //disconnect him
                m_netServer->disconnectClient(user->netSocket);
                //assuming m_netServer will run clientDisconnected and user would remove from m_users
            }
            else
                qInfo() << "user has already banned.";
        }
    }
    else
        qInfo() << "invalid user to ban";
}


BtStatus Backend::btStatus() const
{
    return m_btStatus;
}

// QList<QBluetoothHostInfo> Backend::btLocalAdapters() const
// {
//     return m_btLocalAdapters;
// }

void Backend::setBtLocalAdapters(const QList<QBluetoothHostInfo>& list)
{
    m_btLocalAdapters = list;
    emit btLocalAdaptersChanged();
}

QVariantList Backend::btLocalAdapters() const
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

void Backend::refreshBluetoothAdapters()
{
    QList<QBluetoothHostInfo> currentAdapters = QBluetoothLocalDevice().allDevices();
    setBtLocalAdapters(currentAdapters);
}

QString RemoteUsers::convertUserAccess() const
{
    switch (access)
    {
    case UserAccess::Admin:
        return "admin";
    case UserAccess::Normal:
        return "normal";
    default:
        return "invalid access";
    }
}

QString RemoteUsers::convertConnectionType(bool shortForm) const
{
    switch(connectionType)
    {
    case UserConnectionType::Bluetooth:
        return shortForm? "B" : "Bluetooth";
    case UserConnectionType::Network:
        return shortForm? "N" : "Network";
    default:
        return shortForm? "err" :"invalid connectionType";
    }
}

QString RemoteUsers::convertConnectionStatus() const
{
    switch (status)
    {
    case UserConnectionStatus::UnknownStatus:
        return "unknown";
    case UserConnectionStatus::Connected:
        return "Connected";
    case UserConnectionStatus::ConnectionLost:
        return "ConnectionLost";
    case UserConnectionStatus::Disconnected:
        return "Disconnected";
    default:
        return "invalid status";
    }
}



QList<QString> RemoteUsers::getAsStringList() const
{
    QList<QString> list {
        name,
        address,
        convertConnectionStatus(),
        convertUserAccess(),
        QTime(connectedAt.time()).toString(),
        convertConnectionType(true),
        QString::number(pingMs),
        QString::number(authenticated),
        QString::number(versionCode),
        platform
    };
    return list;
}

