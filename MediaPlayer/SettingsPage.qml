// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import MediaControls
import Config

Item {
    id: root


    Column {
        id:columnAudioOutputDevices
        padding: 15
        spacing: 20
        Label{
            text:"Audio Output device:"
            font.bold: true
            font.pixelSize: 15
        }
        ButtonGroup {
            id: groupAudioOutputDevice
        }
        Repeater {
            model: Config.mediaDevicesPtr.audioOutputs
            CustomRadioButton {
                required property var modelData   // this is QAudioDevice

                text: modelData.description
                checked: modelData.isDefault

                ButtonGroup.group: groupAudioOutputDevice
                onClicked: {
                    // mediaPlayer.audioOutput.device = modelData
                    Config.mediaDevicesPtr.audioOutput.device = modelData
                }
            }
        }

        Label{
            text:"Subtitle 1 Settings:"
            font.bold: true
            font.pixelSize: 15
        }
        CheckBox
        {
            checked: Config.subtitle1DataPtr.wordByWordMode
            text: qsTr("word by word subtitle 1")
            leftPadding: indicator.width
            onCheckedChanged:
            {
                Config.subtitle1DataPtr.wordByWordMode = checked
            }
        }
        SpinBox
        {
            value:Config.subtitle1DataPtr.subFontSize
            onValueChanged:
            {
                Config.subtitle1DataPtr.subFontSize = value
            }
        }

        Label{
            text:"Subtitle 2 Settings:"
            font.bold: true
            font.pixelSize: 15
        }
        CheckBox
        {
            checked: Config.subtitle2DataPtr.wordByWordMode
            text: qsTr("word by word subtitle 2")
            leftPadding: indicator.width
            onCheckedChanged:
            {
                Config.subtitle2DataPtr.wordByWordMode = checked
            }
        }

        SpinBox
        {
            value:Config.subtitle2DataPtr.subFontSize
            onValueChanged:
            {
                Config.subtitle2DataPtr.subFontSize = value
            }
        }

    }
}
