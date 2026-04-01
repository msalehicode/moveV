#include "backend.h"

Backend::Backend(SettingsManager* settings, QGuiApplication *app, QObject *parent)
    : m_settings(settings), m_app(app), QObject{parent}, m_btMaxConnectionUser(2), m_btAlwaysDiscoverable(true)
{
    // QObject::connect(bt, &m_btServer::)
    // QObject::connect(m_bt)


    //get saved setting from settings
}

void Backend::runQmlFunction(const QString &functionName)
{
    if(rootObject)
        QMetaObject::invokeMethod(rootObject, functionName.toLatin1().data());
    else
        qInfo() <<"rootObject is null";
}

QVariant Backend::runQmlFunction(const QString &functionName, QVariant argum)
{
    if(rootObject)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(rootObject, functionName.toLatin1().data(),
                                  Q_RETURN_ARG(QVariant, returnedValue),
                                  Q_ARG(QVariant, argum));
        // qDebug() << "runQmlFunction: Retuerend value: " << returnedValue.toString();
        return returnedValue;
    }
    else
        qInfo() <<"rootObject is null";
}

void Backend::btCheckPermission()
{
#if QT_CONFIG(permissions)
    QBluetoothPermission permission{};
    switch (m_app->checkPermission(permission))
    {
        case Qt::PermissionStatus::Undetermined:
        {
            qInfo () << "user hasn't been asked or hasn't responded to the permission request yet";
            qInfo () << "lets ask for permission";
            setBtStatus(BtStatus::AskingPermission);
            m_app->requestPermission(permission, this, &Backend::initBluetoothServer); //permission requests are asynchronous.
        }return;
        case Qt::PermissionStatus::Denied:
        {
            qInfo () << "user has explicitly refused to grant the Bluetooth permission.";

            qInfo() << "Permissions are needed to use Bluetooth. "
                       "Please grant the permissions to this "
                       "application in the system settings.";
            setBtStatus(BtStatus::DeniedPermission);
            // m_app->quit();
        }return;
        case Qt::PermissionStatus::Granted:
        {
            qInfo () <<"bluetooth permission is fine. we proceed to stuff";
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
        QTimer::singleShot(5000, [this]()
        {
            qInfo() << "starting blutooth server.";
            btCheckPermission();
        });

    }
    else
    {
        if(m_btServer)
        {
            qInfo() << "stopping blutooth server.";
            m_btServer->stopServer();
            setBtStatus(BtStatus::Inactive);
        }

    }
}


void Backend::clientConnected( QBluetoothSocket*  sender)
{
    QString userAddress = sender->peerAddress().toString()+":"+QString::number(static_cast<int>(sender->peerPort()));
    QString userName = sender->peerName();
    if(!m_bannedUsers.contains(userAddress))
    {
        //add him to our clinets list
        RemoteUsers* usr = new RemoteUsers{
            userName,
            userAddress,
            UserConnectionStatus::Connected,
            UserAccess::Normal,
            sender,
            QDateTime::currentDateTime(),
            UserConnectionType::Bluetooth
        };
        addUser(usr);
        qInfo () <<  userName << " has conncted to server.\n";
        emit sendMessage("hello welcome");
    }
    else
    {
        qInfo() << userName << " ("<< userAddress << ") tried to connect to server but refused (banned).";
        emit sendMessage(sender, "you are banned.");
        m_btServer->disconnectClient(sender);
    }
}

void Backend::clientDisconnected(QBluetoothSocket *  sender)
{
    RemoteUsers* user = findUser(sender);
    if(user)
    {
        qInfo () <<  user->name <<  " (using " << user->convertConnectionType() <<  ") has disconnected from server.\n";

        //delete that socket/user
        m_users.removeOne(user);

        emit connectedUsersListChanged();
    }

}

void Backend::messageReceived( QBluetoothSocket*  sender, const QString &message)
{
    qInfo() << "message received from("  << sender->peerName() << "): "
            << message;

    //who is this sender?!
    RemoteUsers* user = findUser(sender);
    if(user)
        processCommand(user,message);
    else
        qInfo() << "user/sender not found (isnt valid)";

}

void Backend::bluetoothStateChanged(QBluetoothLocalDevice::HostMode state)
{
    qInfo() << "backend bluetoothStateChanged run.";
    switch (state)
    {
        case QBluetoothLocalDevice::HostPoweredOff:
            qInfo() << "hostMode state is powered off";
            break;
        case QBluetoothLocalDevice::HostConnectable:
            qInfo() <<  "hostMode state is connectable";
            break;
        case QBluetoothLocalDevice::HostDiscoverable:
            qInfo() << "hostMode state is discoverable";
            break;
        case QBluetoothLocalDevice::HostDiscoverableLimitedInquiry:
            qInfo() <<  "hostMode state is discoveralbe limited inquiry";
            break;
        default:
            qInfo() << "hostMode state is unkown hostmode state. state=" << state;
            break;
    }
    setBluetoothHostModeState(state);
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
        qInfo()<<"adaptor list:";
        for(const auto& item : m_btLocalAdapters)
        {
            qInfo() << "Name:" << item.name()
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
                this, &Backend::clientConnected);

        connect(m_btServer, QOverload<QBluetoothSocket *>::of(&ChatServer::clientDisconnected),
                this,  QOverload<QBluetoothSocket *>::of(&Backend::clientDisconnected));

        connect(m_btServer, &ChatServer::messageReceived,
                this,  &Backend::messageReceived);

        connect(this, QOverload<const QString &>::of(&Backend::sendMessage),
                m_btServer, QOverload<const QString &>::of(&ChatServer::sendMessage));

        // Connection for sending a message to a specific client
        connect(this, QOverload<QBluetoothSocket*, const QString &>::of(&Backend::sendMessage),
                m_btServer, QOverload<QBluetoothSocket*, const QString &>::of(&ChatServer::sendMessage));


        if(m_btLocalAdapters.size() < indexCurrentAdaptor)
        {
            qInfo () << "invalid indexCurrentAdaptor (index isn't < localAdaptorsList.size)";
            setBtStatus(BtStatus::AdapterNotFound);
        }
        else
        {
            qInfo() << "c6:";
            if(!m_btServer->startServer(m_btLocalAdapters.at(indexCurrentAdaptor).address(), m_btMaxConnectionUser))
            {
                qInfo() << "btServer starting failed.";
                setBtStatus(BtStatus::Failed);
            }
            else
            {
                //! [Get local device name]
                // setBtLocalName(QBluetoothLocalDevice().name());

                // qInfo () << "bt started, local name= " << btLocalName();
                //! [Get local device name]

                setBtStatus(BtStatus::Active);
            }


            //anyway we set (status, name) to show client what is status
            setBluetoothHostModeState(m_btServer->btState());
        }

        //! [Create Chat Server]
    }




    qInfo() << "btstatus=" << btStatus();
}

void Backend::processCommand(RemoteUsers *user, const QString &message)
{
    QString response = "default response";
    qInfo() << "processing command from:"<< user->socket->peerName() << "command:" << message;


    QString cmd;
    float value;

    bool ok=false;
    if(message.contains(":"))
    {
        cmd = message.split(":").at(0);
        value = message.split(":").at(1).toFloat(&ok);
        if(!ok)
        {
            value=0.0;
            qInfo() << "cuild not convert qstring to float (value)";
        }
    }
    else //it doesnt have value
        cmd = message;



    if(cmd=="changeVolume")
    {
        // m_settings->setSetting("Media/volume",value);
        qInfo() << "change vol received value= (" << value;
        runQmlFunction("changeVol",value);
        response="set Media/volume:"+QString::number(value);
    }
    else if(cmd=="changeBrightness")
    {
        // m_settings->setSetting("Media/brightness",value);
        qInfo() << "change brightness received value= (" << value;
        runQmlFunction("changeBrightness",value);
        response="set Media/brightness:"+QString::number(value);
    }
    else if(cmd=="rotate")
    {
        m_settings->setSetting("Media/rotationAngle",value);
        response="set Media/rotationAngle:"+QString::number(value);
    }
    else if(cmd=="seeker")
    {
        runQmlFunction("changePosition",value);
    }

    //------------------------ each click +/-
    else if(cmd=="seekBack")
    {
        runQmlFunction("seekBack");
    }
    else if(cmd=="seekForth")
    {
        runQmlFunction("seekForth");
    }
    else if(cmd=="speedUp")
    {
        // m_settings->setSetting("Media/rate","2");
        runQmlFunction("speedUp",0.5);
    }
    else if(cmd=="speedDown")
    {
        // m_settings->setSetting("Media/rate","1");
        runQmlFunction("speedDown",0.5);
    }


    //---- semi-toggle
    else if(cmd=="heldSpeeding")
    {
        // showSpeeding
        runQmlFunction("startHoldSpeeding");

    }
    else if(cmd=="releasedSpeeding")
    {
        runQmlFunction("stopHoldSpeeding");
    }

    //------------------------ toggle (on/off) (current=!current)
    else if(cmd=="powerToggle")
    {
        qInfo() << "poweToggle received..";
    }
    else if(cmd=="snsToggle")
    {
        // m_settings->setSetting("SNS/status","true");
        QVariant v = m_settings->getSetting("SNS/status","false");
        if(v=="1" || v=="true")
            m_settings->setSetting("SNS/status","false");
        else
            m_settings->setSetting("SNS/status","true");
    }
    else if(cmd=="muteToggle")
    {
        runQmlFunction("muteUnmute");
        // m_settings->setSetting("Media/muted","true");
    }
    else if(cmd=="shuffleToggle")
    {
        runQmlFunction("shuffleToggle");
    }
    else if(cmd=="fullscreenToggle")
    {
        runQmlFunction("fullscreenToggle");
    }
    else if(cmd=="repeatToggle")
    {
        qInfo()<<"repeattoglle cmd received";
    }
    else if(cmd=="previousToggle")
    {
        runQmlFunction("previousVideo");
    }
    else if(cmd=="playToggle")
    {
        runQmlFunction("togglePlayPause");
    }
    else if(cmd=="nextToggle")
    {
        runQmlFunction("nextVideo");
    }


    //------------ ETC: open dialogs
    // else if(cmd=="openSettings")
    // {

    // }
    // else if(cmd=="openPlaylist")
    // {

    // }



    // QByteArray data = message.toUtf8();

    // switch(m_commandHandler.parse(&data,response))
    // {
    //     case CommandList::PlayRate:
    //     {
    //         m_settings->setSetting("Media/rate","1.0");//change playrate also QML will obey this beacuse it is synced with value (QPORPERTY)
    //         response = m_commandHandler.generate<QString>("applied");
    //     }break;
    //     case CommandList::Play:
    //     {
    //         m_settings->setSetting("Media/play","false");
    //     }break;
    //     default:
    //         qInfo()<<"unknown command..";

    // }


    //send response of that command/request if user is valid
    if(user)
        emit sendMessage(user->socket, response);
    else
        qInfo() << "user is nullptr";
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

bool Backend::btAlwaysDiscoverable() const
{
    return m_btAlwaysDiscoverable;
}

void Backend::setBtAlwaysDiscoverable(bool newAlwaysDiscoverable)
{
    if (m_btAlwaysDiscoverable == newAlwaysDiscoverable)
        return;
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
        qInfo()<<"this address is not banned.";
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

RemoteUsers* Backend::findUser(QBluetoothSocket *userSocket) const
{
    if (!userSocket)
    {
        qInfo() << "unable to findUser socket is nullptr";
        return nullptr;
    }

    for (RemoteUsers* user : m_users)
    {
        if (user->socket == userSocket)
        {
            // qInfo() << "userFound from m_users";
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
            // qInfo() << "userFound from m_users";
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
    emit connectedUsersListChanged();
}

QVariantList Backend::connectedUsersAsVariantList() const
{
    qInfo() << "running connectedUsersAsVariantList. User count:" << m_users.size();

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
        variantList.append(userMap);
    }
    return variantList;
}

void Backend::kickUser(QString address)
{
    RemoteUsers* user = findUser(address);
    if(user)
    {
        if(user->connectionType==UserConnectionType::Bluetooth)
        {
            qInfo() << "user " << user->name << "(" << user->address << ") has been kicked.";
            m_btServer->disconnectClient(user->socket);
            //assuming bterver will run clientDisconnected and user would remove from m_users
        }

        else if(user->connectionType==UserConnectionType::Wifi)
            qInfo()<<"soon kicking wifi user...";
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
                //disconnect him
                m_btServer->disconnectClient(user->socket);
                //assuming bterver will run clientDisconnected and user would remove from m_users
            }
            else
                qInfo() << "user has already banned.";
        }
        else if(user->connectionType==UserConnectionType::Wifi)
            qInfo()<<"soon ban wifi user...";
    }
    else
        qInfo() << "invalid user to kick";
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
    case UserConnectionType::Wifi:
        return shortForm? "W" : "Wifi";
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
        return "connected";
    case UserConnectionStatus::Disconnected:
        return "disconnected";
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
        convertConnectionType(true)
    };
    return list;
}
