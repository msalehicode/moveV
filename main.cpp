// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QDir>
#include <QMediaFormat>
#include <QMimeType>
#include <QGuiApplication>

#include <algorithm>
#include <QQmlContext>
#include "subtitleextractor.h"
#include "subtitlefinder.h"


//to set media.role make sure app get foucs and attention from os
#include <QProcessEnvironment>
#include <QGuiApplication>



#include "backend.h"
#include "settingsmanager.h"

#include "commandhandler.h"

//to pass session to backend
#include <QDBusConnection>
#include <QDBusError>


#include "logger.h"

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


    //win: c/users/username/appdata/roaming/org/app/
    //lin: ~/.local/share/org/app/
    //mac: ~/library/application support/app/
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(logDir);
    QString logPath = logDir + "/app.log";
    qInfo() << " logger filepath = " << logPath;
    Logger::install(logPath);



    qmlRegisterType<SubtitleExtractor>("CustomMedia", 1, 0, "SubtitleExtractor");
    qmlRegisterType<SubtitleFinder>("SubtitleFinder", 1, 0, "SubtitleFinder");

    QQmlApplicationEngine engine;



    SettingsManager settings;
    Backend backend(&settings,&app);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("settings", &settings);


    qmlRegisterUncreatableType<CommandHandler>("MyCommands", 1, 0, "Command", "Enums only");


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



    if (engine.rootObjects().isEmpty())
        return -1;

    QObject *rootObject = engine.rootObjects().first();


    //pass engine's root Object to backend because we need to call QML functions by c++
    //and mpris needs this rootObject
    backend.setRootObject(rootObject);

    //also handle mpris (bluetooth/keyboard media buttons/os media buttons,os notification dialog)
    backend.initMpris();


    return app.exec();
}
