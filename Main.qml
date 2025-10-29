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

    SubtitleExtractor
    {
        id: extractor
    }
    SubtitleFinder {
        id: subtitleFinder
    }

    // 0 = normal, 90 = rotated right, 180 = upside down, 270 = rotated left
    property real rotationAngle:  0

    property string selectedFilePath;
    property string currentSubtitle: ""
    property bool autoLoadSubtitles: true

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


    MediaPlayer {
        id: player
        source: "file:///home/mrx/Desktop/s1/The.Big.Bang.Theory.S01E02.720p.BluRay.PaHe.mkv"
        videoOutput: videoOutput
        audioOutput: AudioOutput {}

        onTracksChanged:
        {
            //encounter embedded subtitles
            subtitleModel.clear()
            for (let i = 0; i < subtitleTracks.length; ++i)
            {
                let lang = subtitleTracks[i].stringValue(6) // 6 = language key
                subtitleModel.append({"text": lang ? lang : "Embedded Subtitle " + i, "index": i, "path": "embedded"})
            }

            //encounter subtitle files
            let matches = subtitleFinder.findMatchingSubtitles(player.source)
            if (matches.length > 0) {
                console.log("Possible subtitles found:")
                for (let i = 1; i < matches.length; ++i)
                {
                    // console.log("  " + matches[i])
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



            // console.log("Subtitle tracks:", subtitleTracks.length)
            // for (let i = 0; i < subtitleTracks.length; ++i)
                // console.log(i, subtitleTracks[i].stringValue(6))  // 6 = language key
        }
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
                    subtitleText1.text = Sub.getSubtitleForTime(subtitle1, player.position + subtitle1OffsetMs*1000)

                if(subtitle2Status)
                    subtitleText2.text = Sub.getSubtitleForTime(subtitle2, player.position + subtitle2OffsetMs*1000)
            }
        }
    }

    //subtitle list
    ListModel { id: subtitleModel }


    // Controls
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        Button { text: "Play"; onClicked: player.play() }
        Button { text: "Pause"; onClicked: player.pause() }
        Button { text: "Subtitle"; onClicked: popupMessage.open() }
        Button
        {
            text: "fullscreen";
            onClicked:
            {
                if (mainWindow.visibility === Window.FullScreen) {
                    mainWindow.visibility = Window.Windowed   // Back to normal
                } else {
                    mainWindow.visibility = Window.FullScreen  // Go fullscreen
                }
            }
        }
        Dial {
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
        }
    }

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
                from: -10    // advance up to 10s
                to: 10       // delay up to 10s
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
            selectedFilePath = selectedFile
            loadSubtitle(false, selectedFilePath, chooseSutitle.switchStatus, -1)
        }

        onRejected: {
            selectedFilePath=""
            console.log("File selection canceled")
        }
    }


    // Subtitle overlay
    Rectangle
    {
        width:subtitleText1.width
        height:subtitleText1.height
        color:sub1BackColor
        opacity: sub1BgOpacity
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
        Text {
            id: subtitleText1
            width: implicitWidth
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
        width:subtitleText2.width
        height:subtitleText2.height
        color:sub2BackColor
        opacity: sub2BgOpacity
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
        Text {
            id: subtitleText2
            width: implicitWidth
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




    function loadSubtitle(embedded, subPath,subtitleNo, subIndex)
    {
        if(embedded)
        {
            currentSubtitle = extractor.extractSubtitle(player.source, subIndex)
            console.log("extract subtitle from video=", currentSubtitle)
        }
        else
        {
            if (subPath.startsWith("file://"))
                subPath = subPath.slice(7)

            currentSubtitle = extractor.loadSrtFile(subPath)
        }

        if(subtitleNo)
        {
            subtitle1 = Sub.parseSrt(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                sub1Index=subIndex
        }

        else
        {
            subtitle2 = Sub.parseSrt(currentSubtitle)
            if(subIndex>=0)//loaded from somehwereelse
                sub2Index=subIndex
        }

    }

}
