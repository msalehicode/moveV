#include "backend.h"

Backend::Backend(const SettingsManager* const settings, QObject *parent)
    : QObject{parent}, m_settings(settings)
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
