import QtQuick
import QtQuick.Controls

Item
{
    id:local_root;
    // anchors.fill: parent;
    width:setWidth
    height:setHeight
    Rectangle
    {
        anchors.fill: parent;
        color:"transparent"
    }
    property int setWidth: 25
    property int setHeight: 25
    property int setButtonsBorderWidth: 1;
    property int setRadius: 10;
    property int setWidthButtons: local_root.width;
    property int setHeightButtons: local_root.height;
    property bool setBold: false
    property bool setVisible:true

    property string setButtonText: "button";
    property color setButtonFontColor: "yellow";
    property color setButtonBackColor: "purple";
    property color setButtonBorderColor: "red";
    property int setButtonFontsize: 12;
    signal buttonClicked;



    //to point to another function/lamda from outside for change clicked behaver multiple time
    property var actionHandler: null

    function setActionHandler(passedFunc)
    {
        actionHandler = (typeof passedFunc === "function") ? passedFunc : null;
    }

    function runActionHandler()
    {
        //check for custom function exists then call it
        if (actionHandler)
        {
               actionHandler()
        }
    }

    Component
    {
        id: buttonComponent
        Rectangle
        {
            id:baseButtons;
            width:local_root.width;
            height:local_root.height;
            color:"transparent";
            visible: setVisible
            Rectangle
            {
                id:button;
                width:setWidthButtons;
                height:setHeightButtons;
                color:setButtonBackColor;
                border.color:setButtonBorderColor;
                border.width: setButtonsBorderWidth;
                radius: setRadius;
                Text
                {
                    text:setButtonText;
                    anchors.centerIn:parent;
                    color:setButtonFontColor;
                    font.pixelSize: setButtonFontsize
                    font.bold: setBold
                }
                MouseArea
                {
                    anchors.fill:parent;
                    onClicked:
                    {
                        buttonClicked()
                        runActionHandler()
                    }
                }
            }

        }


    }

    Loader
    {
        sourceComponent: buttonComponent;
    }
}
