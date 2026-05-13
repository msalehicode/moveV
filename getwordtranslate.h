#ifndef GETWORDTRANSLATE_H
#define GETWORDTRANSLATE_H

#include <QObject>


#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <QDebug>
#include <QRegularExpression>

#include <QNetworkRequest>
#include <QUrlQuery>


class GetWordTranslate : public QObject
{
    Q_OBJECT

public:
    GetWordTranslate(QObject *parent = nullptr);

    Q_INVOKABLE void getTranslate(const QString &text, const QString &lang = "en");

signals:
    void translateResult(bool status,const QString data);

private slots:
    void onHtmlReply(QNetworkReply *reply);

private:
    QNetworkAccessManager manager;
};

#endif



