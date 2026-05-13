// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import MediaControls
import Config
import QtQuick.Dialogs
import "scripts.js" as Scripts
import "../MediaControls/MyComponents/"
import MyCommands 1.0
Item {
    id: root
    anchors.fill: parent

    property ListModel foundSubtitles;



    function refreshAudioOutput()
    {
        //refresh repeater model
        repeaterAudioOutputs.model = null
        repeaterAudioOutputs.model = Config.mediaDevicesPtr.audioOutputs
    }

    // function setAudioOutput(device)
    // {
    //     if(device)
    //     {
    //         Config.mediaPlayerPtr.audioOutput.device = device
    //         console.log("setAudioOutput to device=", device)
    //     }
    // }

    function audioOutputDevicesChanged(defaultDev)
    {
        var currentlyCheckedButton = groupAudioOutputDevice.checkedButton;
        if (currentlyCheckedButton)
        {
            if(currentlyCheckedButton.text === Config.defaultAudioLabel)
            {
                refreshAudioOutput()
                console.info("device is on default. system default audioDevice changed lets obey.")
                return;
            }
            else //selected device is not default
            {
                //check for currentDevice avaiablility if wasn't available, decide switch to default or notify
                var currentDeviceFound=false;
                if (Config.mediaDevicesPtr && Config.mediaDevicesPtr.audioOutputs)
                {

                    //list devices, if set a flag if current device found
                    var audioOutputs = Config.mediaDevicesPtr.audioOutputs;
                    for(var i = 0; i < audioOutputs.length; i++)
                    {
                        var device = audioOutputs[i];
                        // console.debug("Device (", i ,"): desc:" + device.description + " id:" + device.id + ")");
                        if(device.description === settings.value["App/currentAudioOutput"])
                        {
                            // console.debug("currentAudioOuput Found: " + device.description);
                            currentDeviceFound=true;
                            break; // Stop searching once found
                        }
                    }


                    if(currentDeviceFound)
                    {
                       console.info("current device found. no worries.")
                    }
                    else
                    {
                        console.info("current device didn't found...")
                        if(Scripts.asBool(settings.value["App/steadyAudioDevice"]))
                        {
                            console.info("a change on devices has been happened video paused due to steadyAudioDevice is ON.");
                            Config.mediaPlayerPtr.pause()
                            return;
                        }
                        else
                        {
                            console.info("steadyAudiodeie is off, switching to default")
                            refreshAudioOutput()
                        }

                    }
                }
                else
                {
                    console.warn("MediaDevices or audioOutputs not available.");
                }
            }
        }

    }

    Flickable {
        anchors.fill: parent
        clip:true
        contentWidth: 380
        contentHeight: 2500//columnAudioOutputDevices.height  // Optional: Set the height if necessary

        Column {
            id: columnAudioOutputDevices
            width: parent.width  // Make sure column takes up full width of flickable area
            padding: 15
            spacing: 20

            Row
            {
                Label {
                    text: "hold to speedup speed:"
                    font.bold: true
                    font.pixelSize: 15
                }
                SpinBox {
                    value: settings.value["Media/speedHold"]
                    onValueChanged: {
                        settings.setSetting("Media/speedHold",value)
                    }
                }
            }

            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }

            Row
            {
                Label {
                    text: "mpris Control:"
                    font.pixelSize: 12
                }
                MySwitch
                {
                    id: mprisControlStatus
                    switchStatus:  Scripts.asBool(settings.value["App/mprisControl"])
                    visible: backend.IsDBusConnectionOk
                    onSwitchClicked: backend.processCommand(Command.MprisControlToggle,switchStatus)
                }
                Label {
                    text: " D-Bus connection failed."
                    color: "red"
                    visible: !backend.IsDBusConnectionOk
                    font.bold: true
                    font.pixelSize: 15
                }
                MyButton
                {
                    setButtonText: "retry"
                    setWidth: 60
                    setHeight: 50
                    setVisible: !backend.IsDBusConnectionOk
                    onButtonClicked:  backend.retryMprisConnection()
                }
            }


            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Audio Output device:"
                font.bold: true
                font.pixelSize: 15
            }

            Label {
                text: "Steady on selected Audio Device"
                font.pixelSize: 12
            }
            MySwitch
            {
                id: steadyOnAudioOutputDevice
                switchStatus:  Scripts.asBool(settings.value["App/steadyAudioDevice"])
                onSwitchClicked: backend.processCommand(Command.SteadyAudioDeviceToggle,switchStatus)
            }


            ButtonGroup {
                id: groupAudioOutputDevice
            }
            Column
            {
                spacing: 5
                CustomRadioButton {
                    text: Config.defaultAudioLabel
                    checked:(
                                Scripts.asBool(settings.value["App/currentAudioOutput"]==="") ||
                                Scripts.asBool(settings.value["App/currentAudioOutput"]===Config.defaultAudioLabel)
                            )

                    ButtonGroup.group: groupAudioOutputDevice
                    onClicked:
                    {
                        // console.debug("custom audio output selected.")
                        settings.setSetting("App/currentAudioOutput","")
                    }
                }
                Repeater {
                    id:repeaterAudioOutputs
                    model: Config.mediaDevicesPtr.audioOutputs
                    CustomRadioButton {
                        required property var modelData// this is QAudioDevice

                        text: modelData.description
                        checked: Scripts.asBool(settings.value["App/currentAudioOutput"]===modelData.description) //modelData.isDefault

                        ButtonGroup.group: groupAudioOutputDevice
                        onClicked: {
                            settings.setSetting("App/currentAudioOutput",modelData.description)
                            // console.debug("device selected=",modelData.description)
                            Config.mediaPlayerPtr.audioOutput.device = modelData
                        }
                    }
                }
            }




            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "subtitle content correction:"
                font.bold: true
                font.pixelSize: 15
            }
            Column {

                Label {
                    text: "remove domains"
                    font.pixelSize: 12
                }
                MySwitch
                {
                    id:subRemoveDomains
                    switchStatus:  Scripts.asBool(settings.value["Media/sub_removeDomains"])
                    onSwitchClicked: backend.processCommand(Command.SubRemoveDomainsToggle,switchStatus)
                }

                Label {
                    text: "ignore HTML tags"
                    font.pixelSize: 12
                }
                MySwitch
                {
                    id:subIgnoreHTML
                    switchStatus:  Scripts.asBool(settings.value["Media/sub_ignoreHTMLtags"])
                    onSwitchClicked: backend.processCommand(Command.SubIgnoreHtmlTagToggle,switchStatus)
                }

                Label {
                    text: "clean subtitle"
                    font.pixelSize: 12
                }
                MySwitch
                {
                    id:subCleanSubtitle
                    switchStatus:  Scripts.asBool(settings.value["Media/sub_cleanSubtitle"])
                    onSwitchClicked: backend.processCommand(Command.SubCleanSubtitleToggle,switchStatus)
                }



                Label {
                    text: "remove ExtraInfo"
                    font.pixelSize: 12
                }
                MySwitch
                {
                    id:subRemoveExtrainfo
                    switchStatus:  Scripts.asBool(settings.value["Media/sub_removeExtraInfo"])
                    onSwitchClicked: backend.processCommand(Command.SubRemoveExtraInfoToggle,switchStatus)
                }
            }



            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Cursor"
                font.bold: true
                font.pixelSize: 15
            }
            Row
            {
                MySwitch
                {
                    id: customCursorStatus
                    switchStatus:  Scripts.asBool(settings.value["App/customCursorStatus"])
                    onSwitchClicked: backend.processCommand(Command.CustomCursorStatusToggle, switchStatus)
                }


                FileDialog {
                    id: customCursorfileDialog
                    // currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
                    nameFilters:
                        [
                        "All Supported Files (*.jpeg *.jpg *.png *.svg)"
                    ]
                    title: qsTr("Please choose a file")
                    onAccepted:
                    {
                        backend.setupCustomCursor(selectedFile,20,20,10,10);
                        settings.setSetting("App/customCursorIconPath",selectedFile)
                    }
                }

                CustomButton {
                    icon.source: ControlImages.iconSource("Add_file")
                    onClicked: customCursorfileDialog.open()
                }

            }


            ColorDialog
            {
                id:sharedColorDialog
                property string key;
                onAccepted:
                {
                    // console.debug("color accepted key=",key, "selectedColor=",selectedColor)
                    var commandCode=0;

                    if(key==="Subtitle1/textColor")
                        commandCode=Command.Subtitle1TextColor;

                    else if(key==="Subtitle1/backColor")
                        commandCode=Command.Subtitle1BackColor;

                    else if(key==="Subtitle2/textColor")
                        commandCode=Command.Subtitle2TextColor;

                    else if(key==="Subtitle2/backColor")
                        commandCode=Command.Subtitle2BackColor;

                    backend.processCommand(commandCode,selectedColor)
                    // settings.setSetting(key,selectedColor)
                }
            }

            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Subtitle 1 Settings:"
                font.bold: true
                font.pixelSize: 15
            }

            Label {
                text: "sub1 status:"
                font.pixelSize: 12
            }
            MySwitch
            {
                id: subtitle1Status
                switchStatus:  Scripts.asBool(settings.value["Subtitle1/status"])
                onSwitchClicked: backend.processCommand(Command.Subtitle1Status, switchStatus)
            }



            Rectangle {
                id:subtitle1MoreBase
                width: 200
                height: 400
                color: "transparent"
                visible: Scripts.asBool(settings.value["Subtitle1/status"])


                Column {
                    anchors.fill: parent

                    Label {
                        text: "sub1 translate word by click:"
                        font.pixelSize: 12
                    }
                    MySwitch
                    {
                        switchStatus:  Scripts.asBool(settings.value["Subtitle1/translateWordByClick"])
                        onSwitchClicked: backend.processCommand(Command.Subtitle1TranslateWordByClick, switchStatus)
                    }

                    Label {
                        text: "sub1 wordByWord:"
                        font.pixelSize: 12
                        visible: subtitle1Status.switchStatus
                    }
                    MySwitch
                    {
                        id: wordByWordSubtitle1Checkbox
                        switchStatus:  Scripts.asBool(settings.value["Subtitle1/wordByWord"])
                        onSwitchClicked: backend.processCommand(Command.Subtitle1WordByWord,switchStatus)
                    }

                    Label {
                        text: "wordByWord Chunks: (" + settings.value["Subtitle1/wordByWordChunks"] + ")"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle1Checkbox.switchStatus
                    }


                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle1/wordByWordChunks"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 10
                            setStepVisible: true
                            setVisible: wordByWordSubtitle1Checkbox.switchStatus
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/wordByWordChunks", value)
                                backend.processCommand(Command.Subtitle1WordByWordChunks, value)
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



                    Label {
                        text: "Subtitle 1 font size: (" + settings.value["Subtitle1/textSize"] + ")"
                        font.pixelSize: 12
                    }

                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle1/textSize"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 200
                            setStepVisible: false
                            onModified: //value changed
                            {
                                backend.processCommand(Command.Subtitle1TextSize, value)
                                // settings.setSetting("Subtitle1/textSize",value)
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




                    Label {
                        text: "Subtitle 1 offset: (" + settings.value["Subtitle1/offset"] + ")"
                        font.pixelSize: 12
                    }

                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle1/offset"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: -50
                            setTo: 50
                            setStepVisible: false
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/offset",value)
                                backend.processCommand(Command.Subtitle1Offset, value)
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


                    Label {
                        text: "Subtitle 1 back opacity: (" + settings.value["Subtitle1/backOpacity"] + ")"
                        font.pixelSize: 12
                    }
                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asFloat(settings.value["Subtitle1/backOpacity"])*10
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 10
                            setStepVisible: true
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/backOpacity",value/10)
                                backend.processCommand(Command.Subtitle1Opacity, value/10)
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

                    Row
                    {
                        Label {
                            text: "text color:"
                            font.pixelSize: 12
                        }
                        CustomButton {
                            icon.source: ControlImages.iconSource("Add_file")
                            onClicked:
                            {
                                sharedColorDialog.key="Subtitle1/textColor"
                                sharedColorDialog.open()
                            }
                        }
                    }

                    Row
                    {
                        Label {
                            text: "back color:"
                            font.pixelSize: 12
                        }
                        CustomButton {
                            icon.source: ControlImages.iconSource("Add_file")
                            onClicked:
                            {
                                sharedColorDialog.key="Subtitle1/backColor"
                                sharedColorDialog.open()
                            }
                        }
                    }

                }
            }




            ///sub2

            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Subtitle 2 Settings:"
                font.bold: true
                font.pixelSize: 15
            }

            Label {
                text: "sub2 status:"
                font.pixelSize: 12
            }
            MySwitch
            {
                id: subtitle2Status
                switchStatus:  Scripts.asBool(settings.value["Subtitle2/status"])
                onSwitchClicked: backend.processCommand(Command.Subtitle2Status, switchStatus)
            }



            Rectangle {
                id:subtitle2MoreBase
                width: 200
                height: 200
                color: "transparent"
                visible: Scripts.asBool(settings.value["Subtitle2/status"])


                Column {
                    anchors.fill: parent

                    Label {
                        text: "sub2 translate word by click:"
                        font.pixelSize: 12
                    }
                    MySwitch
                    {
                        switchStatus:  Scripts.asBool(settings.value["Subtitle2/translateWordByClick"])
                        onSwitchClicked: backend.processCommand(Command.Subtitle2TranslateWordByClick, switchStatus)
                    }

                    Label {
                        text: "sub2 wordByWord:"
                        font.pixelSize: 12
                        visible: subtitle2Status.switchStatus
                    }
                    MySwitch
                    {
                        id: wordByWordSubtitle2Checkbox
                        switchStatus:  Scripts.asBool(settings.value["Subtitle2/wordByWord"])
                        onSwitchClicked: backend.processCommand(Command.Subtitle2WordByWord,switchStatus)
                    }

                    Label {
                        text: "wordByWord Chunks: (" + settings.value["Subtitle2/wordByWordChunks"] + ")"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle2Checkbox.switchStatus
                    }


                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle2/wordByWordChunks"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 10
                            setStepVisible: true
                            setVisible: wordByWordSubtitle2Checkbox.switchStatus
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/wordByWordChunks", value)
                                backend.processCommand(Command.Subtitle2WordByWordChunks, value)
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



                    Label {
                        text: "Subtitle 2 font size: (" + settings.value["Subtitle2/textSize"] + ")"
                        font.pixelSize: 12
                    }

                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle2/textSize"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 200
                            setStepVisible: false
                            onModified: //value changed
                            {
                                backend.processCommand(Command.Subtitle2TextSize, value)
                                // settings.setSetting("Subtitle1/textSize",value)
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




                    Label {
                        text: "Subtitle 2 offset: (" + settings.value["Subtitle2/offset"] + ")"
                        font.pixelSize: 12
                    }

                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asInt(settings.value["Subtitle2/offset"])
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: -50
                            setTo: 50
                            setStepVisible: false
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/offset",value)
                                backend.processCommand(Command.Subtitle2Offset, value)
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


                    Label {
                        text: "Subtitle 2 back opacity: (" + settings.value["Subtitle2/backOpacity"] + ")"
                        font.pixelSize: 12
                    }
                    Rectangle
                    {
                        width: 200
                        height: 50
                        color:"transparent"
                        MySlider
                        {
                            setWidth: 200
                            setHeight: 10
                            setFilledColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setColor: !Config.activeTheme ? "white" : Config.highlightColor
                            setOpacity: !Config.activeTheme ? 0.8 : 0.5
                            intialValue: Scripts.asFloat(settings.value["Subtitle2/backOpacity"])*10
                            setFilledLeftRadius: 30
                            setRadius: 30
                            setFrom: 1
                            setTo: 10
                            setStepVisible: true
                            onModified: //value changed
                            {
                                // settings.setSetting("Subtitle1/backOpacity",value/10)
                                backend.processCommand(Command.Subtitle2Opacity, value/10)
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

                    Row
                    {
                        Label {
                            text: "text color:"
                            font.pixelSize: 12
                        }
                        CustomButton {
                            icon.source: ControlImages.iconSource("Add_file")
                            onClicked:
                            {
                                sharedColorDialog.key="Subtitle2/textColor"
                                sharedColorDialog.open()
                            }
                        }
                    }

                    Row
                    {
                        Label {
                            text: "back color:"
                            font.pixelSize: 12
                        }
                        CustomButton {
                            icon.source: ControlImages.iconSource("Add_file")
                            onClicked:
                            {
                                sharedColorDialog.key="Subtitle2/backColor"
                                sharedColorDialog.open()
                            }
                        }
                    }

                }
            }


        }
    }

    Connections
    {
        target: backend
        onMediaPlayerDataChange: function (cmd, payload)
        {
            switch(cmd)
            {
                case Command.Subtitle1WordByWord: wordByWordSubtitle1Checkbox.changeStatus(Scripts.asBool(payload)); break;
                case Command.Subtitle1Status:
                {
                    var val = Scripts.asBool(payload)
                    subtitle1Status.changeStatus(val)
                    subtitle1MoreBase.visible=val
                }break;

                case Command.Subtitle2WordByWord: wordByWordSubtitle2Checkbox.changeStatus(Scripts.asBool(payload)); break;
                case Command.Subtitle2Status:
                {
                    var val = Scripts.asBool(payload)
                    subtitle2Status.changeStatus(val)
                    subtitle2MoreBase.visible=val
                }break;

                case Command.SubRemoveDomainsToggle:
                    subRemoveDomains.changeStatus(Scripts.asBool(payload))
                    break;
                case Command.SubIgnoreHtmlTagToggle:
                    subIgnoreHTML.changeStatus(Scripts.asBool(payload))
                    break;
                case Command.SubCleanSubtitleToggle:
                    subCleanSubtitle.changeStatus(Scripts.asBool(payload))
                    break;
                case Command.SubRemoveExtraInfoToggle:
                    subRemoveExtrainfo.changeStatus(Scripts.asBool(payload))
                    break;



                case Command.MprisControlToggle:
                    mprisControlStatus.changeStatus(Scripts.asBool(payload))
                    break;

                case Command.CustomCursorStatusToggle:
                    customCursorStatus.changeStatus(Scripts.asBool(payload))
                    break;


            }
        }
    }

    // Component.onCompleted:
    // {

    // }
}
