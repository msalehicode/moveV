#ifndef CUSTOMCURSOR_H
#define CUSTOMCURSOR_H

#include <QObject>
#include <QCursor>
#include <QPoint>
#include <QImage>
#include <QUrl>
#include <QPixmap>
#include <QGuiApplication>

class CustomCursor : public QObject
{
    Q_OBJECT

    QImage m_cursorImage;
    QCursor* m_customCursor;
    QPixmap cursorPixmap;

    QCursor m_currentCursor;

public:
    explicit CustomCursor(QObject *parent = nullptr);
    ~CustomCursor();

    bool setupCustomCursor(const QUrl& imageUrl, int width, int height, int hotX, int hotY);
    void changeCursor();
    void restoreDefaultCursor();
    bool setCursor(int cursor);
    void loadCustom();
    bool isCustomSet()const;

signals:
};

#endif // CUSTOMCURSOR_H
