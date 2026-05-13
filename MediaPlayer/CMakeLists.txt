# --- Desktop Specific ---
if(NOT ANDROID)
    qt_add_library(MediaPlayer STATIC) # Only static for desktop
    set_source_files_properties(Images.qml
        PROPERTIES
            QT_QML_SINGLETON_TYPE true
    )
endif()

qt_add_qml_module(MediaPlayer
    URI "MediaPlayer"
    VERSION "1.0"
    QML_FILES
        "Main.qml"
        "Images.qml"
        "MetadataInfo.qml"
        "PlayerMenuBar.qml"
        "TracksInfo.qml"
        "TracksOptions.qml"
        "PlaylistInfo.qml"
        "UrlPopup.qml"
        "SettingsInfo.qml"
        "ThemeInfo.qml"
        "ErrorPopup.qml"
        "TouchMenu.qml"
        "SettingsPage.qml"
        SubtitleUtils.js
        scripts.js

    RESOURCES
        "icons/Shadow.png"
        "icons/Shadow@2x.png"
        "icons/Default_CoverArt.svg"
        "icons/Movie_Active.svg"
        "icons/Movie_Icon_Dark.svg"
        "icons/Movie_Icon.svg"
        "icons/Music_Active.svg"
        "icons/Music_Icon_Dark.svg"
        "icons/Music_Icon.svg"
        "icons/Warning_Icon.svg"
        "icons/Rate_Icon.svg"
        "icons/Rate_Icon_Dark.svg"
        "icons/bluetooth.png"
        "icons/wifi.png"
        "icons/lock.svg"
        "icons/unlock.svg"
        "icons/linux.svg"
        "icons/apple.svg"
        "icons/windows.svg"
        "icons/android.svg"


        # country flags
        "icons/sa.png"
        "icons/uk.png"
        "icons/fr.png"
        "icons/de.png"
        "icons/tr.png"
        "icons/es.png"
)


target_link_libraries(MediaPlayer
    PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::Quick
)
