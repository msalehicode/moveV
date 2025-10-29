import QtQuick
import QtQuick.Controls

Item
{
    id: root
    width: setWidth
    height: setHeight

    property int setAnimationDuration: 150
    property int setWidth: 50
    property int setHeight: 40
    property int setRadius: 20
    property color setBgColorActivated: "blue"
    property color setBgColorDeactivated: "grey"


    property bool switchStatus: true

    property int setSwitchBorderWidth: 3
    property int setSwitchWith: 20
    property int setSwitchMargin: 6
    property int setSwitchRadius: 20
    property color setSwitchBorderColor: "transparent"
    property color setSwitchColor: "white"


    signal switchClicked;

    Rectangle {
        id: mySwitsch
        anchors.fill: parent
        radius: setRadius
        color: switchStatus ? setBgColorActivated : setBgColorDeactivated
        border.width: setSwitchBorderWidth
        border.color: setSwitchBorderColor

        Rectangle
        {
            id: switchCircle
            width: setSwitchWith
            height: setSwitchWith
            color: setSwitchColor
            radius: setSwitchRadius
            anchors.verticalCenter: parent.verticalCenter

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

    function setStatus(status)
    {
        if (!status) {
            animationDeactivate.start()
            mySwitsch.color = setBgColorDeactivated
            switchStatus = false
        } else {
            animationActivate.start()
            mySwitsch.color = setBgColorActivated
            switchStatus = true
        }
        // switchClicked()
    }

    function changeStatus()
    {
        if (switchStatus) {
            animationDeactivate.start()
            mySwitsch.color = setBgColorDeactivated
            switchStatus = false
        } else {
            animationActivate.start()
            mySwitsch.color = setBgColorActivated
            switchStatus = true
        }
        switchClicked()
    }
}
