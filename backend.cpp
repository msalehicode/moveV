#include "backend.h"

Backend::Backend(QObject *parent)
    : QObject{parent}
{}

Backend::Backend(QGuiApplication *app) : m_app(app), m_customCursorStatus(false)
{

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
        cc.setCursor(0);
    else if(mode=="blank")
        cc.setCursor(10);
    else if(mode=="wait")
        cc.setCursor(3);
    else if(mode=="hand")
        cc.setCursor(13);
    else if(mode=="custom")
        cc.loadCustom();
    else
    {
        if(cc.isCustomSet() && m_customCursorStatus)
            cc.loadCustom();
        else
            QGuiApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));
    }
}

void Backend::setCustomCursorStatus(int status)
{
    m_customCursorStatus = status;
}

bool Backend::customCursorStatus() const
{
    return m_customCursorStatus;
}

