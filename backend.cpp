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


void Backend::clientConnected(const QString &name)
{
    qInfo () <<  name << " has conncted to server.\n";
}

void Backend::clientDisconnected(const QString &name)
{
    qInfo () <<  name << " has disconnected from server.\n";
}

void Backend::messageReceived(const QString &sender, const QString &message)
{
    qInfo() << "message received from("  << sender << "): "
            << message;

    emit sendMessage("reply:"+message);
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

        connect(m_btServer, QOverload<const QString &>::of(&ChatServer::clientConnected),
                this, &Backend::clientConnected);

        connect(m_btServer, QOverload<const QString &>::of(&ChatServer::clientDisconnected),
                this,  QOverload<const QString &>::of(&Backend::clientDisconnected));

        connect(m_btServer, &ChatServer::messageReceived,
                this,  &Backend::messageReceived);

        connect(this, &Backend::sendMessage,
                m_btServer, &ChatServer::sendMessage);


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

void Backend::setBtStatus(BtStatus status)
{
    m_btStatus = status;
    emit btStatusChanged();
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

void Backend::refreshBluetoothAdapters()
{
    QList<QBluetoothHostInfo> currentAdapters = QBluetoothLocalDevice().allDevices();
    setBtLocalAdapters(currentAdapters);
}
