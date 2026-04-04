import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: setWidth
    height: setHeight

    property int setAnimationDuration: 150

    property int setWidth: 50
    property int setHeight: 40
    property int setRadius: 20
    property color setBgColor: "grey"


    property string setLeftText:"left text"
    property string setRighttText:"right text"
    property color setFontColor: "black"
    property bool setTexBold:true
    property int setFontSize:15

    property bool switchStatus: false

    property color setSwitchColor: "red"
    property color setSwitchBorderColor: "transparent"
    property int setSwitchBorderWidth: 3
    property int setSwitchMargin: 10
    property real setSwitchOpacity: 0.5 // 50% opacity

    signal switchClicked

    Rectangle {
        id: mySwitsch
        anchors.fill: parent
        radius: setRadius
        color: setBgColor
        border.width: setSwitchBorderWidth
        border.color: setSwitchBorderColor
        Rectangle
        {
            id: leftCircle
            width: mySwitsch.width / 2 - setSwitchMargin * 2
            height: parent.height * 0.7
            anchors
            {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin:setSwitchMargin
            }
            radius: height / 2
            color:"transparent"
            Label
            {
                text:setLeftText
                anchors.centerIn: parent
                color:setFontColor
                font.bold: setTexBold
                font.pixelSize: setFontSize
            }
        }
        Rectangle
        {
            id: rightCircle
            width: mySwitsch.width / 2 - setSwitchMargin * 2
            height: parent.height * 0.7
            anchors
            {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin:setSwitchMargin
            }
            radius: height / 2
            color:"transparent"
            Label
            {
                text:setRighttText
                anchors.centerIn: parent
                color:setFontColor
                font.bold: setTexBold
                font.pixelSize: setFontSize
            }
        }

        Rectangle {
            id: switchCircle
            width: mySwitsch.width / 2 - setSwitchMargin * 2
            height: parent.height * 0.7
            color: setSwitchColor
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            opacity: setSwitchOpacity

            // Initial X position depends on switchStatus:
            x: switchStatus ? (mySwitsch.width - width - setSwitchMargin) : setSwitchMargin
            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                changeStatus()
            }
        }
    }

    // Animation for turning switch ON (circle moves right)
    NumberAnimation {
        id: animationActivate
        target: switchCircle
        property: "x"
        to: mySwitsch.width - switchCircle.width - setSwitchMargin
        duration: setAnimationDuration
    }

    // Animation for turning switch OFF (circle moves left)
    NumberAnimation {
        id: animationDeactivate
        target: switchCircle
        property: "x"
        to: setSwitchMargin
        duration: setAnimationDuration
    }

    // Binding {
    //     target: switchCircle
    //     property: "opacity"
    //     value: setSwitchOpacity
    //     when: root.status === Component.Ready  // or Component.completed
    // }

    function changeStatus() {
        if (switchStatus) {
            animationDeactivate.start()
            switchStatus = false
        } else {
            animationActivate.start()
            switchStatus = true
        }
        switchClicked()
    }
}
