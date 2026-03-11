// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Window
import QtQuick.Controls.Fusion
import QtMultimedia
import QtQuick.Effects
import MediaControls
import Config
import io.qt.filenameprovider

import CustomMedia 1.0
import SubtitleFinder 1.0
import "SubtitleUtils.js" as Sub
import "scripts.js" as Scripts

import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 1900//1200
    height: 780
    minimumHeight: 460
    minimumWidth: 640
    visible: true
    color: Config.mainColor
    title: qsTr("moveV Player")
    required property url source
    required property list<string> nameFilters
    required property int selectedNameFilter


    property alias currentFile: playlistInfo.currentIndex
    property alias playlistLooped: playbackControl.isPlaylistLooped
    property alias metadataInfo: settingsInfo.metadataInfo
    property alias tracksInfo: settingsInfo.tracksInfo


    property string currentSubtitle: "" //temp
    SubtitleExtractor
    {
        id: extractor
    }
    SubtitleFinder {
        id: subtitleFinder
    }


    property bool isMuted: false
    property real rotationAngle:  0 // 0 = normal, 90 = rotated right, 180 = upside down, 270 = rotated left
    property string selectedMediaFilePath;
    property bool autoLoadSubtitles: true
    property int subtitlesTimerInterval: 200


    //hold to speedup
    property real speedHold:2
    property bool spedupByHold: false //a flag to set when user hold mouse click to speedup


    //SNS settings
    property real secBeforeSpeedup: 1; //x Seconds before subtitle make pace normal. (FOR SNS) (for those subtitles are not shown/matched when actor speak)


    //subtitles properties
    QtObject {
        id: subtitle1Data
        property bool wordByWordMode:false;
        property int subtitleOffsetMs: 0
        property bool subtitleStatus: true;

        //subtitle texts and variables
        property var subtitle; //whole subtitle file text loaded here
        property int subIndex: 0 //in listing combobox
        property string currentSubtitle:""; //to hold that current chunk of subtitle for that time of media
        property string preSubtitle:""; //for SNS (speedup and stop) to find upcoming subtitle (to make subtitle's speed to normal when hit before-time offset)
        property string subfilePath: "";//to hold selected subtitle file path

        //subtitle styling
        property string subTextColor: "yellow"
        property string subTextOfsetColor: "red"
        property string subBackColor:"black"
        property real subBgOpacity: 0.5
        property int subFontSize: 50
        property int subposy: 50

        //word by word feature
        property var wordList: []
        property int wordIndex: 0
        property string lastSubtitle: ""
        property int subtitleStart: 0
        property int subtitleEnd: 0
        property int subtitleDuration: 1
        property int wordByWordChunks: 1
    }

    QtObject {
        id: subtitle2Data
        property bool wordByWordMode:false;
        property int subtitleOffsetMs: 0
        property bool subtitleStatus: true;

        //subtitle texts and variables
        property var subtitle; //whole subtitle file text loaded here
        property int subIndex: 0 //in listing combobox
        property string currentSubtitle:""; //to hold that current chunk of subtitle for that time of media
        property string preSubtitle:""; //for SNS (speedup and stop) to find upcoming subtitle (to make subtitle's speed to normal when hit before-time offset)
        property string subfilePath: "";//to hold selected subtitle file path

        //subtitle styling
        property string subTextColor: "yellow"
        property string subTextOfsetColor: "red"
        property string subBackColor:"black"
        property real subBgOpacity: 0.5
        property int subFontSize: 50
        property int subposy: 50

        //word by word feature
        property var wordList: []
        property int wordIndex: 0
        property string lastSubtitle: ""
        property int subtitleStart: 0
        property int subtitleEnd: 0
        property int subtitleDuration: 1
        property int wordByWordChunks: 1
    }


    function playMedia() {
        mediaPlayer.source = playlistInfo.getSource()
        mediaPlayer.play()
    }

    function closeOverlays() {
        settingsInfo.visible = false
        playlistInfo.visible = false
    }

    function showOverlay(overlay) {
        closeOverlays()
        overlay.visible = true
    }

    function openFile(path) {
        ++currentFile
        playlistInfo.addFile(currentFile, path)
        mediaPlayer.source = path
        mediaPlayer.play()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {

        }
        onClicked: root.closeOverlays()
    }

    ErrorPopup {
        id: errorPopup
    }



    MediaDevices {
        id: mediaDevices

        // onAudioOutputsChanged: {
        //     settingsInfo.settingsPage.audioOutputDevicesChanged(defaultAudioOutput)
        // }
    }

    MediaPlayer {
        id: mediaPlayer

        playbackRate: playbackControl.playbackRate
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            id: audio
            volume: playbackControl.volume
        }
        // source: new URL("https://download.qt.io/learning/videos/media-player-example/Qt_LogoMergeEffect.mp4")

        function updateMetadata() {
            root.metadataInfo.clear()
            root.metadataInfo.read(mediaPlayer.metaData)
        }

        onMetaDataChanged: updateMetadata()
        onActiveTracksChanged: updateMetadata()
        onErrorOccurred: {
            errorPopup.errorMsg = mediaPlayer.errorString
            errorPopup.open()
        }
        onTracksChanged: {
            settingsInfo.tracksInfo.selectedAudioTrack = mediaPlayer.activeAudioTrack
            settingsInfo.tracksInfo.selectedVideoTrack = mediaPlayer.activeVideoTrack
            settingsInfo.tracksInfo.selectedSubtitleTrack = mediaPlayer.activeSubtitleTrack
            updateMetadata()


            mediaCurrentFileLabel.text = FileNameProvider.getFileName(mediaPlayer.source)




            //encounter embedded subtitles
            subtitleModel.clear()
            subtitle1Data.subtitle="";
            subtitle2Data.subtitle="";


            for (let i = 0; i < subtitleTracks.length; ++i)
            {
                let lang = subtitleTracks[i].stringValue(6) // 6 = language key
                subtitleModel.append({"text": lang ? lang : "Embedded Subtitle " + i, "index": i, "path": "embedded"})
            }

            //encounter subtitle files
            let matches = subtitleFinder.findMatchingSubtitles(mediaPlayer.source)
            console.log("matches.length=",matches.length, "matches",matches )
            if (matches.length > 0) {
                console.log("Possible subtitles found:")
                for (let i = 0; i < matches.length; ++i)
                {
                    console.log("sub: " + matches[i])
                    subtitleModel.append({"text":  matches[(i)] , "index": (i+1), "path": matches[i]})
                }


            } else {
                console.log("No matching subtitles found.")
            }


            if(autoLoadSubtitles)
            {
                var path=subtitleModel.get(0).path
                loadSubtitle(path==="embedded"?true:false,path,false,0)


                path=subtitleModel.get(1).path
                loadSubtitle(path==="embedded"?true:false,path,true,1)

            }


            for (let i = 0; i < audioTracks.length; ++i)
            {
                // let lang = audioTracks[i].stringValue(6) // 6 = language key
                console.log("audiotracks:",audioTracks)
                // subtitleModel.append({"text": lang ? lang : "Embedded Subtitle " + i, "index": i, "path": "embedded"})
            }


        }


        onMediaStatusChanged: {

            loadingMedia(mediaStatus)

            if ((MediaPlayer.EndOfMedia === mediaStatus && mediaPlayer.loops !== MediaPlayer.Infinite) &&
                    ((root.currentFile < playlistInfo.mediaCount - 1) || playlistInfo.isShuffled)) {
                if (!playlistInfo.isShuffled) {
                    ++root.currentFile
                }
                root.playMedia()
            } else if (MediaPlayer.EndOfMedia === mediaStatus && root.playlistLooped && playlistInfo.mediaCount) {
                root.currentFile = 0
                root.playMedia()
            }

        }

        function loadingMedia(mediaStatus)
        {
            if(mediaStatus=== MediaPlayer.LoadingMedia)
                backend.changeCursor("wait")
            else if(mediaStatus===MediaPlayer.LoadedMedia)
                backend.changeCursor()
        }

        function seekForward(val=15)
        {
            mediaPlayer.position = Math.min(mediaPlayer.position + val*1000, mediaPlayer.duration);
        }
        function seekBackward(val=15)
        {
            mediaPlayer.position = Math.max(mediaPlayer.position - val*1000, 0);
        }

        function doFullscreen()
        {
            if (mediaPlayer.hasVideo) {
                videoOutput.fullScreen ?  root.showNormal() : root.showFullScreen()
                videoOutput.fullScreen = !videoOutput.fullScreen
            }
        }
    }


    VideoOutput {
        id: videoOutput

        anchors.top: fullScreen || Config.isMobileTarget ? parent.top : menuBar.bottom
        anchors.bottom: fullScreen ? parent.bottom : playbackControl.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: fullScreen ? 0 : 20
        anchors.rightMargin: fullScreen ? 0 : 20
        visible: mediaPlayer.hasVideo

        property bool fullScreen: false


        TapHandler {
            onDoubleTapped: {
                if (parent.fullScreen) {
                    root.showNormal()
                } else {
                    root.showFullScreen()
                }
                parent.fullScreen = !parent.fullScreen
            }
            onTapped: {
                root.closeOverlays()
            }
        }
    }

    Image {
        id: defaultCoverArt
        anchors.horizontalCenter: videoOutput.horizontalCenter
        anchors.verticalCenter: videoOutput.verticalCenter
        visible: !videoOutput.visible && mediaPlayer.hasAudio
        source: Images.iconSource("Default_CoverArt", false)
    }





    //subtitle list
    ListModel { id: subtitleModel }


    Rectangle {
        id: background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: seeker.opacity ? seeker.top : playbackControl.top
        color: Config.mainColor
        opacity: videoOutput.fullScreen ? 0.75 : 0.5
    }

    Image {
        id: shadow
        source: `icons/Shadow.png`
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }


    Rectangle
    {
        id:brightnessOverlay
        anchors.fill: parent
        color:"black"
        opacity: videoArea.brightness
        WheelHandler {
            onWheel: function(event) {
                if (event.angleDelta.y !== 0) {
                    let posX = event.x;
                    let halfWidth = videoArea.width / 2;

                    if (posX > halfWidth) {
                        // Right side → control volume
                        if (event.angleDelta.y > 0) {
                            playbackControl.volume = Math.min(playbackControl.volume + 0.1, 1.0);
                        } else {
                            playbackControl.volume = Math.max(playbackControl.volume - 0.1, 0.0);
                        }
                    } else {
                        // Left side → control brightness
                        if (event.angleDelta.y > 0) {
                            videoArea.brightness = Math.min(videoArea.brightness + 0.1, 1.0);
                        } else {
                            videoArea.brightness = Math.max(videoArea.brightness - 0.1, 0.0);
                        }
                    }
                }
            }
        }

        Keys.onPressed: (event) =>
                        {
                            keyboardButtonsHandler(event)
                        }

        MouseArea {
            hoverEnabled: true  // enables movement detection even without pressing

            anchors.fill: parent
            preventStealing: false
            propagateComposedEvents: true
            onDoubleClicked:
            {
                mediaPlayer.doFullscreen()
            }
            onPositionChanged: (mouse) =>
                               {
                                   showControlsByHover()
                               }
            onClicked:
            {
                root.closeOverlays()
            }

            onPressAndHold: {
                spedupByHold=true
            }
            onReleased: {
                spedupByHold=false
            }
        }

        Rectangle {
            id: videoArea
            anchors.fill: parent
            color: "black"

            // Properties for volume and brightness
            property real volume:0.5
            property real brightness:0.5
            property real maxDy: 300
            property real minDy: -300


            // --- RIGHT SIDE: Volume Control ---
            Rectangle {
                id: volumeControlArea
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: parent.width / 8
                color: "transparent"

                property real cumulativeDy: 0
                property real startY: 0

                MouseArea {
                    anchors.fill: parent
                    drag.target: null
                    onPressed: (mouse) => {
                                   volumeControlArea.cumulativeDy = 0
                                   volumeControlArea.startY = mouse.y
                               }
                    onPositionChanged: (mouse) => {
                                           let delta = volumeControlArea.startY - mouse.y
                                           volumeControlArea.cumulativeDy += delta
                                           volumeControlArea.startY = mouse.y

                                           if (volumeControlArea.cumulativeDy > videoArea.maxDy)
                                           volumeControlArea.cumulativeDy = videoArea.maxDy
                                           if (volumeControlArea.cumulativeDy < videoArea.minDy)
                                           volumeControlArea.cumulativeDy = videoArea.minDy

                                           videoArea.volume = (volumeControlArea.cumulativeDy - videoArea.minDy) / (videoArea.maxDy - videoArea.minDy)
                                           videoArea.volume = Math.min(Math.max(videoArea.volume, 0), 1)
                                           // Volume
                                           volumeIndicator.visible = true

                                           // console.log("Volume:", videoArea.volume.toFixed(2))
                                       }
                }
            }

            // --- LEFT SIDE: Brightness Control ---
            Rectangle {
                id: brightnessControlArea
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width / 8
                color: "transparent"

                property real cumulativeDy: 0
                property real startY: 0

                MouseArea {
                    anchors.fill: parent
                    drag.target: null
                    onPressed: (mouse) => {
                                   brightnessControlArea.cumulativeDy = 0
                                   brightnessControlArea.startY = mouse.y
                               }
                    onPositionChanged: (mouse) => {
                                           let delta = brightnessControlArea.startY - mouse.y
                                           brightnessControlArea.cumulativeDy += delta
                                           brightnessControlArea.startY = mouse.y

                                           if (brightnessControlArea.cumulativeDy > videoArea.maxDy)
                                           brightnessControlArea.cumulativeDy = videoArea.maxDy
                                           if (brightnessControlArea.cumulativeDy < videoArea.minDy)
                                           brightnessControlArea.cumulativeDy = videoArea.minDy

                                           videoArea.brightness = (brightnessControlArea.cumulativeDy - videoArea.minDy) / (videoArea.maxDy - videoArea.minDy)
                                           videoArea.brightness = Math.min(Math.max(videoArea.brightness, 0), 1)
                                           brightnessIndicator.visible = true


                                           // console.log("Brightness:", videoArea.brightness.toFixed(2))
                                       }
                }
            }


        }



    }



    MultiEffect {
        source: settingsInfo
        anchors.fill: settingsInfo
        shadowEnabled: settingsInfo.visible || playlistInfo.visible
        visible: settingsInfo.visible || playlistInfo.visible
    }

    PlaylistInfo {
        id: playlistInfo

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: seeker.opacity ? seeker.top : playbackControl.top
        anchors.topMargin: 10
        anchors.rightMargin: 5

        visible: false
        isShuffled: playbackControl.isPlaylistShuffled

        onVisibleChanged: controlsHideTimer.start()

        onPlaylistUpdated: {
            if (mediaPlayer.playbackState == MediaPlayer.StoppedState && root.currentFile < playlistInfo.mediaCount - 1) {
                ++root.currentFile
                root.playMedia()
            }
        }

        onPlaySelectedIndex:
        {
            root.playMedia();
        }

        onCurrentFileRemoved: {
            mediaPlayer.stop()
            if (root.currentFile < playlistInfo.mediaCount - 1) {
                root.playMedia()
            } else if (playlistInfo.mediaCount) {
                --root.currentFile
                root.playMedia()
            }
        }
    }

    SettingsInfo {
        id: settingsInfo

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: seeker.opacity ? seeker.top : playbackControl.top
        anchors.topMargin: 10
        anchors.rightMargin: 5

        mediaPlayer: mediaPlayer
        selectedAudioTrack: mediaPlayer.activeAudioTrack
        selectedVideoTrack: mediaPlayer.activeVideoTrack
        selectedSubtitleTrack: mediaPlayer.activeSubtitleTrack
        visible: false

        onVisibleChanged: controlsHideTimer.start()

    }

    ParallelAnimation {
        id: hideControls

        NumberAnimation {
            targets: [playbackControl, seeker, background, shadow, topControls]
            property: "opacity"
            to: 0
            duration: 1000
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: playbackControl
            property: "anchors.bottomMargin"
            to: -playbackControl.height - seeker.height
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    ParallelAnimation {
        id: showControls

        NumberAnimation {
            targets: [playbackControl, seeker, shadow,topControls]
            property: "opacity"
            to: 1
            duration: 1000
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: background
            property: "opacity"
            to: 0.5
            duration: 1000
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: playbackControl
            property: "anchors.bottomMargin"
            to: 0
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }


    // Subtitle overlay
    // Update subtitle every ..ms
    Timer {
        interval: subtitlesTimerInterval
        running: true
        repeat: true



        onTriggered:
        {
            if(mediaPlayer.playing)
            {
                subtitle1Data.currentSubtitle=""
                subtitle2Data.currentSubtitle=""

                if(subtitle1Data.subtitleStatus)
                {
                    subtitle1Data.currentSubtitle = Sub.getSubtitleForTime(subtitle1Data.subtitle, mediaPlayer.position + subtitle1Data.subtitleOffsetMs*1000)
                }

                if(subtitle2Data.subtitleStatus)
                {
                    subtitle2Data.currentSubtitle = Sub.getSubtitleForTime(subtitle2Data.subtitle, mediaPlayer.position + subtitle2Data.subtitleOffsetMs*1000)
                }


                subtitle1Data.currentSubtitle=checkAndClean(subtitle1Data.currentSubtitle)
                subtitle2Data.currentSubtitle=checkAndClean(subtitle2Data.currentSubtitle)



                // WORD BY WORD MODE
                if (subtitle1Data.wordByWordMode)
                    subtitleText1.text = Sub.giveWordByWordSubtitle(subtitle1Data,mediaPlayer.position);
                else
                    subtitleText1.text =subtitle1Data.currentSubtitle

                if (subtitle2Data.wordByWordMode)
                    subtitleText2.text = Sub.giveWordByWordSubtitle(subtitle2Data,mediaPlayer.position);
                else
                    subtitleText2.text =subtitle2Data.currentSubtitle





                if(spedupByHold)//user held mouse click to spedup
                {
                    mediaPlayer.playbackRate=speedHold
                    speedingLabel.visible=true
                    speedingLabel.text="hold speed "+speedHold + "x"
                }
                else if(playbackControl.snsStatus)
                {
                    //speed up when text is empty.
                    if(subtitle1Data.currentSubtitle==="" && subtitle2Data.currentSubtitle==="")
                    {

                        subtitle1Data.preSubtitle=""
                        subtitle2Data.preSubtitle=""
                        //read coming up subtitle for seconds before speedup

                        if(subtitle1Data.subtitleStatus)
                        {
                            //get presubtitle
                            subtitle1Data.preSubtitle = Sub.getSubtitleForTime(subtitle1Data.subtitle, mediaPlayer.position + subtitle1Data.subtitleOffsetMs*1000 + playbackControl.secBeforeSpeedup*1000)

                            //clean presubtitle
                            subtitle1Data.preSubtitle=checkAndClean(subtitle1Data.preSubtitle)
                        }
                        if(subtitle2Data.subtitleStatus)
                        {
                            //get presubtitle
                            subtitle2Data.preSubtitle = Sub.getSubtitleForTime(subtitle2Data.subtitle, mediaPlayer.position + subtitle2Data.subtitleOffsetMs*1000 + playbackControl.secBeforeSpeedup*1000)

                            //clean presubtitle
                            subtitle2Data.preSubtitle=checkAndClean(subtitle2Data.preSubtitle)
                        }


                        //check for seconds before speedup to avoid speedup
                        if(subtitle1Data.preSubtitle==="" && subtitle2Data.preSubtitle==="")
                        {
                            mediaPlayer.playbackRate=playbackControl.snsSpeed;
                            speedingLabel.visible=true
                            speedingLabel.text="sns speed "+playbackControl.snsSpeed + "x" + ", before " + playbackControl.secBeforeSpeedup +"s"
                        }
                        else
                        {
                            // console.log("subtitle is not empty for speedup. subtitle1Data.preSubtitle=",subtitle1Data.preSubtitle,"subtitle2Data.preSubtitle=",subtitle2Data.preSubtitle)
                            mediaPlayer.playbackRate=playbackControl.playbackRate
                            speedingLabel.visible=false
                            speedingLabel.text=""
                        }
                    }
                    else
                    {
                        mediaPlayer.playbackRate=playbackControl.playbackRate
                        speedingLabel.visible=false
                        speedingLabel.text=""
                    }

                }
                else // set playbackrate value
                {
                    mediaPlayer.playbackRate=playbackControl.playbackRate
                    speedingLabel.visible=false
                    speedingLabel.text=""
                }
            }
        }
    }

    Rectangle
    {
        width: subtitleText1.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText1.implicitWidth
        height:subtitleText1.height
        color:subtitle1Data.subBackColor
        opacity: subtitle1Data.subBgOpacity-brightnessOverlay.opacity/2
        visible: subtitle1Data.subtitleStatus
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:subtitle1Data.subposy

        property int parentWidth: parent ? parent.width : 0
        property int parentHeight: parent ? parent.height : 0
        MouseArea {
            id: dragArea

            onEntered: backend.changeCursor("verReposition")
            onExited: backend.changeCursor()

            anchors.fill: parent
            drag.target: parent
            onReleased: {
                // Ensure rectangle stays inside parent bounds
                if (parent.x < 0)
                    parent.x = 0
                if (parent.y < 0)
                    parent.y = 0
                if (parent.x + parent.width > parent.parentWidth)
                    parent.x = parent.parentWidth - parent.width
                if (parent.y + parent.height > parent.parentHeight)
                    parent.y = parent.parentHeight - parent.height

                subtitle1Data.subposy=parent.y
            }
        }
        Label {
            id: subtitleText1
            width: parent.width
            height: implicitHeight
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            // horizontalAlignment: Text.AlignRight

            color: subtitle1Data.subTextColor
            style: Text.Outline
            styleColor: subtitle1Data.subTextOfsetColor
            font.pixelSize: subtitle1Data.subFontSize
        }
    }
    Rectangle
    {
        width: subtitleText2.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText2.implicitWidth
        height:subtitleText2.height
        color:subtitle2Data.subBackColor
        opacity: subtitle2Data.subBgOpacity-brightnessOverlay.opacity/2
        visible: subtitle2Data.subtitleStatus
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:subtitle2Data.subposy


        property int parentWidth: parent ? parent.width : 0
        property int parentHeight: parent ? parent.height : 0
        MouseArea
        {
            anchors.fill: parent
            drag.target: parent
            onEntered: backend.changeCursor("verReposition")
            onExited: backend.changeCursor()
            onReleased: {
                // Ensure rectangle stays inside parent bounds
                if (parent.x < 0)
                    parent.x = 0
                if (parent.y < 0)
                    parent.y = 0
                if (parent.x + parent.width > parent.parentWidth)
                    parent.x = parent.parentWidth - parent.width
                if (parent.y + parent.height > parent.parentHeight)
                    parent.y = parent.parentHeight - parent.height


                subtitle2Data.subposy=parent.y
            }
        }
        Label {
            id: subtitleText2
            // width: implicitWidth>parent.width/2? parent.width/2 : implicitWidth
            width: parent.width
            height: implicitHeight
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            // horizontalAlignment: Text.AlignRight

            color: subtitle2Data.subTextColor
            style: Text.Outline
            styleColor: subtitle2Data.subTextOfsetColor
            font.pixelSize: subtitle2Data.subFontSize
        }
    }



    // Controls
    Rectangle
    {
        id:controls
        width:parent.width
        height:implicitHeight
        anchors.bottom:parent.bottom


        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            // }
            /*Dial {
                id: rotationDial
                // anchors.bottom: parent.bottom
                // anchors.horizontalCenter: parent.horizontalCenter
                from: 0
                to: 360
                value: rotationAngle
                stepSize: 1
                onValueChanged: rotationAngle = value
                width: 70
                height: 70
            }*/

        }

        Timer {
            id: controlsHideTimer
            interval: 3000   // milliseconds to hide after last change
            repeat: false
            running: true
            onTriggered:
            {
                if(!playbackControl.isMouseOnControl && !settingsInfo.visible && !playlistInfo.visible
                        && !seeker.isMouseOnControl)
                {
                    controls.visible = false
                    hideControls.start()
                    backend.changeCursor("blank");
                }

            }
        }



        // --- Volume indicator (right) ---
        Rectangle {
            id: volumeIndicator
            width: 40
            height: 200
            anchors.right: parent.right
            anchors.rightMargin: 10
            // anchors.verticalCenter: parent.verticalCenter
            anchors.bottom:parent.top
            anchors.bottomMargin: 100
            color: "#888"
            radius: 8

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: volumeIndicator.height * playbackControl.volume
                color: "#0f0"
            }
        }

        // --- Brightness indicator (left) ---
        Rectangle {
            id: brightnessIndicator
            width: 40
            height: 200
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom:parent.top
            anchors.bottomMargin: 100
            color: "#888"
            radius: 8

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: brightnessIndicator.height * videoArea.brightness
                color: "#ff0"
            }

        }

    }
    Label {
        text: qsTr("Click <font color=\"#41CD52\">here</font> to open media file.")
        font.pixelSize: 24
        color: Config.secondaryColor
        anchors.centerIn: parent
        visible: !errorPopup.visible && !videoOutput.visible && !defaultCoverArt.visible

        TapHandler {
            onTapped: menuBar.openFileMenu.open()
        }
    }

    PlaybackSeekControl {
        id: seeker
        anchors.left: videoOutput.left
        anchors.right: videoOutput.right
        anchors.bottom: playbackControl.top
        mediaPlayer: mediaPlayer

        fullScreenButton.onClicked: {
            if (mediaPlayer.hasVideo) {
                videoOutput.fullScreen ?  root.showNormal() : root.showFullScreen()
                videoOutput.fullScreen = !videoOutput.fullScreen
            }
        }

        settingsButton.onClicked: !settingsInfo.visible ? root.showOverlay(settingsInfo) : root.closeOverlays()
    }

    PlaybackControl {
        id: playbackControl

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        mediaPlayer: mediaPlayer
        isPlaylistVisible: playlistInfo.visible

        onPlayNextFile: {
            if (playlistInfo.mediaCount) {
                if (!playlistInfo.isShuffled){
                    ++root.currentFile
                    if (root.currentFile > playlistInfo.mediaCount - 1 && root.playlistLooped) {
                        root.currentFile = 0
                    } else if (root.currentFile > playlistInfo.mediaCount - 1 && !root.playlistLooped) {
                        --root.currentFile
                        return
                    }
                }
                root.playMedia()
            }
        }


        onPlayPreviousFile: {
            if (playlistInfo.mediaCount) {
                if (!playlistInfo.isShuffled){
                    --root.currentFile
                    if (root.currentFile < 0 && isPlaylistLooped) {
                        root.currentFile = playlistInfo.mediaCount - 1
                    } else if (root.currentFile < 0 && !root.playlistLooped) {
                        ++root.currentFile
                        return
                    }
                }
                root.playMedia()
            }
        }

        playlistButton.onClicked: !playlistInfo.visible ? root.showOverlay(playlistInfo) : root.closeOverlays()
        menuButton.onClicked: menuPopup.open()
    }



    Row
    {
        id:topControls
        height:implicitHeight
        width: root.width

        Rectangle
        {
            width:150
            height:150
            color:"transparent"
            TouchMenu {
                id: menuPopup
                width: 100//root.width - 64
                // x: (parent.width - width) / 2
                // y: parent.height - height - 32
                openFileMenuItem.onClicked: {
                    menuPopup.close()
                    menuBar.openFileMenu.open()
                }

                openUrlMenuItem.onClicked: {
                    menuPopup.close()
                    menuBar.openUrlPopup.open()
                }
            }
            PlayerMenuBar {
                id: menuBar

                anchors.left: parent.left
                anchors.right: parent.right

                // visible: !videoOutput.fullScreen

                onFileOpened: (path) => openFile(path)

                // nameFilters : root.nameFilters
                // nameFilters: ["All Files (*)"]
                nameFilters:
                    [
                    "All Supported Files (*.gif *.mp4 *.avi *.mkv *.mov *.webm)",
                    "GIF Files (*.gif)",
                    "Video Files (*.mp4 *.avi *.mkv *.mov *.webm)",
                    "All Files (*)"
                ]
                selectedNameFilter : root.selectedNameFilter
            }
        }
        Rectangle
        {
            width:200
            height:50
            color:"transparent"
            Label
            {
                id:mediaCurrentFileLabel
                text:""
                color:"yellow"
                font.pixelSize: 35
            }

        }


    }


    function checkAndClean(textPara)
    {
        //ignore subtitles which contain website domains
        if(playbackControl.removeDomainsStatus)
        {
            if(Scripts.containsDomain(textPara))
                textPara=""
        }


        //remove html tags
        if(playbackControl.removeHTMLStatus)
        {
            textPara = Scripts.stripHtmlClean(textPara)
        }


        //clean subtitle
        if(playbackControl.cleanSubtitleStatus)
        {
            textPara = Scripts.cleanSubtitleText(textPara)
        }


        //remove more info like (hello) or [this is building] or <dwadwa> or «something» ...
        if(playbackControl.removeExtraInfo)
        {
            textPara= Scripts.removeExtraInfo(textPara)
        }

        return textPara;
    }




    function playVideo()
    {
        mediaPlayer.play()
    }
    function pauseVideo()
    {
        mediaPlayer.pause()
    }
    function togglePlayPause() {

        if (mediaPlayer.playbackState === MediaPlayer.PlayingState)
            mediaPlayer.pause()
        else
            mediaPlayer.play()
    }
    function stopVideo() {
        mediaPlayer.stop()
    }
    function nextVideo()
    {
        playbackControl.playNextFile()
    }

    function previousVideo()
    {
        playbackControl.playPreviousFile()
    }

    function seekForth()
    {
        mediaPlayer.position = Math.min(mediaPlayer.position + 15000, mediaPlayer.duration);
    }
    function seekBack()
    {
        mediaPlayer.position = Math.max(mediaPlayer.position - 15000, 0);
    }

    function volUp(val=0.10)
    {
        if(playbackControl.volume<100)
            playbackControl.volume +=val
    }

    function volDown(val=0.10)
    {
        if(playbackControl.volume>0)
            playbackControl.volume -=val
    }

    function speedUp(val=0.5)
    {
        if(playbackControl.playbackRate<100)
            playbackControl.playbackRate +=val
    }

    function speedDown(val=0.5)
    {
        if(playbackControl.playbackRate>0)
            playbackControl.playbackRate -= val
    }

    function brightnessUp(val=0.10)
    {
        if(videoArea.brightness<100)
            videoArea.brightness += val
    }

    function brightnessDown(val=0.10)
    {
        if(videoArea.brightness>0)
            videoArea.brightness -= val
    }

    function muteUnmute()
    {
        isMuted = !isMuted
    }

    function showControlsByHover()
    {
        controls.visible=true
        controlsHideTimer.running=true
        brightnessOverlay.focus=true
        backend.changeCursor()
        showControls.start()
    }

    function loadSubtitle(embedded, subPath,subtitleNo, subIndex)
    {
        if(embedded)
        {
            currentSubtitle = extractor.extractSubtitle(mediaPlayer.source, subIndex)
            // console.log("extract subtitle from video=", currentSubtitle)
        }
        else
        {
            if (subPath.startsWith("file://"))
                subPath = subPath.slice(7)

            currentSubtitle = extractor.loadSrtFile(subPath)
            // console.log("loaded subtitle from video=", currentSubtitle)

        }

        if(subtitleNo)
        {
            subtitle1Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                subtitle1Data.subIndex=subIndex
        }

        else
        {
            subtitle2Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                subtitle2Data.subIndex=subIndex
        }

    }

    function keyboardButtonsHandler(event)
    {
        if(event.key === Qt.Key_Up  && (event.modifiers & Qt.ShiftModifier))
        {
            brightnessUp()
        }

        else if(event.key === Qt.Key_Down  && (event.modifiers & Qt.ShiftModifier))
        {
            brightnessDown()
        }

        else if(event.key === Qt.Key_Up  && (event.modifiers & Qt.ControlModifier))
        {
            speedUp()
        }

        else if(event.key === Qt.Key_Down  && (event.modifiers & Qt.ControlModifier))
        {
            speedDown()
        }


        else
            switch(event.key)
            {




            case Qt.Key_VolumeMute:
            case Qt.Key_M:
            {
                muteUnmute()
            }break;

            case Qt.Key_MediaPlay:
            case Qt.Key_MediaPause:
            case Qt.Key_MediaTogglePlayPause:
            case Qt.Key_Space:
            {
                if(!mediaPlayer.playing)
                    playVideo()
                else
                    pauseVideo()
            }break;

            case Qt.Key_Right:
            {
                mediaPlayer.seekForward()
            }break;
            case Qt.Key_Left:
            {
                mediaPlayer.seekBackward()
            }break;

            case Qt.Key_VolumeUp:
            case Qt.Key_Up:
            {
                volUp()
            }break;

            case Qt.Key_VolumeDown:
            case Qt.Key_Down:
            {
                volDown()
            }break;
            case Qt.Key_F:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            {
                mediaPlayer.doFullscreen()
            }break;
            }

        showControlsByHover()
    }

    Label
    {
        id:speedingLabel
        text:playbackControl.snsSpeed
        visible: false
        anchors.top:parent.top
        anchors.left: parent.left
        color: "yellow"
        font.pixelSize: 15
        z:0
    }




    Component.onCompleted: {
        if (source.toString().length > 0)
            openFile(source)
        else
            mediaPlayer.play()


        //set media devicesfor config
        Config.mediaDevicesPtr=mediaDevices
        Config.mediaPlayerPtr=mediaPlayer

        //alias data to config
        Config.subtitle1DataPtr= subtitle1Data
        Config.subtitle2DataPtr= subtitle2Data


        backend.setupCustomCursor(Config.customCursorIconPath,20,20,10,10);

        //load customCursrorStatus
        Config.customCursorStatus = backend.customCursorStatus()
    }
}
