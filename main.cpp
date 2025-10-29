#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "subtitleextractor.h"
#include "subtitlefinder.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<SubtitleExtractor>("CustomMedia", 1, 0, "SubtitleExtractor");
    qmlRegisterType<SubtitleFinder>("SubtitleFinder", 1, 0, "SubtitleFinder");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("moveV", "Main");

    return app.exec();
}
