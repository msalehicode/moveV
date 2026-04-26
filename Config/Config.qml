// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma Singleton
import QtQuick


import QtMultimedia
QtObject {
    enum Theme {
        Light,
        Dark
    }


    //supported formats for FileDialogs
    readonly property list<string> nameFilters:
    [
        "Video Files (*.mp4 *.avi *.mkv *.mov *.webm)",
        "Music Files (*.mp3 *.wav *.aac *.aiff)",
        "Subtitle Files (*.srt *.sub)",
        "GIF Files (*.gif)",
        "All Supported Files (*.gif *.mp4 *.avi *.mkv *.mov *.webm *.mp3 *.wav *.aac *.aiff *.sub *.srt)",
        "All Files (*)"
    ]
    property int selectedNameFilter: 0



    property int activeTheme : settings.value["App/theme"]==="dark" ? Config.Theme.Dark : Config.Theme.Light
    readonly property string defaultAudioLabel: "Default"
    property MediaDevices mediaDevicesPtr;
    property MediaPlayer mediaPlayerPtr;
    property bool autoSwitchAudioDeviceToDefault:true;

    readonly property bool isMobileTarget : Qt.platform.os === "android" || Qt.platform.os === "ios"
    readonly property color mainColor : activeTheme ? "#09102B" : "#FFFFFF"
    readonly property color secondaryColor : activeTheme ? "#FFFFFF" : "#09102B"
    readonly property color highlightColor : "#41CD52"
    property int currentActiveAudioTrack:0

    property string customCursorIconPath: "file:///home/mrx/head.png"

    function iconName(fileName, addSuffix = true) {
        return `${fileName}${activeTheme === Config.Theme.Dark && addSuffix ? "_Dark.svg" : ".svg"}`
    }
    function iconNamePng(fileName, addSuffix = true) {
        return `${fileName}${activeTheme === Config.Theme.Dark && addSuffix ? "_Dark.png" : ".png"}`
    }
}
