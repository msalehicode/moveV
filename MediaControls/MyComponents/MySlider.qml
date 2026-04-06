import QtQuick
import QtQuick.Controls.Fusion

Item
{
    id:root;
    width:setWidth
    height:setHeight
    visible: setVisible
    anchors.top:parent.top
    anchors.topMargin: setHandleHeight/2 //because hight of handle. make sure it would show whole handle

    property string setColor: "green"
    property int setRadius: 0
    property int setWidth: 300
    property int setHeight: 5
    property real setOpacity: 1
    property bool setVisible: true

    property int setFrom: 0
    property int setTo: 10
    property real setSteps: 1
    property int value:0
    property int intialValue:0


    //handle
    property int setHandleWidth: 20
    property int setHandleHeight: 20
    property int setHandleRadius: 20
    property string setHandleColor: "red"

    //background steps:
    property bool setStepVisible: true
    property int setStepHeight: 10
    property int setStepWidth: 10
    property int setStepRadius: 10
    property string setStepColor: "lime"

    //
    property int setFilledHeight: 11
    property int setFilledLeftRadius: 0
    property int setFilledRightRadius: 0
    property string setFilledColor: "black"


    property bool isHovered: false
    signal modified;
    signal hovered;

    Slider {
        id: slider

        width: parent.width
        height: parent.height
        property alias backgroundColor: backgroundRec.color
        property alias backgroundOpacity: backgroundRec.opacity

        stepSize: root.setSteps

        snapMode: Slider.SnapAlways
        value: root.intialValue
        from: root.setFrom
        to: root.setTo

        background: Rectangle {
            id: backgroundRec
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height:slider.availableHeight
            radius: root.setRadius
            color: root.setColor
            opacity: setOpacity
        }



        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: root.setHandleWidth
            height: root.setHandleHeight
            radius: root.setHandleRadius
            color: root.setHandleColor
        }
        onValueChanged:
        {
            root.value=value
            root.modified()
        }



        Repeater {
            id: stepRepeater
            model: (slider.to - slider.from) / slider.stepSize + 1

            Rectangle {
                visible: root.setStepVisible
                width: root.setStepWidth
                height: root.setStepHeight
                radius: root.setStepRadius
                color: root.setStepColor

                x: slider.leftPadding
                   + (index / (stepRepeater.count - 1)) * (slider.availableWidth - slider.handle.width)
                   + slider.handle.width / 2
                   - width / 2
                y: backgroundRec.height / 2 - height / 2
            }
        }

        Rectangle {
            id:filledValue
            width: slider.visualPosition * slider.availableWidth
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            height: root.setFilledHeight
            color: root.setFilledColor
            radius: root.setFilledRadius
            bottomLeftRadius: root.setFilledLeftRadius
            topLeftRadius: root.setFilledLeftRadius
            topRightRadius: root.setFilledRightRadius
            bottomRightRadius: root.setFilledRightRadius
        }
        HoverHandler
        {
            onHoveredChanged:
            {
                root.isHovered=hovered
                root.hovered()
            }
        }
    }
}
