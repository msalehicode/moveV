#include "backend.h"

Backend::Backend(const SettingsManager* const settings, QGuiApplication *app, QObject *parent)
    : m_settings(settings), m_app(app), QObject{parent}
{
    // QObject::connect(bt, &m_btServer::)
    // QObject::connect(m_bt)


    //get saved setting from settings
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
        qInfo() << "starting blutooth server.";
        initBluetoothServer();
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
    qInfo () <<  sender->peerName() << " has conncted to server.\n";

    //add him to our clinets list
    RemoteUsers* usr = new RemoteUsers{UserConnectionStatus::Connected, UserAccess::Normal, sender};
    addUser(usr);
    emit sendMessage("welcome");
}

void Backend::clientDisconnected( QBluetoothSocket *  sender)
{
    qInfo () <<  sender->peerName() << " has disconnected from server.\n";
    //remove him from our clinets list
}

void Backend::messageReceived( QBluetoothSocket*  sender, const QString &message)
{
    qInfo() << "message received from("  << sender->peerName() << "): "
            << message;

    //who is this sender?!
    RemoteUsers* user = findUser(sender);
    // if(user)
        processCommand(user,message);
    // else
        // qInfo() << "undefined user!";

}

void Backend::initBluetoothServer()
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
        }break; // proceed to initialization
    }
#endif // QT_CONFIG(permissions)




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


        // make discoverable
        setBtStatus(BtStatus::Discoverable);
        QBluetoothLocalDevice adapter(m_btLocalAdapters.at(0).address());
        adapter.setHostMode(QBluetoothLocalDevice::HostDiscoverable);





        //! [Create Chat Server]
        setBtStatus(BtStatus::Loading);

        if(m_btServer) //user is trying to start again
        {
            delete m_btServer;
        }

        m_btServer = new ChatServer(this);

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
            if(!m_btServer->startServer(m_btLocalAdapters.at(indexCurrentAdaptor).address()))
            {
                qInfo() << "btServer starting failed.";
                setBtStatus(BtStatus::Failed);
            }
            else
            {
                //! [Get local device name]
                m_btLocalName = QBluetoothLocalDevice().name();
                qInfo () << "bt started, local name= " << m_btLocalName;
                //! [Get local device name]

                setBtStatus(BtStatus::Active);
            }
        }

        //! [Create Chat Server]
    }


    qInfo() << "btstatus=" << btStatus();
}

void Backend::processCommand(RemoteUsers *user, const QString &message)
{
    QString response = "default response";
    qInfo() << "processing command from:"<< user->socket->peerName() << "command:" << message;
    // switch (user->access)
    // {
    //     case UserAccess::Admin:
    //     {

    //     }break;
    //     case UserAccess::Normal:
    //     {

    //     }break;
    //     default: qInfo () << "invalid acecss";
    //         break;
    // }
    if(user)
        emit sendMessage(user->socket, response);
    else
        qInfo() << "user is nullptr";
}

void Backend::setBtStatus(BtStatus status)
{
    m_btStatus = status;
    emit btStatusChanged();
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
            qInfo() << "userFound from m_users";
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
