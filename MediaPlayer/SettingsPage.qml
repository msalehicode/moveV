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
                    mediaPlayer.audioOutput.device = modelData
                }
            }
        }
    }
}
