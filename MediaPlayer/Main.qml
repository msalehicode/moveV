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
import "../MediaControls/MyComponents/"
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

    minimumHeight: 460
    minimumWidth: 640
    visible: true
    color: Config.mainColor
    title: qsTr("moveV Player")
    required property url source

    property alias currentFile: playlistInfo.currentIndex
    property alias playlistLooped: playbackControl.isPlaylistLooped
    property alias metadataInfo: settingsInfo.metadataInfo
    property alias tracksInfo: settingsInfo.tracksInfo

    property bool spedupByHold: false //a flag to set when user hold mouse click to speedup
    property bool spedupByHoldFromRemote: false
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
            volume: Scripts.asBool(settings.value["Media/muted"])? 0 : root.volume
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
            // console.debug("matches.length=",matches.length, "matches",matches )
            if (matches.length > 0) {
                // console.debug("Possible subtitles found:")
                for (let i = 0; i < matches.length; ++i)
                {
                    // console.debug("sub: " + matches[i])
                    subtitleModel.append({"text":  matches[(i)] , "index": (i+1), "path": matches[i]})
                }
            }
            else
            {
                console.info("subtitle file doesnt match (living directory subtitle files are not matching for current media)")
            }


            //pass subtitleModel to settings combobox
            settingsInfo.settingsPage.foundSubtitles = subtitleModel


            if (Scripts.asBool(settings.value["Media/autoLoadSubtitles"]))
            {
                // console.debug("autoLoadSubtitles..")
                var path=subtitleModel.get(0).path
                loadSubtitle(path==="embedded"?true:false,path,false,0)

                path=subtitleModel.get(1).path
                loadSubtitle(path==="embedded"?true:false,path,true,1)
            }

            /*
            for (let i = 0; i < audioTracks.length; ++i)
            {
                let track = audioTracks[i];
                console.debug("track=", track.stringValue(6))
                // console.debug("audiotracks:",audioTracks)
            }
            */

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
                    showControls.start()
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


    //


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
                    // console.debug("subtitle2Data.subtitle=",subtitle2Data.subtitle)
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
                    // console.debug("subtitle2Data.subtitle=",subtitle2Data.subtitle)
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

                if(spedupByHold || spedupByHoldFromRemote)//user held mouse click to spedup
                {
                    mediaPlayer.playbackRate=settings.value["Media/speedHold"]
                    showSpeeding("hold speed "+settings.value["Media/speedHold"] + "x" +
                                 (spedupByHoldFromRemote? " (by remote)" : ""))
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
                            // console.debug("subtitle is not empty for speedup. subtitle1Data.preSubtitle=",subtitle1Data.preSubtitle,"subtitle2Data.preSubtitle=",subtitle2Data.preSubtitle)
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


    function loadSubtitle(embedded, subPath,subtitleNo=true, subIndex=50)
    {
        //embeded -> stuck with media or not
        //subPath -> address of file
        //subtitleNo -> apply for sub1 or sub2?
        //subIndex -> those case e.g media has 2 embedded subtitles so which one?



        if(embedded)
        {
            currentSubtitle = extractor.extractSubtitle(mediaPlayer.source, subIndex)
            // console.debug("extract subtitle from video=", currentSubtitle)
        }
        else
        {
            if (subPath.startsWith("file://"))
                subPath = subPath.slice(7)

            currentSubtitle = extractor.loadSrtFile(subPath)
            // console.debug("loaded subtitle beside video=", currentSubtitle)
        }

        if(subtitleNo)
        {
            subtitle1Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            subtitle1Data.subfilePath=subPath
            if(subIndex>=0)//maybe loaded from somehwereelse
                subtitle1Data.subIndex=subIndex
        }
        else
        {
            subtitle2Data.subtitle = Sub.parseSubtitle(currentSubtitle)
            subtitle2Data.subfilePath=subPath
            if(subIndex>=0)//maybe loaded from somehwereelse
                subtitle2Data.subIndex=subIndex
        }

        // console.debug("subtitle1Data.subtitle=",subtitle1Data.subtitle)
        // console.debug("subtitle2Data.subtitle=",subtitle2Data.subtitle)

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



    Column
    {
        id:showingStatusBox
        width: implicitWidth
        height: implicitHeight
        anchors
        {
            verticalCenter: parent.verticalCenter
            left:parent.left
            leftMargin:50
        }

        Rectangle
        {
            id:speedingBox
            width: rowSpeeding.implicitWidth
            height: rowSpeeding.implicitHeight
            visible: false
            color:"transparent"

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


        Rectangle
        {
            id:muteBox
            width: rowMute.implicitWidth
            height: rowMute.implicitHeight
            visible: Scripts.asBool(settings.value["Media/muted"])
            color:"transparent"

            Rectangle
            {
                anchors.fill: parent
                color:"black"
                opacity: 0.1
            }

            Row
            {
                id:rowMute
                spacing: 10
                anchors.fill: parent
                Image {
                    source: "icons/Warning_Icon.svg"
                    width: 25
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label
                {
                    text:"Muted"
                    color: "yellow"
                    font.pixelSize: 30
                    z:0
                }
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

                Column
                {
                    id:bluetoothHostingBox
                    Row
                    {
                        spacing: 5
                        Rectangle
                        {
                            id:bluetoothStateColor
                            width:20
                            height:20
                            radius: 20
                            color: (function(status) {
                                switch(status) {
                                    case 0: return "red";
                                    case 3: return "lime";
                                    case 1:
                                    case 2: return "green"
                                    default: return "black";
                                }
                                })(backend.bluetoothHostModeState)

                        }
                        Label
                        {
                            id:bluetoothDeviceNameAddressAndState
                            text: backend.btLocalName + " max:" + backend.btMaxConnectionUser
                        }
                    }


                    //later adeptor list via RadioButton by Repeater

                    CustomCheckbox
                    {
                        id:bluetoothHostAlwaysDiscoverable
                        initialCheckedState: backend.btAlwaysDiscoverable
                        theText:"always discoverable";
                        onStatusChangeAction:
                        {
                            backend.btAlwaysDiscoverable=checked
                            settings.setSetting("App/bluetoothHostAlwaysDiscoverable",checked)
                        }
                    }

                    CustomCheckbox
                    {
                        id:bluetoothHostStatus
                        initialCheckedState:  Scripts.asBool(settings.value["App/bluetoothHostStatus"])
                        theText:"Bluetooth host (" + (function(status) {
                            switch(status) {
                                case -1: return "Unknown";
                                case 0:  return "Starting...";
                                case 10: return "Adaptor Not Found";
                                case 11: return "Failed";
                                case 20: return "Permission Denied";
                                case 21: return "Asking Permission";
                                case 22: return "Permission Granted";
                                case 30: return "Inactive";
                                case 31: return "Discoverable";
                                case 32: return "Loading";
                                case 33: return "Active";
                                default: return "Unknown Status: "+status;
                            }
                        })(backend.btStatus) +")"

                        enabled: (backend.btStatus!==0 && backend.btStatus!==32)//BtStatus::Starting or ::Loading  (disable it to make sure user dont spam start/stop button while backend is working on bluetooth server)
                        onStatusChangeAction:
                        {
                            backend.bluetoothServer(checked);
                            settings.setSetting("App/bluetoothHostStatus",checked)
                        }
                    }



                    Rectangle
                    {
                        width: 200
                        height: 60
                        color:"transparent"
                        Row
                        {
                            Label
                            {
                                text:"Max Connection:"
                                color: "white"
                            }
                            MySlider
                            {
                                id:bluetoothHostMaxAllowedConnection
                                setWidth: 200
                                setHeight: 10
                                setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                                setColor: !Config.activeTheme ? "white" : Config.highlightColor
                                setOpacity: !Config.activeTheme ? 0.8 : 0.5
                                intialValue: backend.btMaxConnectionUser
                                setFilledLeftRadius: 30
                                setRadius: 30
                                setFrom: 1
                                setTo: 5
                                onModified: //value changed
                                {
                                    // console.debug("bt max users changed to " + value)
                                    backend.btMaxConnectionUser=value
                                }
                                onHovered:
                                {
                                    if(isHovered)
                                        backend.changeCursor("hand")
                                    else
                                        backend.changeCursor()
                                }
                            }

                        }


                    }


                }


                Column
                {
                    id:networkHostingBox
                    Label
                    {
                        id:networkHostName
                        text:"network name:" + backend.netLocalName
                    }

                    CustomCheckbox
                    {
                        id:networkHostStatus
                        initialCheckedState:  Scripts.asBool(settings.value["App/networkHostStatus"])
                        theText:"Network host (" + (function(status) {
                            switch(status) {
                                case -1: return "Unknown";
                                case 0:  return "Starting...";
                                case 10: return "Adaptor Not Found";
                                case 11: return "Failed";
                                case 30: return "Inactive";
                                case 31: return "Loading";
                                case 32: return "Active";
                                default: return "Unknown Status: "+status;
                            }
                        })(backend.ntStatus) +")"

                        enabled: (backend.ntStatus!==0 && backend.ntStatus!==31)
                        //NetStatus::Starting or ::Loading  (disable it to make sure user dont spam start/stop button while backend is working on network server)
                        onStatusChangeAction:
                        {
                            backend.netServer(checked);
                            settings.setSetting("App/networkHostStatus",checked)
                        }
                    }



                }


                CustomCollapsiblePanel
                {
                    setWidth: 500
                    setHeight: 250
                    setTitle: "Connected remotes: (" + connectedUsers.count + ")"
                    setBgColorButton:"black"
                    setBgContent: "grey"
                    setContentHeight: connectedUsers.count===0 ? 60+15 : (connectedUsers.count*(60+15)) //15spacing, 60height item
                    setIconArrow: "icons/back.png"
                    pathFromComponentDire:false
                    ListView {
                        id:connectedUsers
                        anchors.fill: parent
                        model: backend.connectedUsersList
                        spacing: 15
                        delegate: Rectangle
                        {
                            width: parent.width
                            height: 60
                            color:(function(status) {
                                switch(status) {
                                    case "Connected": return "#256b00"; //dark green
                                    case "ConnectionLost": return "#c76400"; //dark orange
                                    case "Disconnected": return "#950500"; //dark red
                                    default: return "purple";
                                }})(modelData.status) //connection status
                            Row
                            {
                                anchors.fill: parent
                                spacing: 10
                                Image
                                {
                                    width:50
                                    height:50
                                    source: modelData.using==="B"? "icons/bluetooth.png" : "icons/wifi.png"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle
                                {
                                    color:"black"
                                    width:35
                                    height:35
                                    radius: 35
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label
                                    {
                                        text: modelData.ping==="-1" ? "?" : modelData.ping
                                        color:"white"
                                        anchors.centerIn: parent
                                        font.pixelSize: 15
                                    }
                                }


                                Text
                                {
                                    /*
                                       modelData.access
                                       .connectedAt
                                       .address
                                       .status
                                       .name
                                       .using
                                       .ping
                                    */
                                    text:"name: ("+modelData.name+") @ ["+modelData.address+"]"
                                    width: 200
                                    color: "white"
                                    font.pixelSize: 15
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                MyButton
                                {
                                    setWidth:60
                                    setHeight:40
                                    setButtonBackColor: "black"
                                    setButtonBorderColor: "transparent"
                                    setButtonFontColor: "white"
                                    setButtonFontsize: 13
                                    setButtonText: "Kick"
                                    onButtonClicked:  backend.kickUser(modelData.address);
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                MyButton
                                {
                                    setWidth:60
                                    setHeight:40
                                    setButtonBackColor: "black"
                                    setButtonBorderColor: "transparent"
                                    setButtonFontColor: "white"
                                    setButtonFontsize: 13
                                    setButtonText: "Ban"
                                    onButtonClicked: backend.banUser(modelData.address);
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }
                        }
                    }
                }


                CustomCollapsiblePanel
                {
                    setWidth: 250
                    setHeight: 200
                    setTitle:"banned users: (" + listViewBannedUsers.count + ")"
                    setBgColorButton: "black"
                    setTextColor: "white"
                    setIconArrow: "icons/back.png"
                    pathFromComponentDire:false

                    setContentHeight: listViewBannedUsers.count===0 ? 60+15 : (listViewBannedUsers.count*(60+15)) //15spacing, 60height item
                    ListView
                    {
                        id:listViewBannedUsers
                        anchors.fill: parent
                        model: backend.bannedUsers
                        spacing: 15
                        delegate: Rectangle
                        {
                            color:"black"
                            width:parent.width/1.20
                            height:60
                            anchors.horizontalCenter:parent.horizontalCenter

                            Row
                            {
                                anchors.fill: parent
                                Label
                                {
                                    text:modelData
                                    font.pixelSize: 15
                                    color: "white"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                MyButton
                                {
                                    setWidth:60
                                    setHeight:40
                                    setButtonBackColor: "green"
                                    setButtonBorderColor: "transparent"
                                    setButtonFontColor: "black"
                                    setButtonFontsize: 13
                                    setButtonText: "Unban"
                                    onButtonClicked: backend.unbanUser(modelData) //pass banned address
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }


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

            case Qt.Key_Escape:
            {
                if(videoOutput.fullScreen)
                {
                    root.showNormal()
                }
            }break;


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
    function changePosition(val)
    {
        mediaPlayer.position = val
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

    function changeVol(val)
    {
        if(val>=0 && val<=1)
            root.volume=val
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

    function startHoldSpeeding()
    {
        spedupByHoldFromRemote=true
    }
    function stopHoldSpeeding()
    {
        spedupByHoldFromRemote=false
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

    function changeBrightness(val)
    {
        if(val<100 && val >0)
        {
            root.brightness=val
        }
    }

    function muteUnmute()
    {
        settings.setSetting("Media/muted",
                            !Scripts.asBool(settings.value["Media/muted"]))
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


    function shuffleToggle()
    {
        playlistInfo.isShuffled=!playlistInfo.isShuffled
    }

    function fullscreenToggle()
    {
        mediaPlayer.doFullscreen()
    }

    // -------------------------- popups --------------------------



    //to appear above all components and contorls (on click close overlays)
    Rectangle
    {
        id:popupOverlay
        anchors.fill: parent
        color:"black"
        opacity: 0.7
        visible: playlistInfo.visible || settingsInfo.visible
        MouseArea
        {
            anchors.fill: parent
            onClicked: root.closeOverlays()
        }
    }


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


    DropArea {
        id:dropHandler
        anchors.fill: parent
        property string subPath;
        function openDialog()
        {
            dropAreaOverlayClose.visible=true
            applyForWhichSubtitle.visible=true
            cancelApplSubtitleButton.visible=true
        }

        function closeDialog()
        {
            dropAreaOverlayClose.visible=false
            applyForWhichSubtitle.visible=false
            cancelApplSubtitleButton.visible=false
            subPath=""
        }
        function applyForSubtitle1()
        {
            loadSubtitle(false,subPath,true)
            closeDialog()
        }

        function applyForSubtitle2()
        {
            loadSubtitle(false,subPath,false)
            closeDialog()
        }

        Rectangle
        {
            id:dropAreaOverlayClose
            anchors.fill: parent
            color:"black"
            // opacity:0.0
            visible: false
            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    // dropHandler.closeDialog()
                    console.info("user must select one subtitle OR cancel.")
                }
            }
        }
        Rectangle
        {
            id:cancelApplSubtitleButton
            width:100
            height:100
            color:"red"
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            Label
            {
                text:"cancel"
                wrapMode: "WrapAnywhere"
                width: parent.width
                height: parent.height
                font.pixelSize: 20
                color:"black"
                anchors.centerIn: parent
            }
            MouseArea
            {
                anchors.fill: parent
                onClicked: dropHandler.closeDialog()
            }
        }

        Rectangle
        {
            id:applyForWhichSubtitle

            visible:false
            width: parent.width/2
            height:parent.height/2
            color:"transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            radius: width

            Row{
                anchors.fill: parent
                spacing: 20
                Rectangle
                {
                    color:Config.highlightColor
                    width: parent.width/2
                    height: parent.height
                    radius:20
                    Label
                    {
                        text:"for subtitle 1" + "\n" + "current:" + subtitle1Data.subfilePath
                        wrapMode: "WrapAnywhere"
                        width: parent.width
                        height: parent.height
                        font.pixelSize: 20
                        color:"black"
                        anchors.centerIn: parent
                    }

                    MouseArea{
                        anchors.fill: parent
                        onClicked:
                        {
                            dropHandler.applyForSubtitle1()
                        }
                    }
                }
                Rectangle
                {
                    color:Config.highlightColor
                    width: parent.width/2
                    height: parent.height
                    radius:20
                    Label
                    {
                        text:"for subtitle 2" + "\n" + "current:" + subtitle2Data.subfilePath
                        wrapMode: "WrapAnywhere"
                        width: parent.width
                        height: parent.height
                        font.pixelSize: 20
                        color:"black"
                        anchors.centerIn: parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked:
                        {
                            dropHandler.applyForSubtitle2()
                        }
                    }
                }
            }
        }

        // Accept common file-drop mimetypes
        keys: ["text/uri-list"]
        onEntered: (drag) => {
            // console.debug("Entered with:", drag.keys)
            drag.acceptProposedAction() //tell OS drop is allowed/accepted
        }


        onDropped: (drop) => {
                       // console.debug("Dropped keys:", drop.keys)
                       // console.debug("Dropped urls:", drop.urls)
                       let countFiles=drop.urls.length

                       const fileFormat = Scripts.isSupportedFormat(drop.urls[0],true)
                       if((fileFormat === ".srt" || fileFormat===".sub") &&
                          countFiles===1)//if its single and foramt is subttile apply for subtitle
                       {
                           // console.debug("dropped file is single subtitle")
                           dropHandler.openDialog()
                           subPath=drop.urls[0]
                       }
                       else
                        playlistInfo.addFiles(countFiles, drop.urls)

                       drop.acceptProposedAction() //tell OS drop is done
                   }
    }



    ErrorPopup {
        id: errorPopup
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


        if(Scripts.asBool(settings.value["App/bluetoothHostStatus"]))
            backend.bluetoothServer(true)

        if(Scripts.asBool(settings.value["App/networkHostStatus"]))
            backend.netServer(true)
    }
}

