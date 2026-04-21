// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import MediaControls
import Config
import io.qt.filenameprovider
import "scripts.js" as Scripts

Rectangle {
    id: root

    implicitWidth: 580
    color: Config.mainColor
    border.color: "lightgrey"
    radius: 10

    property int currentIndex: -1
    property bool isShuffled: false
    property alias mediaCount: files.count
    signal playlistUpdated()
    signal currentFileRemoved()
    signal playSelectedIndex();

    function getSource() {
        if (isShuffled && mediaCount > 1) {
            let randomIndex = Math.floor(Math.random() * mediaCount)
            while (randomIndex == currentIndex) {
                randomIndex = Math.floor(Math.random() * mediaCount)
            }
            currentIndex = randomIndex
        }
        return files.get(currentIndex).path
    }

    function addFiles(index, selectedFiles)
    {
        selectedFiles.forEach(function (file)
        {
            if(Scripts.isSupportedFormat(file))
            {
                files.append({
                    path: file,
                    isMovie: Scripts.isMovie(
                        FileNameProvider.getFileName(file.toString())
                    )
                })
                if(!backend.isThereNextTrack)
                    backend.isThereNextTrack=true
            }
            else
                console.warn("file format not supported, file:",file)

        })

        playlistUpdated()
    }

    function addFile(index, selectedFile) {
        if (index > mediaCount || index < 0) {
            index = 0
            currentIndex = 0
        }

        if(Scripts.isSupportedFormat(selectedFile))
        {
            files.insert(index,
                {
                    path: selectedFile,
                    isMovie: Scripts.isMovie(FileNameProvider.getFileName(selectedFile.toString()))
                })
            if(!backend.isThereNextTrack && mediaCount>1)
                backend.isThereNextTrack=true
        }
        else
            console.warn("file format not supported, file:",selectedFile)
    }


    MouseArea {
        anchors.fill: root
        preventStealing: true
    }

    FileDialog {
        id: folderView
        title: qsTr("Add files to playlist")
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: Config.nameFilters
        selectedNameFilter.index: Config.selectedNameFilter
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            root.addFiles(files.count, folderView.selectedFiles)
            close()
        }
    }

    ListModel {
        id: files
    }

    Item {
        id: playlist
        anchors.fill: root
        anchors.margins: 30

        RowLayout {
            id: header
            width: playlist.width

            Label {
                font.bold: true
                font.pixelSize: 20
                text: qsTr("Playlist")
                color: Config.secondaryColor

                Layout.fillWidth: true
            }

            CustomButton {
                icon.source: ControlImages.iconSource("Add_file")
                onClicked: folderView.open()
            }
        }

        ListView {
            id: listView
            model: files
            anchors.fill: playlist
            anchors.topMargin: header.height + 30
            spacing: 20

            delegate: RowLayout {
                id: row
                width: listView.width
                spacing: 15

                required property string path
                required property int index
                required property bool isMovie

                Image {
                    id: mediaIcon

                    states: [
                        State {
                            name: "activeMovie"
                            when: root.currentIndex === row.index && row.isMovie
                            PropertyChanges {
                                mediaIcon.source: Images.iconSource("Movie_Active", false)
                            }
                        },
                        State {
                            name: "inactiveMovie"
                            when: root.currentIndex !== row.index && row.isMovie
                            PropertyChanges {
                                mediaIcon.source: Images.iconSource("Movie_Icon")
                            }
                        },
                        State {
                            name: "activeMusic"
                            when: root.currentIndex === row.index && !row.isMovie
                            PropertyChanges {
                                mediaIcon.source: Images.iconSource("Music_Active", false)
                            }
                        },
                        State {
                            name: "inactiveMusic"
                            when: root.currentIndex !== row.index && !row.isMovie
                            PropertyChanges {
                                mediaIcon.source: Images.iconSource("Music_Icon")
                            }
                        }
                    ]
                }

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.bold: root.currentIndex === row.index
                    color: root.currentIndex === row.index ? Config.highlightColor : Config.secondaryColor
                    font.pixelSize: 18
                    text: {
                        return FileNameProvider.getFileName(row.path)
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            root.currentIndex=row.index
                            playSelectedIndex()
                        }
                    }
                }


                CustomButton {
                    icon.source: ControlImages.iconSource("Trash_Icon")
                    onClicked: {
                        const removedIndex = row.index
                        files.remove(row.index)
                        if (root.currentIndex === removedIndex)
                        {
                            root.currentFileRemoved()
                        }
                        else if (root.currentIndex > removedIndex)
                        {
                            --root.currentIndex
                        }
                    }
                }
            }

            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 400
                }
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 400
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.5
                    to: 1.0
                    duration: 400
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 600
                    easing.type: Easing.OutBounce
                }
            }
        }
    }
}
