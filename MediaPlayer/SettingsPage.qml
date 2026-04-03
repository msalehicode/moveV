// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import MediaControls
import Config
import QtQuick.Dialogs
import "scripts.js" as Scripts

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
                console.log("device is on default. system default audioDevice changed lets obey.")
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
                        console.log("Device (", i ,"): desc:" + device.description + " id:" + device.id + ")");
                        if(device.description === settings.value["App/currentAudioOutput"])
                        {
                            console.log("currentAudioOuput Found: " + device.description);
                            currentDeviceFound=true;
                            break; // Stop searching once found
                        }
                    }


                    if(currentDeviceFound)
                    {
                       console.log("current device found. no worries.")
                    }
                    else
                    {
                        console.log("current device didn't found...")
                        if(Scripts.asBool(settings.value["App/steadyAudioDevice"]))
                        {
                            console.log("a change on devices has been happened video paused due to steadyAudioDevice is ON.");
                            Config.mediaPlayerPtr.pause()
                            return;
                        }
                        else
                        {
                            console.log("steadyAudiodeie is off, switching to default")
                            refreshAudioOutput()
                        }

                    }
                }
                else
                {
                    console.log("MediaDevices or audioOutputs not available.");
                }
            }
        }

    }

    Flickable {
        anchors.fill: parent
        clip:true
        contentWidth: 380
        contentHeight: columnAudioOutputDevices.height  // Optional: Set the height if necessary

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
                    font.bold: true
                    font.pixelSize: 15
                }
                CustomCheckbox
                {
                    id:mprisControlStatus
                    initialCheckedState:  Scripts.asBool(settings.value["App/mprisControl"])
                    theText:"mpris control"
                    // enabled: backend.IsDBusConnectionOk
                    visible: backend.IsDBusConnectionOk
                    onStatusChangeAction:
                    {
                        backend.mprisControl=checked
                        settings.setSetting("App/mprisControl",checked)
                    }
                }
                Label {
                    text: " D-Bus connection failed."
                    color: "red"
                    visible: !backend.IsDBusConnectionOk
                    font.bold: true
                    font.pixelSize: 15
                }
            }


            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Audio Output device:"
                font.bold: true
                font.pixelSize: 15
            }

            CustomCheckbox
            {
                initialCheckedState:  Scripts.asBool(settings.value["App/steadyAudioDevice"])
                theText:"Steady on selected Audio Device"
                onStatusChangeAction:
                {
                    settings.setSetting("App/steadyAudioDevice",checked)
                }
                leftPadding: indicator.width
            }


            ButtonGroup {
                id: groupAudioOutputDevice
            }
            Column {
                CustomRadioButton {
                    text: Config.defaultAudioLabel
                    checked:(
                                Scripts.asBool(settings.value["App/currentAudioOutput"]==="") ||
                                Scripts.asBool(settings.value["App/currentAudioOutput"]===Config.defaultAudioLabel)
                            )

                    ButtonGroup.group: groupAudioOutputDevice
                    onClicked:
                    {
                        console.log("custom audio output selected.")
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
                            console.log("device selected=",modelData.description)
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

                ButtonGroup {
                    id: childGroup
                    exclusive: false
                    checkState: parentBox.checkState
                }

                CustomCheckbox {
                    id: parentBox
                    text: qsTr("check all")
                    checkState: childGroup.checkState
                }


                CustomCheckbox
                {
                    initialCheckedState:  Scripts.asBool(settings.value["Media/sub_removeDomains"])
                    theText:"remove domains"
                    onStatusChangeAction:
                    {
                        settings.setSetting("Media/sub_removeDomains",checked)
                    }
                    leftPadding: indicator.width
                    ButtonGroup.group: childGroup
                }

                CustomCheckbox
                {
                    initialCheckedState:  Scripts.asBool(settings.value["Media/sub_ignoreHTMLtags"])
                    theText:"ignore HTML tags"
                    onStatusChangeAction:
                    {
                        settings.setSetting("Media/sub_ignoreHTMLtags",checked)
                    }
                    leftPadding: indicator.width
                    ButtonGroup.group: childGroup
                }

                CustomCheckbox
                {
                    initialCheckedState:  Scripts.asBool(settings.value["Media/sub_cleanSubtitle"])
                    theText:"clean subtitle"
                    onStatusChangeAction:
                    {
                        settings.setSetting("Media/sub_cleanSubtitle",checked)
                    }
                    leftPadding: indicator.width
                    ButtonGroup.group: childGroup
                }


                CustomCheckbox
                {
                    initialCheckedState:  Scripts.asBool(settings.value["Media/sub_removeExtraInfo"])
                    theText:"remove extrainfo"
                    onStatusChangeAction:
                    {
                        settings.setSetting("Media/sub_removeExtraInfo",checked)
                    }
                    leftPadding: indicator.width
                    ButtonGroup.group: childGroup
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
                CustomCheckbox
                {
                    initialCheckedState:  Scripts.asBool(settings.value["App/customCursorStatus"])
                    theText:"custom cursor status"
                    onStatusChangeAction:
                    {
                        settings.setSetting("App/customCursorStatus",checked)
                    }
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



            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Subtitle 1 Settings:"
                font.bold: true
                font.pixelSize: 15
            }


            CustomCheckbox
            {
                id:subtitle1Status
                initialCheckedState:  Scripts.asBool(settings.value["Subtitle1/status"])
                theText:"subtitle 1 Status"
                onStatusChangeAction:
                {
                    settings.setSetting("Subtitle1/status",checked)
                }
            }


            Rectangle {
                width: 200
                height: 200
                color: "transparent"
                visible: subtitle1Status.checked

                ColorDialog
                {
                    id:sharedColorDialog
                    property string key;
                    onAccepted:
                    {
                        console.log("color accepted key=",key, "selectedColor=",selectedColor)
                        settings.setSetting(key,selectedColor)
                    }
                }

                Column {
                    anchors.fill: parent


                    ComboBox {
                        id: fruitComboBox
                        // Layout.alignment: Qt.AlignHCenter
                        model: foundSubtitles // Assign the data model
                        textRole: "text"  // Specify which property to display
                        valueRole: "id"   // Specify which property to use as the value (optional, defaults to index)
                        onCurrentIndexChanged:
                        {
                            if (currentIndex !== -1) {
                                // Get the data of the selected item from the ListModel
                                var selectedItem = subtitleModel.get(currentIndex);
                                console.log("Selected Index:", selectedItem.index);
                                console.log("Selected Text:", selectedItem.text);
                                console.log("Selected Path:", selectedItem.path);



                            }
                        }
                    }



                    CustomCheckbox
                    {
                        id:wordByWordSubtitle1Checkbox
                        initialCheckedState:  Scripts.asBool(settings.value["Subtitle1/wordByWord"])
                        theText:"word by word"
                        onStatusChangeAction:
                        {
                            settings.setSetting("Subtitle1/wordByWord",checked)
                        }
                    }

                    Label {
                        text: "Subtitle 1 wordByWord Chunks:"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle1Checkbox.checked
                    }

                    SpinBox {
                        value: Scripts.asInt(settings.value["Subtitle1/wordByWordChunks"])
                        visible: wordByWordSubtitle1Checkbox.checked
                        onValueChanged: {
                            settings.setSetting("Subtitle1/wordByWordChunks", value)
                        }
                    }

                    Label {
                        text: "Subtitle 1 font size:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: settings.value["Subtitle1/textSize"]
                        onValueChanged: {
                            settings.setSetting("Subtitle1/textSize", value)
                        }
                    }


                    Label {
                        text: "Subtitle 1 offset:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: settings.value["Subtitle1/offset"]
                        from: -100
                        to: 100
                        onValueChanged: {
                            settings.setSetting("Subtitle1/offset", value)
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



            Rectangle { height: 1; color: "lightgrey"; anchors { right:parent.right; left:parent.left } }
            Label {
                text: "Subtitle 2 Settings:"
                font.bold: true
                font.pixelSize: 15
            }

            CustomCheckbox
            {
                id:subtitle2Status
                initialCheckedState:  Scripts.asBool(settings.value["Subtitle2/status"])
                theText:"subtitle 2 status"
                onStatusChangeAction:
                {
                    settings.setSetting("Subtitle2/status",checked)
                }
            }

            Rectangle {
                width: 200
                height: 200
                color: "transparent"
                visible: subtitle2Status.checked

                Column {
                    anchors.fill: parent
                    CustomCheckbox
                    {
                        id:wordByWordSubtitle2Checkbox
                        initialCheckedState:  Scripts.asBool(settings.value["Subtitle2/wordByWord"])
                        theText:"word by word"
                        onStatusChangeAction:
                        {
                            settings.setSetting("Subtitle2/wordByWord",newStatus)
                        }
                    }

                    Label {
                        text: "wordByWord Chunks:"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle2Checkbox.checked
                    }

                    SpinBox {
                        value: Scripts.asInt(settings.value["Subtitle2/wordByWordChunks"])
                        visible: wordByWordSubtitle2Checkbox.checked
                        onValueChanged: {
                            settings.setSetting("Subtitle2/wordByWordChunks",value)
                        }
                    }

                    Label {
                        text: "text size:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: settings.value["Subtitle2/textSize"]
                        onValueChanged: {
                            settings.setSetting("Subtitle2/textSize",value)
                        }
                    }


                    Label {
                        text: "offset:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: settings.value["Subtitle2/offset"]
                        from: -100
                        to: 100
                        onValueChanged: {
                            settings.setSetting("Subtitle2/offset",value)
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


    // Component.onCompleted:
    // {

    // }
}
