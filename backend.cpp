#include "backend.h"

Backend::Backend(QObject *parent)
    : QObject{parent}
{}

Backend::Backend(QGuiApplication *app) : m_app(app)
{

}

bool Backend::setAppCursor(int cursor)
{
    if(cursor>=0 && cursor <= 24) //cursor valuse from enum Qt::CursorShape
        m_app->setOverrideCursor(QCursor(static_cast<Qt::CursorShape>(cursor)));
    else //invalid cursor
        return false;

    return true;
}
