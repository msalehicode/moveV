import QtQuick
import QtQuick.Controls

Item {
    width: setWidth
    height: setHeight

    property color setBgColor:"black"
    property color setFontColor:"white"
    property color setBgColorCurrentItem: "red"
    property int setfontSize: 16
    property int setRadius: 20
    property int setWidth: 180
    property int setHeight: 50
    property int setMaxHeightItemsList: 300
    property string setIconArrow: ""
    property string currentItemText:modelData[currentIndex].text
    property bool pathFromComponentDire:true

    property string setPositionPopup: "bottom"


    property int currentIndex: 0
    signal activated(int index)


    property var modelData: [
        { text: "Item 1", icon: appIcons.icon_question },
        { text: "Item 2", icon: appIcons.icon_streak},
        { text: "Item 3", icon: appIcons.icon_streak},
        { text: "Item 4", icon: appIcons.icon_streak},
        { text: "Item 5", icon: appIcons.icon_streak},
        { text: "Item 6", icon: appIcons.icon_check }
    ]

    function addItem(itemTitle,itemIcon)
    {
        modelData.push({ text: itemTitle, icon: itemIcon });
        theListview.model = [];
        theListview.model = modelData;
    }

    Rectangle {
        id: baseCombobox
        anchors.fill: parent
        color:setBgColor
        radius:setRadius


        Rectangle
        {
            id:iconItem
            color:"transparent"
            width:30
            height:30
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            Image {
                source: pathFromComponentDire ? "../" + modelData[currentIndex].icon : modelData[currentIndex].icon
                anchors.fill: parent
            }
        }


        Rectangle
        {
            id:textItem
            color:"transparent"
            width:setWidth/2
            height:setHeight/2
            clip:true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: iconItem.right
            anchors.leftMargin: 10
            Text
            {
                text:modelData[currentIndex].text
                color:setFontColor
                font.pixelSize: setfontSize
            }
        }







        Rectangle
        {
            id:iconFlashCombobox
            color:"transparent"
            width:40
            height:40
            rotation: -90
            anchors.right:parent.right
            anchors.verticalCenter: parent.verticalCenter
            Image {
                source: pathFromComponentDire ? "../" + setIconArrow : setIconArrow
                anchors.centerIn: parent
                width:20
                height:20
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked:
            {
                iconFlashCombobox.rotation=90
                popup.open()
            }
        }
    }

    Popup {
        id: popup
        x: baseCombobox.x -5
        y: (setPositionPopup==="center"? baseCombobox.y - baseCombobox.height -5
                                      : (setPositionPopup==="bottom"? baseCombobox.y + baseCombobox.height -5
                                                                    : baseCombobox.y - baseCombobox.height *3.50 ))
        width: baseCombobox.width
        height: Math.min(modelData.length * setHeight, setMaxHeightItemsList) // max height
        modal: true
        focus: true

        background: Rectangle {
            color: "transparent"
        }
        onClosed:
        {
            iconFlashCombobox.rotation=-90
        }

        Rectangle
        {
            width: baseCombobox.width
            color: setBgColor
            height: Math.min(modelData.length * setHeight, setMaxHeightItemsList) // max height
            radius: setRadius
            clip:true
            ListView {
                id:theListview
                anchors.fill: parent
                model: modelData
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                anchors.margins: 2

                delegate: Rectangle {
                    width: parent.width
                    height: setHeight
                    color: index === currentIndex ? setBgColorCurrentItem : setBgColor
                    radius: setRadius

                    Row {
                        anchors.fill: parent
                        spacing: 5

                        Rectangle
                        {
                            id:iconItem_onList
                            color:"transparent"
                            width:30
                            height:30
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            Image {
                                source: pathFromComponentDire ? "../" +  modelData.icon :  modelData.icon
                                anchors.fill: parent
                            }
                        }

                        Rectangle
                        {
                            id:textItem_onList
                            color:"transparent"
                            width:setWidth
                            height:setHeight/2
                            anchors.verticalCenter: parent.verticalCenter
                            clip:true
                            Text
                            {
                                text:modelData.text
                                color:setFontColor
                                font.pixelSize: setfontSize
                                anchors.left: parent.left
                                anchors.leftMargin:35
                            }
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:
                        {
                            activated(index)
                            popup.close()

                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }



            }

        }


    }




}
