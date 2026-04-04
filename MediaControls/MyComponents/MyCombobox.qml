import QtQuick
import QtQuick.Controls

Item {
    width: setWidth
    height: setHeight

    property color setBgColor:"black"
    property color setFontColor:"white"
    property color setBgColorCurrentItem: "red"
    property int setfontSize: 16
    property int setItemsFontSize: 10
    property int setRadius: 20
    property int setWidth: 180
    property int setHeight: 50
    property int setMaxHeightItemsList: 300
    property string setIconArrow: ""

    property string setPositionPopup: "bottom"
    property string currentItemText:modelData[currentIndex].text
    property bool pathFromComponentDire:true

    property int currentIndex: 0
    signal activated(int index)

    property var modelData: [
        { text: "Item 1"},
        { text: "Item 2"},
        { text: "Item 3"},
        { text: "Item 4"},
        { text: "Item 5"},
        { text: "Item 6"}
    ]


    function addItem(itemTitle,itemPayload)
    {
        modelData.push({ text: itemTitle, payload: itemPayload });
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
            id:textItem
            color:"transparent"
            width:setWidth/2
            height:setHeight/2
            clip:true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
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

                    Row{
                        anchors.fill: parent
                        spacing: 5

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
                                anchors.leftMargin:15
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
