import QtQuick
import QtQuick.Controls
import QtMultimedia
import "SubtitleUtils.js" as Sub
import CustomMedia 1.0
import SubtitleFinder 1.0
import QtQuick.Dialogs
import "CustomComponents"

Window {
    id:mainWindow
    width: 800; height: 600; visible: true

    Rectangle
    {
        anchors.fill: parent
        color:"black"
    }

    SubtitleExtractor
    {
        id: extractor
    }
    SubtitleFinder {
        id: subtitleFinder
    }

    // 0 = normal, 90 = rotated right, 180 = upside down, 270 = rotated left
    property real rotationAngle:  0

    property string currentSubtitle: ""
    property bool autoLoadSubtitles: true
    property string selectedMediaFilePath;
    property real thePlaybackRate:1.0

    property var subtitle1;
    property int sub1Index: 0
    property int subtitle1OffsetMs: 0
    property bool subtitle1Status: true;
    property string sub1TextColor: "yellow"
    property string sub1TextOfsetColor: "red"
    property string sub1BackColor:"black"
    property real sub1BgOpacity: 0.5
    property int sub1FontSize: 35
    property int sub1posy: 0
    property string sub1filePath: "";

    property var subtitle2;
    property int sub2Index: 0
    property int subtitle2OffsetMs: 0
    property bool subtitle2Status: true;
    property string sub2TextColor: "yellow"
    property string sub2TextOfsetColor: "red"
    property string sub2BackColor:"black"
    property real sub2BgOpacity: 0.5
    property int sub2FontSize: 35
    property int sub2posy: 50
    property string sub2filePath: "";


    property bool spedupByHold: false

    MediaPlayer {
        id: player
        // source: "https://dl4.indllserver.info/Movies8/2025/Roofman.2025/Roofman.2025.480p.WEB-DL.x264.ZarFilm.mkv?md5=Se8-Q7EJHgZjH1BWWcaqbA&u=743953&expires=1762946468"
        videoOutput: videoOutput
        audioOutput: audioOutput
        playbackRate: thePlaybackRate

        onTracksChanged:
        {
            //encounter embedded subtitles
            subtitleModel.clear()
            for (let i = 0; i < subtitleTracks.length; ++i)
            {
                let lang = subtitleTracks[i].stringValue(6) // 6 = language key
                subtitleModel.append({"text": lang ? lang : "Embedded Subtitle " + i, "index": i, "path": "embedded"})
            }

            // --- Audio Tracks ---
            audioTracksModel.clear()
            audioTracksModel.append({
                                        "text":"null",
                                        "index": -1
                                    })

            for (let i = 0; i < audioTracks.length; ++i) {
                // Common string keys:
                // 6 = language, 1 = codec, 3 = description (depends on Qt version)
                let lang = audioTracks[i].stringValue(6)
                let codec = audioTracks[i].stringValue(1)
                audioTracksModel.append({
                                            "text": (lang ? lang+" "+i : "Track " + i) + (codec ? " (" + codec + ")" : ""),
                                            "index": i
                                        })
            }
            if(audioTracksModel.count>1)
            {
                audioTrackCombobox.visible=true
                audioTrackCombobox.currentIndex=1;
            }
            else
                audioTrackCombobox.visible=false

            //encounter subtitle files
            let matches = subtitleFinder.findMatchingSubtitles(player.source)
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




            // console.log("Subtitle tracks:", subtitleTracks.length)
            // for (let i = 0; i < subtitleTracks.length; ++i)
            // console.log(i, Button { text: "Subtitle"; onClicked: popupMessage.open() }subtitleTracks[i].stringValue(6))  // 6 = language key
        }
    }

    AudioOutput
    {
        id:audioOutput
        volume: videoArea.volume
    }

    VideoOutput {
        id:videoOutput
        anchors.fill: parent
        visible: true
        // rotation property in degrees
        rotation: rotationAngle
        transformOrigin: Item.Center   // rotate around center
        // source: player
    }


    // Update subtitle every 200 ms
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered:
        {
            if(player.playing)
            {
                if(subtitle1Status)
                {
                    // console.log("subtitle1 = ",subtitleText1.text)
                    subtitleText1.text = Sub.getSubtitleForTime(subtitle1, player.position + subtitle1OffsetMs*1000)
                }

                if(subtitle2Status)
                {
                    // console.log("subtitle2 = ",subtitleText2.text)
                    subtitleText2.text = Sub.getSubtitleForTime(subtitle2, player.position + subtitle2OffsetMs*1000)
                }

                //ignore subtitles which contain website domains
                if(removeDomains.checkState)
                {
                    if(containsDomain(subtitleText1.text))
                        subtitleText1.text=""
                    if(containsDomain(subtitleText2.text))
                        subtitleText2.text=""
                }


                //remove html tags
                if(removeHtmlTags.checkState)
                {
                    subtitleText1.text = stripHtmlClean(subtitleText1.text)
                    subtitleText2.text = stripHtmlClean(subtitleText2.text)
                }



                if(spedupByHold)//user held mouse click to spedup
                {
                    player.playbackRate=2
                    console.log("hold speedhp")
                }
                else if(speedupWhenNoSubtitle.checkState)
                {
                    //speed up when text is empty.
                    if(subtitleText1.text==="" && subtitleText2.text==="")
                        player.playbackRate=2;
                    else
                        player.playbackRate=thePlaybackRate

                }
                else // set playbackrate value
                {
                    player.playbackRate=thePlaybackRate
                    console.log("normal speed")
                }
            }
        }
    }

    function containsDomain(text) {
        if (!text)
            return false;

        var domainRegex =
                /\b((https?:\/\/)?(www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(\/\S*)?\b/;

        return domainRegex.test(text);
    }


    function stripHtmlClean(text) {
        if (!text)
            return "";
        return text
        .replace(/<[^>]+>/g, "") // remove tags
        .replace(/\s+/g, " ") // normalize spaces
        .trim();
    }

    //subtitle list
    ListModel { id: subtitleModel }

    ListModel { id: audioTracksModel }






    CustomPopupMessage
    {
        id:popupMessage
        setDefaultText: ""
        setFailColor: "red"
        setSuccessColor: "green"
        setBgContent: "grey"
        setTextFontSize: 15
        setTextColor:  "black"
        setBgColorPopup: "black"
        setWidth: parent.width
        setHeight: parent.height
        Column
        {
            anchors.fill: parent
            spacing:5
            Button
            {
                text:"close"
                width:50
                height:50
                onClicked:
                {
                    popupMessage.close()
                }
            }

            CustomSwitchText
            {
                id:chooseSutitle
                setWidth:parent.width
                setHeight:70
                setRadius:70
                setBgColor: "black"
                setSwitchColor: "lime"
                setSwitchOpacity: 0.5
                setFontColor:"white"
                setFontSize: 15
                setRighttText:"First"
                setLeftText: "Second"
                switchStatus: true
                onSwitchClicked:
                {
                    if(switchStatus)
                    {
                        subtitleCombo.currentIndex=sub1Index
                        disableEnableSub.setStatus(subtitle1Status)
                        subfontsize.value=sub1FontSize
                    }

                    else
                    {
                        subtitleCombo.currentIndex=sub2Index
                        disableEnableSub.setStatus(subtitle2Status)
                        subfontsize.value=sub2FontSize
                    }

                }
            }

            Text
            {
                text:"subtitle status:"
                width:parent.width
                height:30
            }
            CustomSwitch
            {
                id:disableEnableSub
                setWidth:50
                setHeight:30
                setBgColorActivated: "blue"
                setBgColorDeactivated:"black"
                switchStatus: chooseSutitle.switchStatus ? subtitle1Status : subtitle2Status
                // setStatusBorder:false;
                onSwitchClicked:
                {
                    if(chooseSutitle.switchStatus)
                        subtitle1Status = !subtitle1Status
                    else
                        subtitle2Status = !subtitle2Status
                }
            }

            Text
            {
                text:"from video subtitels:"
                width:parent.width
                height:30
            }
            ComboBox {
                id: subtitleCombo
                width:parent.width
                height:90
                model: subtitleModel
                textRole: "text"

                onCurrentIndexChanged:
                {
                    if (currentIndex >= 0 && currentIndex < subtitleModel.count)
                    {
                        var subIndex= subtitleModel.get(currentIndex).index;
                        var subText= subtitleModel.get(currentIndex).text
                        var subPath=  subtitleModel.get(currentIndex).path
                        if(subPath==="embedded")
                        {
                            loadSubtitle(true, player.source, chooseSutitle.switchStatus, subIndex)
                        }
                        else
                        {
                            loadSubtitle(false, subPath, chooseSutitle.switchStatus, subIndex)
                        }


                    }
                }
            }

            Text
            {
                text:"load from local starage subtitle:"
                width:parent.width
                height:30
            }
            Text
            {
                text:"selected file:" + chooseSutitle.switchStatus ? sub1filePath : sub2filePath
                width:parent.width
                visible: sub1filePath.length>0||sub2filePath.length>0 ? (chooseSutitle.switchStatus ? sub1filePath : sub2filePath) : false
                height:30
            }
            Button
            {
                text: "pick a file"
                width:parent.width
                height:30
                onClicked:
                {
                    fileDialog.open()
                }
            }

            Text
            {
                text:"change subtitle offset:"
                width:parent.width
                height:30
            }
            SpinBox {
                id: offsetSpin
                width: 50
                height:50
                from: -50    // advance up to 10s
                to: 50       // delay up to 10s
                // stepSize: 0.5
                value: chooseSutitle.switchStatus ? subtitle1OffsetMs : subtitle2OffsetMs
                onValueChanged:
                {
                    if(chooseSutitle.switchStatus)
                        subtitle1OffsetMs = value
                    else
                        subtitle2OffsetMs = value
                }
            }

            Text
            {
                text:"change subtitle fontsize:"
                width:parent.width
                height:30
            }
            SpinBox {
                id: subfontsize
                width: 50
                height:50
                from: 0    // advance up to 10s
                to: 200       // delay up to 10s
                // stepSize: 0.5
                value: chooseSutitle.switchStatus ? sub1FontSize : sub2FontSize
                onValueChanged:
                {
                    if(chooseSutitle.switchStatus)
                        sub1FontSize = value
                    else
                        sub2FontSize = value
                }
            }
        }


    }

    FileDialog {
        id: fileDialog
        title: "Choose a subtitle file"
        // folder: StandardPaths.home
        // selectExisting: true
        nameFilters: ["Subtitle Files (*.srt)", "All Files (*)"]

        onAccepted: {
            if(chooseSutitle.switchStatus)
            {
                sub1filePath = selectedFile
                loadSubtitle(false, sub1filePath, chooseSutitle.switchStatus, -1)
            }
            else
            {
                sub2filePath = selectedFile
                loadSubtitle(false, sub2filePath, chooseSutitle.switchStatus, -1)
            }
        }

        onRejected: {
            if(chooseSutitle.switchStatus)
            {
                sub1filePath = ""
            }
            else
            {
                sub2filePath = ""
            }
            console.log("File selection canceled")
        }
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
                            videoArea.volume = Math.min(videoArea.volume + 0.1, 1.0);
                        } else {
                            videoArea.volume = Math.max(videoArea.volume - 0.1, 0.0);
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
                            console.log("ptrddf= ", event.key)
                            if(event.key === Qt.Key_Up  && (event.modifiers & Qt.ShiftModifier))
                            {
                                videoArea.brightness += 0.1
                                console.log("shoift")
                            }

                            else if(event.key === Qt.Key_Down  && (event.modifiers & Qt.ShiftModifier))
                            {
                                videoArea.brightness -= 0.1
                                console.log("shoift-")
                            }

                            else if(event.key === Qt.Key_Up  && (event.modifiers & Qt.ControlModifier))
                            {
                                console.log("control playback=",thePlaybackRate)
                                thePlaybackRate += 0.10
                                player.playbackRate=thePlaybackRate
                            }

                            else if(event.key === Qt.Key_Down  && (event.modifiers & Qt.ControlModifier))
                            {
                                console.log("control- playback=",thePlaybackRate)
                                thePlaybackRate -= 0.10
                                player.playbackRate=thePlaybackRate
                            }

                            else
                            switch(event.key)
                            {
                                case Qt.Key_M:
                                {
                                    videoArea.volume=0
                                }break;
                                case Qt.Key_Space:
                                {
                                    if(!player.playing)
                                    playVideo()
                                    else
                                    pauseVideo()
                                }break;
                                case Qt.Key_Right:
                                {
                                    seekForth()
                                }break;
                                case Qt.Key_Left:
                                {
                                    seekBack();
                                }break;
                                case Qt.Key_Up:
                                {
                                    videoArea.volume += 0.1
                                }break;
                                case Qt.Key_Down:
                                {
                                    videoArea.volume -= 0.1
                                }break;
                                case Qt.Key_F:
                                case Qt.Key_Enter:
                                case Qt.Key_Return:
                                {
                                    changeWindowFullScreen()
                                }break;
                            }
                            showControls()
                        }

        MouseArea {
            hoverEnabled: true  // enables movement detection even without pressing

            anchors.fill: parent
            preventStealing: false
            propagateComposedEvents: true
            onDoubleClicked:
            {
                changeWindowFullScreen()
            }
            onPositionChanged: (mouse) =>
                               {
                                   showControls()
                               }
            // onClicked:
            // {

            // }

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

                                           console.log("Volume:", videoArea.volume.toFixed(2))
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


                                           console.log("Brightness:", videoArea.brightness.toFixed(2))
                                       }
                }
            }


        }

    }


    // Subtitle overlay
    Rectangle
    {
        width: subtitleText1.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText1.implicitWidth
        height:subtitleText1.height
        color:sub1BackColor
        opacity: sub1BgOpacity-brightnessOverlay.opacity/2
        visible: subtitle1Status
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:sub1posy

        property int parentWidth: parent ? parent.width : 0
        property int parentHeight: parent ? parent.height : 0
        MouseArea {
            id: dragArea
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

                sub1posy=parent.y
            }
        }
        Label {
            id: subtitleText1
            width: parent.width
            height: implicitHeight
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            // horizontalAlignment: Text.AlignRight

            color: sub1TextColor
            style: Text.Outline
            styleColor: sub1TextOfsetColor
            font.pixelSize: sub1FontSize
        }
    }
    Rectangle
    {
        width: subtitleText2.implicitWidth>parent.width/1.5? parent.width/1.5 : subtitleText2.implicitWidth
        height:subtitleText2.height
        color:sub2BackColor
        opacity: sub2BgOpacity-brightnessOverlay.opacity/2
        visible: subtitle2Status
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        Drag.source: parent
        y:sub2posy

        property int parentWidth: parent ? parent.width : 0
        property int parentHeight: parent ? parent.height : 0
        MouseArea
        {
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


                sub2posy=parent.y
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

            color: sub2TextColor
            style: Text.Outline
            styleColor: sub2TextOfsetColor
            font.pixelSize: sub2FontSize
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
            Text {
                text: player.position
                color:"white"
            }
            Button { text: "file"; onClicked: fileDialogMedia.open() }
            Button
            {
                text: player.playing ? "pause" : "play";
                onClicked:
                {
                    if(!player.playing)
                    {
                        playVideo()
                    }
                    else
                    {
                        pauseVideo()
                    }


                }
            }
            Button { text: "+15"; onClicked: seekForth()}
            Button { text: "-15"; onClicked: seekBack()}
            Button { text: "sub"; onClicked: popupMessage.open() }
            Column
            {
                width: 150
                height:implicitHeight
                CheckBox
                {
                    id:speedupWhenNoSubtitle
                    checked:false;
                    text:"SNS"
                    onCheckStateChanged:
                    {
                        if(checkState)
                        {
                            player.playbackRate=thePlaybackRate
                        }
                    }
                }

                CheckBox
                {
                    id:removeDomains
                    checked:false;
                    text:"ignore domains"
                }

                CheckBox
                {
                    id:removeHtmlTags
                    checked:false;
                    text:"no html"
                }
            }


            Button
            {
                text: "fillmode";
                onClicked:
                {
                    switch (videoOutput.fillMode)
                    {
                    case VideoOutput.PreserveAspectFit:
                        videoOutput.fillMode = VideoOutput.PreserveAspectCrop;
                        text = "FillMode: PreserveAspectCrop";
                        break;
                    case VideoOutput.PreserveAspectCrop:
                        videoOutput.fillMode = VideoOutput.Stretch;
                        text = "FillMode: Stretch";
                        break;
                    case VideoOutput.Stretch:
                        videoOutput.fillMode = VideoOutput.PreserveAspectFit;
                        text = "FillMode: PreserveAspectFit";
                        break;
                    }
                }
            }
            Button
            {
                text: "fullscreen";
                onClicked:
                {
                    changeWindowFullScreen()
                }
            }
            ComboBox {
                id:audioTrackCombobox
                width:100
                height:50
                model: audioTracksModel
                textRole: "text"
                onActivated: (index) => {
                                 player.activeAudioTrack = audioTracksModel.get(index).index
                             }
                onCurrentIndexChanged:
                {
                    player.activeAudioTrack = audioTracksModel.get(currentIndex).index
                }
            }

            ComboBox {
                id:playRateComboBox
                width:100
                height:50
                model: [{value:0.5},{value:1.0},{value:1.5},{value:2.0},{value:2.5}]
                currentIndex: 1
                textRole: "value"
                onActivated: (index) => {
                                 thePlaybackRate=currentText
                                 player.playbackRate=thePlaybackRate
                             }

            }
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
        FileDialog {
            id: fileDialogMedia
            title: "Choose a media file"
            // folder: StandardPaths.home
            // selectExisting: true
            nameFilters: ["All Files (*)"]

            onAccepted: {
                selectedMediaFilePath = selectedFile
                player.source = selectedMediaFilePath
                player.play()
            }

            onRejected: {
                selectedMediaFilePath=""
                console.log("File selection canceled")
            }
        }
        Timer {
            id: controlsHideTimer
            interval: 3000   // milliseconds to hide after last change
            repeat: false
            running: true
            onTriggered: controls.visible = false
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
                height: volumeIndicator.height * videoArea.volume
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





    function playVideo()
    {
        player.play()
        // dubPlayer.play()
    }
    function pauseVideo()
    {
        player.pause()
        // dubPlayer.pause()
    }

    function seekForth()
    {
        player.position = Math.min(player.position + 15000, player.duration);
        // dubPlayer.position=player.position + dubPlayerOffset
    }
    function seekBack()
    {
        player.position = Math.max(player.position - 15000, 0);
        // dubPlayer.position=player.position + dubPlayerOffset
    }

    function changeWindowFullScreen()
    {
        if (mainWindow.visibility === Window.FullScreen) {
            mainWindow.visibility = Window.Windowed   // Back to normal
        } else {
            mainWindow.visibility = Window.FullScreen  // Go fullscreen
        }
    }

    function showControls()
    {
        controls.visible=true
        controlsHideTimer.running=true
        brightnessOverlay.focus=true
    }

    function loadSubtitle(embedded, subPath,subtitleNo, subIndex)
    {
        if(embedded)
        {
            currentSubtitle = extractor.extractSubtitle(player.source, subIndex)
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
            subtitle1 = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                sub1Index=subIndex
        }

        else
        {
            subtitle2 = Sub.parseSubtitle(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                sub2Index=subIndex
        }

    }

}
