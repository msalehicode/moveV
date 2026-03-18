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
import "../MediaControls/"
import QtQuick.Dialogs

ApplicationWindow {

    id: root
    // width: settings.value["App/width"]//1200
    // height: settings.value["App/height"]
    width:1000
    height:800

    onClosing:
    {
        //save busy settings (stored in variable)
        settings.setSetting("Media/brightness",root.brightness)
        settings.setSetting("Media/volume",root.volume)
    }

    // onHeightChanged: settings.setSetting("App/height",height)
    // onWidthChanged: settings.setSetting("App/width",width)
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

    property bool spedupByHold: false //a flag to set when user hold mouse click to speedup
    property string currentSubtitle: "" //temp variable to hold subtitle



    //on load fill these from settings.value then on closing save them.
    property alias volume: playbackControl.volume
    property real brightness;


    //subtitles properties
    QtObject {
        id: subtitle1Data

        //subtitle texts and variables
        property var subtitle; //whole subtitle file text loaded here
        property int subIndex: 0 //in listing combobox
        property string currentSubtitle:""; //to hold that current chunk of subtitle for that time of media
        property string preSubtitle:""; //for SNS (speedup and stop) to find upcoming subtitle (to make subtitle's speed to normal when hit before-time offset)
        property string subfilePath: "";//to hold selected subtitle file path

        //word by word feature
        property var wordList: []
        property int wordIndex: 0
        property string lastSubtitle: ""
        property int subtitleStart: 0
        property int subtitleEnd: 0
        property int subtitleDuration: 1
    }

    QtObject {
        id: subtitle2Data

        //subtitle texts and variables
        property var subtitle; //whole subtitle file text loaded here
        property int subIndex: 0 //in listing combobox
        property string currentSubtitle:""; //to hold that current chunk of subtitle for that time of media
        property string preSubtitle:""; //for SNS (speedup and stop) to find upcoming subtitle (to make subtitle's speed to normal when hit before-time offset)
        property string subfilePath: "";//to hold selected subtitle file path

        //word by word feature
        property var wordList: []
        property int wordIndex: 0
        property string lastSubtitle: ""
        property int subtitleStart: 0
        property int subtitleEnd: 0
        property int subtitleDuration: 1
    }


    MediaDevices {
        id: mediaDevices

        onAudioOutputsChanged: {
            settingsInfo.settingsPage.audioOutputDevicesChanged(defaultAudioOutput)
        }
    }

    MediaPlayer {
        id: mediaPlayer

        playbackRate: settings.value["Media/rate"]
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            id: audio
            volume: root.volume
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
            }
            else
            {
                console.log("No matching subtitles found.")
            }


            //pass subtitleModel to settings combobox
            settingsInfo.settingsPage.foundSubtitles = subtitleModel


            if (Scripts.asBool(settings.value["Media/autoLoadSubtitles"]))
            {
                console.log("autioloadsubtitels..")
                var path=subtitleModel.get(0).path
                loadSubtitle(path==="embedded"?true:false,path,false,0)
                console.log("path=",path)

                path=subtitleModel.get(1).path
                loadSubtitle(path==="embedded"?true:false,path,true,1)
                console.log("path2=",path)
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

        // anchors.top: fullScreen || Config.isMobileTarget ? parent.top : topControls.top
        // anchors.bottom: fullScreen ? parent.bottom : playbackControl.bottom
        // anchors.left: parent.left
        // anchors.right: parent.right
        // anchors.leftMargin: fullScreen ? 0 : 20
        // anchors.rightMargin: fullScreen ? 0 : 20
        anchors.fill: parent
        visible: mediaPlayer.hasVideo

        property bool fullScreen: false


        // TapHandler {
        //     onDoubleTapped: {
        //         if (parent.fullScreen) {
        //             root.showNormal()
        //         } else {
        //             root.showFullScreen()
        //         }
        //         parent.fullScreen = !parent.fullScreen
        //     }
        //     onTapped: {
        //         root.closeOverlays()
        //     }
        // }
    }

    Image {
        id: defaultCoverArt
        anchors.horizontalCenter: videoOutput.horizontalCenter
        anchors.verticalCenter: videoOutput.verticalCenter
        visible: !videoOutput.visible && mediaPlayer.hasAudio
        source: Images.iconSource("Default_CoverArt", false)
    }


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


    //[brightness overlay],   [catch user actions(clicks,wheel,keys)],  [videoArea(drag up/down) to adjust voulme/brightness]
    Rectangle
    {
        id:brightnessOverlay
        anchors.fill: parent
        color:"black"
        opacity: root.brightness
        WheelHandler {
            onWheel: function(event) {
                if (event.angleDelta.y !== 0) {
                    let posX = event.x;
                    let halfWidth = videoArea.width / 2;

                    if (posX > halfWidth) {
                        // Right side → control volume
                        if (event.angleDelta.y > 0) {
                            root.volume = Math.min(root.volume + 0.1, 1.0)
                        } else {
                            root.volume = Math.max(root.volume - 0.1, 0.0)
                        }
                    } else {
                        // Left side → control brightness
                        if (event.angleDelta.y > 0) {
                            root.brightness=Math.min(root.brightness - 0.1, 1.0)
                        } else {
                            root.brightness= Math.max(root.brightness + 0.1, 0.0)
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
                                   showControls.start()
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

        //handle hold and drag up/down to change volume and brightness
        Rectangle {
            id: videoArea
            anchors.fill: parent
            color: "black"

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
                                           // Volume
                                           showControls.start()

                                           let delta = volumeControlArea.startY - mouse.y
                                           volumeControlArea.cumulativeDy += delta
                                           volumeControlArea.startY = mouse.y

                                           if (volumeControlArea.cumulativeDy > videoArea.maxDy)
                                           volumeControlArea.cumulativeDy = videoArea.maxDy
                                           if (volumeControlArea.cumulativeDy < videoArea.minDy)
                                           volumeControlArea.cumulativeDy = videoArea.minDy

                                           root.volume=Math.min(Math.max(
                                                                           ((volumeControlArea.cumulativeDy - videoArea.minDy) / (videoArea.maxDy - videoArea.minDy))
                                                                           , 0), 1)

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
                                           showControls.start()

                                           let delta = brightnessControlArea.startY - mouse.y
                                           brightnessControlArea.cumulativeDy += delta
                                           brightnessControlArea.startY = mouse.y

                                           if (brightnessControlArea.cumulativeDy > videoArea.maxDy)
                                           brightnessControlArea.cumulativeDy = videoArea.maxDy
                                           if (brightnessControlArea.cumulativeDy < videoArea.minDy)
                                           brightnessControlArea.cumulativeDy = videoArea.minDy

                                           root.brightness = Math.min(Math.max(
                                               1 - ((brightnessControlArea.cumulativeDy - videoArea.minDy) / (videoArea.maxDy - videoArea.minDy)),
                                               0), 1)

                                       }
                }
            }

        }



    }



    // MultiEffect {
    //     source: settingsInfo
    //     anchors.fill: settingsInfo
    //     shadowEnabled: settingsInfo.visible || playlistInfo.visible
    //     visible: settingsInfo.visible || playlistInfo.visible
    // }

    PlaylistInfo {
        id: playlistInfo

        anchors.right: parent.right
        anchors.top: topControls.bottom
        anchors.bottom: seeker.opacity ? seeker.top : playbackControl.top
        anchors.topMargin: 10
        anchors.rightMargin: 5

        visible: false
        isShuffled: playbackControl.isPlaylistShuffled

        onVisibleChanged: showControls.start()

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
        anchors.top: topControls.bottom
        anchors.bottom: seeker.opacity ? seeker.top : playbackControl.top
        anchors.topMargin: 10
        anchors.rightMargin: 5

        mediaPlayer: mediaPlayer
        selectedAudioTrack: mediaPlayer.activeAudioTrack
        selectedVideoTrack: mediaPlayer.activeVideoTrack
        selectedSubtitleTrack: mediaPlayer.activeSubtitleTrack
        visible: false

        onVisibleChanged: showControls.start()

    }


    // -------------------------- SUBTITLE --------------------------

    SubtitleExtractor
    {
        id: extractor
    }
    SubtitleFinder
    {
        id: subtitleFinder
    }


    //subtitle list
    ListModel { id: subtitleModel }

    // Update subtitle every ..ms
    Timer {
        interval: settings.value["Media/subtitleTimerInterval"]
        running: mediaPlayer.playing ? true : false
        repeat: true

        onTriggered:
        {
            if(mediaPlayer.playing)
            {
                subtitle1Data.currentSubtitle=""
                subtitle2Data.currentSubtitle=""

                if (Scripts.asBool(settings.value["Subtitle1/status"]))
                {
                    // console.log("subtitle2Data.subtitle=",subtitle2Data.subtitle)
                    subtitle1Data.currentSubtitle = Sub.getSubtitleForTime(subtitle1Data.subtitle, mediaPlayer.position + settings.value["Subtitle1/offset"]*1000)

                    //clean stage
                    subtitle1Data.currentSubtitle=checkAndClean(subtitle1Data.currentSubtitle)


                    // WORD BY WORD MODE
                    if (Scripts.asBool(settings.value["Subtitle1/wordByWord"]))
                    {
                        subtitleText1.text = Sub.giveWordByWordSubtitle(subtitle1Data,settings.value["Subtitle1/offset"] ,
                                                                        Scripts.asInt(settings.value["Subtitle1/wordByWordChunks"]),
                                                                        mediaPlayer.position);
                    }
                    else
                        subtitleText1.text =subtitle1Data.currentSubtitle
                }


                if (Scripts.asBool(settings.value["Subtitle2/status"]))
                {
                    // console.log("subtitle2Data.subtitle=",subtitle2Data.subtitle)
                    subtitle2Data.currentSubtitle = Sub.getSubtitleForTime(subtitle2Data.subtitle, mediaPlayer.position + settings.value["Subtitle2/offset"]*1000)

                    //clean stage
                    subtitle2Data.currentSubtitle=checkAndClean(subtitle2Data.currentSubtitle)


                    // WORD BY WORD MODE
                    if (Scripts.asBool(settings.value["Subtitle2/wordByWord"]))
                    {
                        subtitleText2.text = Sub.giveWordByWordSubtitle(subtitle2Data,settings.value["Subtitle2/offset"] ,
                                                                        Scripts.asInt(settings.value["Subtitle2/wordByWordChunks"]),
                                                                        mediaPlayer.position);
                    }
                    else
                        subtitleText2.text =subtitle2Data.currentSubtitle
                }




                if(spedupByHold)//user held mouse click to spedup
                {
                    mediaPlayer.playbackRate=settings.value["Media/speedHold"]
                    showSpeeding("hold speed "+settings.value["Media/speedHold"] + "x")
                }
                else if (Scripts.asBool(settings.value["SNS/status"]))
                {
                    //speed up when text is empty.
                    if(subtitle1Data.currentSubtitle==="" && subtitle2Data.currentSubtitle==="")
                    {

                        subtitle1Data.preSubtitle=""
                        subtitle2Data.preSubtitle=""
                        //read coming up subtitle for seconds before speedup
                        if (Scripts.asBool(settings.value["Subtitle1/status"]))
                        {
                            //get presubtitle
                            subtitle1Data.preSubtitle = Sub.getSubtitleForTime(subtitle1Data.subtitle, mediaPlayer.position + settings.value["SNS/secBeforeSpeedup"]*1000)

                            //clean presubtitle
                            subtitle1Data.preSubtitle=checkAndClean(subtitle1Data.preSubtitle)
                        }
                        if (Scripts.asBool(settings.value["Subtitle2/status"]))
                        {
                            //get presubtitle
                            subtitle2Data.preSubtitle = Sub.getSubtitleForTime(subtitle2Data.subtitle, mediaPlayer.position + settings.value["SNS/secBeforeSpeedup"]*1000)

                            //clean presubtitle
                            subtitle2Data.preSubtitle=checkAndClean(subtitle2Data.preSubtitle)
                        }


                        //check for seconds before speedup to avoid speedup
                        if(subtitle1Data.preSubtitle==="" && subtitle2Data.preSubtitle==="")
                        {
                            mediaPlayer.playbackRate=settings.value["SNS/speed"];
                            showSpeeding("sns speed "+settings.value["SNS/speed"] + "x" + ", before " + settings.value["SNS/secBeforeSpeedup"] +"s")
                        }
                        else
                        {
                            // console.log("subtitle is not empty for speedup. subtitle1Data.preSubtitle=",subtitle1Data.preSubtitle,"subtitle2Data.preSubtitle=",subtitle2Data.preSubtitle)
                            mediaPlayer.playbackRate=settings.value["Media/rate"]
                            showSpeeding("")
                        }
                    }
                    else
                    {
                        mediaPlayer.playbackRate=settings.value["Media/rate"]
                        showSpeeding("")
                    }

                }
                else // set playbackrate value
                {
                    mediaPlayer.playbackRate=settings.value["Media/rate"]
                    showSpeeding("")
                }
            }
        }
    }

    // Subtitle boxes
    Rectangle
    {
        width: subtitleText1.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText1.implicitWidth
        height:subtitleText1.height
        color:settings.value["Subtitle1/backColor"]
        opacity: settings.value["Subtitle1/backOpacity"]-brightnessOverlay.opacity/2
        visible: Scripts.asBool(settings.value["Subtitle1/status"])
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:settings.value["Subtitle1/posY"]

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

                settings.setSetting("Subtitle1/posY",parent.y)
            }
        }
        Label {
            id: subtitleText1
            width: parent.width
            height: implicitHeight
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            // horizontalAlignment: Text.AlignRight

            color: settings.value["Subtitle1/textColor"]
            style: Text.Outline
            // styleColor: subtitle1Data.subTextOfsetColor
            font.pixelSize: settings.value["Subtitle1/textSize"]
        }
    }
    Rectangle
    {
        width: subtitleText2.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText2.implicitWidth
        height:subtitleText2.height
        color:settings.value["Subtitle2/backColor"]
        opacity: settings.value["Subtitle2/backOpacity"]-brightnessOverlay.opacity/2
        visible: Scripts.asBool(settings.value["Subtitle2/status"])
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:settings.value["Subtitle2/posY"]


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


                settings.setSetting("Subtitle2/posY",parent.y)
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

            color: settings.value["Subtitle2/textColor"]
            style: Text.Outline
            // styleColor: subtitle2Data.subTextOfsetColor
            font.pixelSize: settings.value["Subtitle2/textSize"]
        }
    }



    function checkAndClean(textPara)
    {
        //ignore subtitles which contain website domains
        if (Scripts.asBool(settings.value["Media/sub_removeDomains"]))
        {
            if(Scripts.containsDomain(textPara))
                textPara=""
        }


        //remove html tags
        if (Scripts.asBool(settings.value["Media/sub_ignoreHTMLtags"]))
        {
            textPara = Scripts.stripHtmlClean(textPara)
        }


        //clean subtitle
        if (Scripts.asBool(settings.value["Media/sub_cleanSubtitle"]))
        {
            textPara = Scripts.cleanSubtitleText(textPara)
        }


        //remove more info like (hello) or [this is building] or <dwadwa> or «something» ...
        if (Scripts.asBool(settings.value["Media/sub_removeExtraInfo"]))
        {
            textPara= Scripts.removeExtraInfo(textPara)
        }

        return textPara;
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
            // console.log("loaded subtitle beside video=", currentSubtitle)
        }

        if(subtitleNo)
        {
            subtitle1Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//maybe loaded from somehwereelse
                subtitle1Data.subIndex=subIndex
        }

        else
        {
            subtitle2Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//maybe loaded from somehwereelse
                subtitle2Data.subIndex=subIndex
        }

        // console.log("subtitle1Data.subtitle=",subtitle1Data.subtitle)
        // console.log("subtitle2Data.subtitle=",subtitle2Data.subtitle)

        currentSubtitle=""
    }


    // -------------------------- INDICATORS --------------------------


    // --- Volume indicator (right) ---
    Rectangle {
        id: volumeIndicator
        width: 40
        height: 200
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: "#888"
        radius: 8
        clip:true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: volumeIndicator.height * root.volume
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
        anchors.verticalCenter: parent.verticalCenter
        color: "#888"
        radius: 8
        clip:true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: brightnessIndicator.height * (1.0 - root.brightness)
            color: "#ff0"
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
            // cursorShape: Qt.OpenHandCursor
        }
    }

    ErrorPopup {
        id: errorPopup
    }

    Rectangle
    {
        id:speedingBox
        width: rowSpeeding.implicitWidth
        height: rowSpeeding.implicitHeight
        visible: false
        color:"transparent"
        anchors
        {
            verticalCenter: parent.verticalCenter
            left:parent.left
            leftMargin:50
        }

        Rectangle
        {
            anchors.fill: parent
            color:"black"
            opacity: 0.1
        }

        Row{
            id:rowSpeeding
            spacing: 10
            anchors.fill: parent
            Image {
                source: Config.activeTheme === Config.Theme.Dark
                        ? "icons/Rate_Icon_Dark.svg" : "icons/Rate_Icon.svg"
                width: 25
                height: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Label
            {
                id:speedingLabel
                text:""
                color: "yellow"
                font.pixelSize: 30
                z:0
            }
        }



    }


    function showSpeeding(text="")
    {
        if(text==="")
            speedingBox.visible=false
        else
        {
            speedingLabel.text = text;
            speedingBox.visible=true
        }
    }



    // -------------------------- CONTROLS --------------------------

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

    Rectangle
    {
        id:topControls
        width: parent.width
        height:120
        color:"transparent"
        property bool isMouseOnControl: false;
        HoverHandler {
               acceptedDevices: PointerDevice.Mouse
               onHoveredChanged: {
                   parent.isMouseOnControl = hovered
               }
           }
        Column
        {
            width: parent.width
            height: parent.height
            Rectangle
            {
                id:bgTopControls
                width: parent.width
                height:60
                color: "black"
                opacity:0.5
            }
            Rectangle
            {
                id:bgSubTopControls
                width: parent.width
                height:60
                color: "black"
                opacity:0.4
            }
        }

        Column
        {
            height: parent.height
            width: parent.width
            Row //row topControls
            {
                height: bgTopControls.height
                width:parent.width

                Rectangle //menubar
                {
                    width:100
                    height:parent.height
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
                            "All Supported Files (*.gif *.mp4 *.avi *.mkv *.mov *.webm *.mp3 *.wav *.aac *.aiff)",
                            "Music Files (*.mp3 *.wav *.aac *.aiff)",
                            "Video Files (*.mp4 *.avi *.mkv *.mov *.webm)",
                            "GIF Files (*.gif)",
                            "All Files (*)"
                        ]
                        selectedNameFilter : root.selectedNameFilter
                    }
                }
                Rectangle  //current media filename
                {
                    color: "transparent"
                    width: mediaCurrentFileLabel.implicitWidth + 10
                    height: parent.height

                    Label {
                        id: mediaCurrentFileLabel
                        text: "Media isn't selected"
                        color: "yellow"
                        font.pixelSize: {
                            // Define how width maps to font size
                            const minW = 300;   // when window is 300px wide -> use min font
                            const maxW = 1200;  // when window >=1200px -> use max font

                            const minSize = 8;
                            const maxSize = 25;

                            // Clamp width between minW and maxW
                            const w = Math.max(minW, Math.min(root.width, maxW));

                            // Linear interpolation (lerp) between min and max font size
                            return minSize + (maxSize - minSize) * ((w - minW) / (maxW - minW));
                        }

                        anchors.centerIn: parent
                    }
                }

            }

            Row //row sub TopControls
            {
                height: bgSubTopControls.height
                width:parent.width
                leftPadding: 50
                rightPadding: 50
                spacing: 25
                Dial {
                    id: rotationDial
                    from: 0
                    to: 360
                    value: settings.value["Media/rotationAngle"] // 0 = normal, 90 = rotated right, 180 = upside down, 270 = rotated left
                    stepSize: 1
                    onValueChanged:
                    {
                        settings.setSetting("Media/rotationAngle",value)
                        videoOutput.rotation=value
                    }
                    width: 45
                    height: 45
                }

                Row //sns settings
                {
                    anchors.verticalCenter:parent.verticalCenter
                    SpinBox {
                        id: offsetBeforeSubtitle
                        width: 50
                        height:25
                        from: 0    // advance up to 10s
                        to: 50       // delay up to 10s
                        // stepSize: 0.5
                        value: settings.value["SNS/secBeforeSpeedup"]
                        visible: snsCheckbox.checked
                        onValueChanged:
                        {
                            settings.setSetting("SNS/secBeforeSpeedup",value)
                        }
                    }
                    Column
                    {
                        CustomCheckbox
                        {
                            id:snsCheckbox
                            initialCheckedState: (settings.value["SNS/status"] === "true")
                            theText:"SNS"
                            onStatusChangeAction:
                            {
                                settings.setSetting("SNS/status",checked)
                            }
                            leftPadding: indicator.width
                        }
                        SpinBox {
                            id:snsSpeedSpinBox
                            width: 50
                            height:25
                            from: 0    // advance up to 10s
                            to: 50       // delay up to 10s
                            value: settings.value["SNS/speed"]
                            visible: snsCheckbox.checked
                            onValueChanged:
                            {
                                settings.setSetting("SNS/speed",value)
                            }
                        }
                    }

                    SpinBox {
                        id: offsetAfterSubtitle
                        width: 50
                        height:25
                        from: 0    // advance up to 10s
                        to: 50       // delay up to 10s
                        // stepSize: 0.5
                        value: settings.value["SNS/secAfterSpeedup"]
                        visible: snsCheckbox.checked
                        onValueChanged:
                        {
                            settings.setSetting("SNS/secAfterSpeedup",value)
                        }
                    }

                }


            }

        }

    }


    Timer {
        id: controlsHideTimer
        interval: 3000   // milliseconds to hide after last change
        repeat: false
        running: false
        onTriggered:
        {
            if(!playbackControl.isMouseOnControl && !settingsInfo.visible && !playlistInfo.visible
                    && !seeker.isMouseOnControl && !topControls.isMouseOnControl && !menuBar.isMenuOpened)
            {
                hideControls.start()
            }
        }
    }


    ParallelAnimation {
        id: hideControls

        NumberAnimation {
            targets: [playbackControl, seeker, background, shadow, topControls, volumeIndicator, brightnessIndicator]
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
        onStarted:
        {
            backend.changeCursor("blank")
        }
    }

    ParallelAnimation {
        id: showControls

        NumberAnimation {
            targets: [playbackControl, seeker, shadow,topControls, volumeIndicator, brightnessIndicator]
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
        onStarted:
        {
            //give focus for events
            brightnessOverlay.focus=true

            backend.changeCursor()

            //to 3 seconds later check and decide to call hideControls.start() or not
            controlsHideTimer.running=true
        }
    }



    function keyboardButtonsHandler(event)
    {
        if(event.key === Qt.Key_Up  && (event.modifiers & Qt.ShiftModifier))
        {
            brightnessDown()
        }

        else if(event.key === Qt.Key_Down  && (event.modifiers & Qt.ShiftModifier))
        {
            brightnessUp()
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

        showControls.start()
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
        if(root.volume<100)
            root.volume+=val
    }

    function volDown(val=0.10)
    {
        if(root.volume>0)
            root.volume-=val
    }

    function speedUp(val=0.5)
    {
        var temp = settings.value["Media/rate"]
        if(temp<100)
            settings.setSetting("Media/rate",temp+val)
    }

    function speedDown(val=0.5)
    {
        var temp = settings.value["Media/rate"]
        if(temp>0)
            settings.setSetting("Media/rate",temp-val)
    }

    function brightnessUp(val=0.10)
    {
        if(root.brightness<100)
            root.brightness+=val
    }

    function brightnessDown(val=0.10)
    {
        if(root.brightness>0)
            root.brightness-=val
    }

    function muteUnmute()
    {
        settings.setSetting("Media/muted",
                            Scripts.asBool(settings.value["Media/muted"]))
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



    // -------------------------- ETC --------------------------



    function callbycpp(name="empty")
    {
        return "."+name+".";
    }



    function dosomething()
    {
        console.log("doing something...")
    }

    Component.onCompleted: {
        if (source.toString().length > 0)
            openFile(source)
        else
            mediaPlayer.play()


        //alias media stuff for config
        Config.mediaDevicesPtr=mediaDevices
        Config.mediaPlayerPtr=mediaPlayer



        //get data from settings c++ (will save onClose app)
        root.brightness=Scripts.asInt(settings.value["Media/brightness"])
        root.volume=Scripts.asInt(settings.value["Media/volume"])


        backend.setupCustomCursor(settings.value["App/customCursorIconPath"],20,20,10,10);
    }

    // Connections {
    //         target: settings
    //         function onValueChanged()
    //         {
    //             console.log("Settings changed")
    //         }
    //     }
}

