cmake_minimum_required(VERSION 3.16)

project(MediaPlayerApp LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CM_MPRIS_IDENTITY "MyMediaPlayer")

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2 Svg Multimedia Bluetooth DBus)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(MediaPlayerApp
    main.cpp
    filenameprovider.h
)

qt_add_qml_module(MediaPlayerApp
    URI "io.qt.filenameprovider"
    VERSION 1.0
    SOURCES subtitleextractor.h subtitleextractor.cpp
    SOURCES subtitlefinder.h subtitlefinder.cpp
    SOURCES mprisadaptor.h mprisadaptor.cpp
    SOURCES mprisrootadaptor.h
    SOURCES changeVolumeManually.cpp
    SOURCES backend.h backend.cpp
    SOURCES customcursor.h customcursor.cpp
    SOURCES settingsmanager.h settingsmanager.cpp
)

qt_add_ios_ffmpeg_libraries(MediaPlayerApp)

add_subdirectory(MediaPlayer)
add_subdirectory(MediaControls)
add_subdirectory(Config)
add_subdirectory(BluetoothControl)
add_subdirectory(../CommandHandler ../../build/CommandHandler_build)


target_link_libraries(MediaPlayerApp PRIVATE
    Qt6::Core
    Qt6::Svg
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Bluetooth
    Qt6::DBus
    MediaControlsplugin
    MediaPlayerplugin
    Configplugin
    BluetoothControl #bluetoothControl library (subDirectory)
    MediaPlayer #mediaPlayer library (subDirectory)
    CommandHandler
)

install(TARGETS MediaPlayerApp
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# announce cmake variables to Cpp side
target_compile_definitions(MediaPlayerApp PRIVATE
    MPRIS_IDENTITY="${CM_MPRIS_IDENTITY}"
)


qt_generate_deploy_qml_app_script(
    TARGET MediaPlayerApp
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
