// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import MediaControls
import Config

Item {
    id: root
    anchors.fill: parent
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

            Label {
                text: "Audio Output device:"
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
                        // mediaPlayer.audioOutput.device = modelData //ok
                        // Config.mediaDevicesPtr.audioOutput.device = modelData //error
                        Config.mediaPlayerPtr.audioOutput.device = modelData
                    }
                }
            }

            Label {
                text: "Subtitle 1 Settings:"
                font.bold: true
                font.pixelSize: 15
            }

            CheckBox {
                id: subtitle1Status
                checked: Config.subtitle1DataPtr.subtitleStatus
                text: qsTr("subtitle 1 enable Status")
                leftPadding: indicator.width
                onCheckedChanged: {
                    Config.subtitle1DataPtr.subtitleStatus = checked
                }
            }

            Rectangle {
                width: 200
                height: 200
                color: "transparent"
                visible: subtitle1Status.checked

                Column {
                    anchors.fill: parent
                    CheckBox {
                        id: wordByWordSubtitle1Checkbox
                        checked: Config.subtitle1DataPtr.wordByWordMode
                        text: qsTr("word by word subtitle 1")
                        leftPadding: indicator.width
                        onCheckedChanged: {
                            Config.subtitle1DataPtr.wordByWordMode = checked
                        }
                    }

                    Label {
                        text: "Subtitle 1 wordByWord Chunks:"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle1Checkbox.checked
                    }

                    SpinBox {
                        value: Config.subtitle1DataPtr.wordByWordChunks
                        visible: wordByWordSubtitle1Checkbox.checked
                        onValueChanged: {
                            Config.subtitle1DataPtr.wordByWordChunks = value
                        }
                    }

                    Label {
                        text: "Subtitle 1 font size:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: Config.subtitle1DataPtr.subFontSize
                        onValueChanged: {
                            Config.subtitle1DataPtr.subFontSize = value
                        }
                    }

                    Label {
                        text: "Subtitle 1 offset:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: Config.subtitle1DataPtr.subtitleOffsetMs
                        from: -100
                        to: 100
                        onValueChanged: {
                            Config.subtitle1DataPtr.subtitleOffsetMs = value
                        }
                    }
                }
            }



            Label {
                text: "Subtitle 2 Settings:"
                font.bold: true
                font.pixelSize: 15
            }

            CheckBox {
                id: subtitle2Status
                checked: Config.subtitle2DataPtr.subtitleStatus
                text: qsTr("subtitle 2 enable Status")
                leftPadding: indicator.width
                onCheckedChanged: {
                    Config.subtitle2DataPtr.subtitleStatus = checked
                }
            }

            Rectangle {
                width: 200
                height: 200
                color: "transparent"
                visible: subtitle2Status.checked

                Column {
                    anchors.fill: parent
                    CheckBox {
                        id: wordByWordSubtitle2Checkbox
                        checked: Config.subtitle2DataPtr.wordByWordMode
                        text: qsTr("word by word subtitle 2")
                        leftPadding: indicator.width
                        onCheckedChanged: {
                            Config.subtitle2DataPtr.wordByWordMode = checked
                        }
                    }

                    Label {
                        text: "Subtitle 2 wordByWord Chunks:"
                        font.pixelSize: 12
                        visible: wordByWordSubtitle2Checkbox.checked
                    }

                    SpinBox {
                        value: Config.subtitle2DataPtr.wordByWordChunks
                        visible: wordByWordSubtitle2Checkbox.checked
                        onValueChanged: {
                            Config.subtitle2DataPtr.wordByWordChunks = value
                        }
                    }

                    Label {
                        text: "Subtitle 2 font size:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: Config.subtitle2DataPtr.subFontSize
                        onValueChanged: {
                            Config.subtitle2DataPtr.subFontSize = value
                        }
                    }

                    Label {
                        text: "Subtitle 2 offset:"
                        font.pixelSize: 12
                    }

                    SpinBox {
                        value: Config.subtitle2DataPtr.subtitleOffsetMs
                        from: -100
                        to: 100
                        onValueChanged: {
                            Config.subtitle2DataPtr.subtitleOffsetMs = value
                        }
                    }
                }
            }


        }
    }
}
