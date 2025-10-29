import QtQuick
import QtQuick.Controls

Item
{
    width: setWidth
    height: setHeight

    // Props
    property int currentValue: 50
    property int totalValue: 100
    onCurrentValueChanged: updateProgressModel()
    onTotalValueChanged: updateProgressModel()



    property int repeaterModelCount: Math.max(0, 5 + currentValue)

    property int setWidth: 400
    property int setHeight: 30
    property color setFontColor : "white"
    property color setBgColor: "white"
    property color setProgressColor: "blue"
    property string setSeperatorWord: " of "
    property bool setStatusTotalValueText: true

    property int setFontSize: 15
    property int setCotinainerRadius: 100
    property int setSpacing: 1
    property int setProgressRadius:3

    Rectangle
    {
        anchors.fill: parent
        color: setBgColor
        radius: setCotinainerRadius
        clip:true
        Rectangle
        {
            id: progressBarContainer
            width: parent.width
            height:parent.height
            color:"transparent"
            clip:true
            ListModel
            {
                id: progressModel
            }
            Row
            {
                anchors.fill: parent
                spacing: setSpacing
                anchors
                {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 5
                    rightMargin: 5
                }
                Repeater
                {
                    model: progressModel

                    Rectangle
                    {
                        width: (parent.width - ((totalValue - 1) * setSpacing)) / totalValue
                        height: parent.height/1.10
                        color: model.filled ? setProgressColor : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        radius:setProgressRadius
                    }
                }
            }
        }
        Text
        {
            text: (setStatusTotalValueText) ? (currentValue + setSeperatorWord +  totalValue) : (currentValue + setSeperatorWord)
            color: setFontColor
            font.pixelSize: setFontSize
            font.bold: true
            anchors
            {
                centerIn:parent
            }
        }
    }

    function updateProgressModel()
    {
        progressModel.clear()
        for (var i = 0; i < totalValue; i++)
        {
            progressModel.append({ filled: i < currentValue })
        }
    }

    Component.onCompleted:
    {
        updateProgressModel()
    }
}
