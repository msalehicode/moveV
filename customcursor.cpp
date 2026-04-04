#include "customcursor.h"
CustomCursor::CustomCursor(QObject *parent)
    : QObject{parent}, m_customCursor(nullptr)
{

}

CustomCursor::~CustomCursor()
{
    delete m_customCursor;
}

bool CustomCursor::setupCustomCursor(const QUrl &imageUrl, int width, int height, int hotX, int hotY)
{
    if(imageUrl.scheme() == "file")
    {
        m_cursorImage.load(imageUrl.toLocalFile());
        if(!m_cursorImage.isNull())
        {
            //check for image size if its too large show error dont proceed
            if(m_cursorImage.height()>64 || m_cursorImage.width()>64)
            {
                qWarning()<< "selected image is too large to set for custom cursor!";
                return false;
            }

            //make sure no memory leak from previous call this function
            if(m_customCursor!=nullptr)
                delete m_customCursor;

            cursorPixmap = QPixmap::fromImage(m_cursorImage);
            m_customCursor = new QCursor(cursorPixmap, hotX, hotY);
            return true;
        }
        else
            qWarning() << "failed to load image for custom cursor:" << imageUrl.toLocalFile();
    }
    else
        qWarning() << "unsupported url scheme  for custom cursor image, only local files  are supported:";

    return false;
}

bool CustomCursor::setCursor(int cursor)
{
    if(cursor>=0 && cursor <= 24) //cursor valuse from enum Qt::CursorShape
    {
        m_currentCursor = QCursor(static_cast<Qt::CursorShape>(cursor));
        QGuiApplication::setOverrideCursor(m_currentCursor);
        return true;
    }

    //invalid cursor
    qWarning() << "invalid cursor id to set.";
    return false;
}

void CustomCursor::loadCustom()
{
    QGuiApplication::setOverrideCursor(*m_customCursor);
}

bool CustomCursor::isCustomSet() const
{
    return (m_customCursor!=nullptr)? true : false;
}



void CustomCursor::restoreDefaultCursor()
{
    QGuiApplication::setOverrideCursor(QCursor(Qt::ArrowCursor));
}

