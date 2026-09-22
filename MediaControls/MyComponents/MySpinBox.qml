import QtQuick
import QtQuick.Controls

Item {
    id: local_root

    width: setWidth
    height: setHeight

    property int setWidth: 25
    property int setHeight: 25
    property int setButtonsBorderWidth: 1
    property int setRadius: 10
    property int setWidthButtons: local_root.width
    property int setHeightButtons: local_root.height
    property bool setBold: false
    property bool setVisible: true

    property string setButtonText: "button"
    property color setButtonFontColor: "yellow"
    property color setButtonBackColor: "purple"
    property color setButtonBorderColor: "red"
    property int setButtonFontsize: 12

    signal buttonClicked()
    signal buttonHeld()
    signal buttonReleasesd()

    property var actionHandler: null

    function setActionHandler(passedFunc) {
        actionHandler = (typeof passedFunc === "function") ? passedFunc : null
    }

    function runActionHandler() {
        if (actionHandler) {
            actionHandler()
        }
    }

    Rectangle {
        id: baseButton

        width: local_root.width
        height: local_root.height
        visible: local_root.setVisible
        color: "transparent"

        Rectangle {
            id: button

            width: local_root.setWidthButtons
            height: local_root.setHeightButtons

            color: local_root.setButtonBackColor
            border.color: local_root.setButtonBorderColor
            border.width: local_root.setButtonsBorderWidth
            radius: local_root.setRadius

            Text {
                text: local_root.setButtonText
                anchors.centerIn: parent
                color: local_root.setButtonFontColor
                font.pixelSize: local_root.setButtonFontsize
                font.bold: local_root.setBold
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    local_root.buttonClicked()
                    local_root.runActionHandler()
                }

                onPressAndHold: {
                    local_root.buttonHeld()
                }

                onReleased: {
                    local_root.buttonReleasesd()
                }
            }
        }
    }
}
