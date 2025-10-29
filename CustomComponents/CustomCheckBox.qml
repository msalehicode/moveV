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

    property bool setVisible:true
    property bool setStatus:false

    //text:
    property string setCheckBoxText: "Checkbox";
    property color setCheckBoxFontColor: "yellow";
    property int setCheckBoxFontsize: 12;
    property bool setBold: false


    //box
    property int setRadius: 10;
    property color setBoxCheckedBackColor: "transparent";
    property color setBoxUncheckBackColor: "transparent";

    property color setBoxCheckedBorderColor: "transparent";
    property color setBoxUncheckedBorderColor: "transparent";
    property int setBoxBorderWidth:1

    property int setWidthBox: 20;
    property int setHeightBox: 20;


    property bool pathFromComponentDire:true
    property string setBoxIconSource:""
    property int setBoxIconWidth:setWidthBox/1.50
    property int setBoxIconHeight:setHeightBox/1.50





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
        id: checkBoxComponent
        Rectangle
        {
            id:baseCheckBox;
            width:local_root.width;
            height:local_root.height;
            color:"transparent";
            visible: setVisible
            Row
            {
                width:parent.width
                height:parent.height
                spacing:5
                Rectangle
                {
                    id:theBox;
                    width:setWidthBox;
                    height:setHeightBox;
                    color: setStatus ? setBoxCheckedBackColor : setBoxUncheckBackColor
                    radius: setRadius;
                    border.color: setStatus ? setBoxCheckedBorderColor : setBoxUncheckedBorderColor
                    border.width: setBoxBorderWidth
                    anchors.verticalCenter:parent.verticalCenter
                    Image
                    {
                        anchors.centerIn: parent
                        visible: setStatus ? true : false
                        source: pathFromComponentDire ? "../" + setBoxIconSource : setBoxIconSource

                        width: setBoxIconWidth
                        height: setBoxIconHeight
                    }
                }
                Text
                {
                    text:setCheckBoxText;
                    width:parent.width
                    height:implicitHeight
                    wrapMode: Text.WordWrap
                    color:setCheckBoxFontColor;
                    font.bold: setBold
                    font.pixelSize: setCheckBoxFontsize
                    anchors.verticalCenter:parent.verticalCenter

                }
            }


            MouseArea
            {
                anchors.fill:parent;
                onClicked:
                {
                    setStatus = !setStatus

                    buttonClicked()
                    runActionHandler()
                }
            }

        }


    }

    Loader
    {
        sourceComponent: checkBoxComponent;
    }
}
