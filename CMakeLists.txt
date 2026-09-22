cmake_minimum_required(VERSION 3.16)

project(MediaPlayerApp LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CM_MPRIS_IDENTITY "MyMediaPlayer")
set(APP_TitleName "MOVEV")
set(APP_CURRENT_VERSION "0.0.1")

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2 Svg Multimedia Bluetooth DBus WebEngineQuick)

# ffmpeg FOR LINUX if(UNIX AND NOT APPLE)
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FFMPEG REQUIRED
        libavformat
        libavcodec
        libavutil
    )
endif()


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
    SOURCES logger.h logger.cpp
    SOURCES config.h
    SOURCES getwordtranslate.h getwordtranslate.cpp
)

qt_add_ios_ffmpeg_libraries(MediaPlayerApp)

add_subdirectory(MediaPlayer)
add_subdirectory(MediaControls)
add_subdirectory(Config)
add_subdirectory(BluetoothControl)
add_subdirectory(NetworkControl)
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
    NetworkControl
    MediaPlayer #mediaPlayer library (subDirectory)
    CommandHandler
    Qt6::WebEngineQuick

    ${FFMPEG_LIBRARIES} #ffmpeg for extract subtitle from movie
)

install(TARGETS MediaPlayerApp
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# ffmpeg
if(UNIX AND NOT APPLE)
target_include_directories(MediaPlayerApp PRIVATE
    ${FFMPEG_INCLUDE_DIRS}
)
target_link_directories(MediaPlayerApp PRIVATE
    ${FFMPEG_LIBRARY_DIRS}
)
elseif(WIN32)
    target_include_directories(MediaPlayerApp PRIVATE C:/Libraries/ffmpeg/include)
    target_link_directories(MediaPlayerApp PRIVATE C:/Libraries/ffmpeg/lib)
    target_link_libraries(MediaPlayerApp PRIVATE
        avcodec
        avformat
        avutil
        # swresample
        # swscale
    )
endif()



# announce cmake variables to Cpp side
target_compile_definitions(MediaPlayerApp PRIVATE
    MPRIS_IDENTITY="${CM_MPRIS_IDENTITY}"
)



include(GNUInstallDirs)
install(TARGETS MediaPlayerApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)




# ==========================================================
# Windows deployment
# ==========================================================
if(WIN32)
    get_target_property(WINDEPLOYQT_EXECUTABLE Qt6::windeployqt IMPORTED_LOCATION)

    set(DEPLOY_DIR "${CMAKE_BINARY_DIR}/deploy/${APP_TitleName}-${APP_CURRENT_VERSION}-Windows")

    add_custom_command(TARGET MediaPlayerApp POST_BUILD

        # recreate deployment directory
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEPLOY_DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEPLOY_DIR}"

        # copy executable
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:MediaPlayerApp>"
            "${DEPLOY_DIR}"

        # deploy Qt
        COMMAND
            "${WINDEPLOYQT_EXECUTABLE}"
            --release
             --qmldir "${CMAKE_SOURCE_DIR}/ui"
            "${DEPLOY_DIR}/$<TARGET_FILE_NAME:MediaPlayerApp>"


        # ffmpeg
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "C:/Libraries/ffmpeg/bin/avcodec-62.dll"
            "${DEPLOY_DIR}"

        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "C:/Libraries/ffmpeg/bin/avformat-62.dll"
            "${DEPLOY_DIR}"

        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "C:/Libraries/ffmpeg/bin/avutil-60.dll"
            "${DEPLOY_DIR}"

        COMMENT "Deploying MoveV..."
    )

endif()


qt_generate_deploy_qml_app_script(
    TARGET MediaPlayerApp
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
