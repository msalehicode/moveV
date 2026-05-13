#include "getwordtranslate.h"

GetWordTranslate::GetWordTranslate(QObject *parent) : QObject(parent)
{

}

void GetWordTranslate::getTranslate(const QString &text, const QString &lang)
{
    QString baseUrl = QString("https://dic.b-amooz.com/%1/dictionary/w?word=%2").arg(lang, text);

    QUrl url(baseUrl);

    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Mozilla/5.0"); // Required

    qDebug() << "Requesting:" << url.toString();
    manager.get(request);
    connect(&manager, &QNetworkAccessManager::finished, this, &GetWordTranslate::onHtmlReply);
}

void GetWordTranslate::onHtmlReply(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError)
    {
        qWarning() << "Network error:" << reply->errorString();
        reply->deleteLater();
        disconnect(&manager, &QNetworkAccessManager::finished, this, &GetWordTranslate::onHtmlReply);
        emit translateResult(false, "");
        return;
    }
    else
    {
        QByteArray data = reply->readAll();
        QString html = QString::fromUtf8(data);

        // qDebug() << "getWordResult= " << html;

        reply->deleteLater();
        disconnect(&manager, &QNetworkAccessManager::finished, this, &GetWordTranslate::onHtmlReply);
        emit translateResult(true, html);
    }
}
