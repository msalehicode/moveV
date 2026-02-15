// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QDir>
#include <QMediaFormat>
#include <QMimeType>
#include <algorithm>
#include <QQmlContext>
// #include "bluetoothserver.h"
#include "subtitleextractor.h"
#include "subtitlefinder.h"




//handle pause play... commands from handsfree, and gnome notification to manage media and show metadata of media
#include <QDBusConnection>
#include "mprisadaptor.h"
#include "mprisrootadaptor.h"
#include <QDBusError>
// #include "bluezmediaplayer.h"


//to set media.role make sure app get foucs and attention from os
#include <QProcessEnvironment>


using namespace Qt::Literals::StringLiterals;

struct NameFilters
{
    QStringList filters;
    int preferred = 0;
};

static NameFilters nameFilters()
{
    QStringList result;
    QString preferredFilter;
    const auto formats = QMediaFormat().supportedFileFormats(QMediaFormat::Decode);
    for (qsizetype m = 0, size = formats.size(); m < size; ++m) {
        const auto format = formats.at(m);
        QMediaFormat mediaFormat(format);
        const QMimeType mimeType = mediaFormat.mimeType();
        if (mimeType.isValid()) {
            QString filter = QMediaFormat::fileFormatDescription(format) + " ("_L1;
            const auto suffixes = mimeType.suffixes();
            for (qsizetype i = 0, size = suffixes.size(); i < size; ++i) {
                if (i)
                    filter += u' ';
                filter += "*."_L1 + suffixes.at(i);
            }
            filter += u')';
            result.append(filter);
            if (mimeType.name() == "video/mp4"_L1)
                preferredFilter = filter;
        }
    }
    std::sort(result.begin(), result.end());
    const int preferred = preferredFilter.isEmpty() ? 0 : int(result.indexOf(preferredFilter));
    return { result, preferred };
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);


    // Set the media role to "video"
    qputenv("PULSE_PROP", "media.role=video");

    QCoreApplication::setApplicationName("MediaPlayer Example");
    QCoreApplication::setOrganizationName("QtProject");
    QCoreApplication::setApplicationVersion(QT_VERSION_STR);
    QCommandLineParser parser;
    parser.setApplicationDescription(QCoreApplication::translate("main", "Qt Quick MediaPlayer Example"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addPositionalArgument("url", QCoreApplication::translate("main", "The URL(s) to open."));
    parser.process(app);

    qmlRegisterType<SubtitleExtractor>("CustomMedia", 1, 0, "SubtitleExtractor");
    qmlRegisterType<SubtitleFinder>("SubtitleFinder", 1, 0, "SubtitleFinder");


    QQmlApplicationEngine engine;

    QObject::connect(&engine, &QQmlApplicationEngine::quit, &app, &QGuiApplication::quit);

    QUrl source;
    if (!parser.positionalArguments().isEmpty())
        source = QUrl::fromUserInput(parser.positionalArguments().at(0), QDir::currentPath());

    const auto filters = nameFilters();
    QVariantMap initialProperties{
        {"source", source},
        {"nameFilters", filters.filters},
        {"selectedNameFilter", filters.preferred}
    };

    engine.setInitialProperties(initialProperties);
    engine.loadFromModule("MediaPlayer", "Main");





    //dbus

    if (engine.rootObjects().isEmpty())
        return -1;

    QObject *rootObject = engine.rootObjects().first();

    // Create BOTH adaptors
    new MprisRootAdaptor(rootObject);
    new MprisAdaptor(rootObject, "/org/mpris/MediaPlayer2");


    QDBusConnection connection = QDBusConnection::sessionBus();

    connection.registerService("org.mpris.MediaPlayer2.myplayer");

    connection.registerObject(
        "/org/mpris/MediaPlayer2",
        rootObject,
        QDBusConnection::ExportAdaptors
        );


    if (!connection.registerService("org.mpris.MediaPlayer2.myplayer")) {
        qWarning() << "Failed to register D-Bus service:" << connection.lastError().message();
    }


    //handle bluz
    // BluezMediaPlayer *bluezPlayer = new BluezMediaPlayer(rootObject);

    // QDBusConnection systemBus = QDBusConnection::systemBus();
    // if (!systemBus.registerObject("/org/bluez/hci0/player0", rootObject, QDBusConnection::ExportAdaptors)) {
    //     qWarning() << "Failed to register system-bus BlueZ MediaPlayer";
    // }

    // if (!systemBus.registerService("org.bluez")) {
    //     qWarning() << "Failed to register system-bus BlueZ service";
    // }





    return app.exec();
}
