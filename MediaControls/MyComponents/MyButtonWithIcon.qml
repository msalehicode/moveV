import QtQuick
import QtQuick.Controls

Item
{
    id:local_root;
    width: setWidth;
    height: setHeight;
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

    property int setTextMagin: 0
    property string setButtonText: "button";
    property color setButtonFontColor: "yellow";
    property color setButtonBackColor: "purple";
    property color setButtonBorderColor: "red";

    property bool setVisible: true
    property string setIconSource: "";
    property int setIconWidth: 45
    property int setIconHeight: 45
    property int setIconRotation: 0
    property bool setIconFlipHorizontal: false
    property bool setIconFlipVertical: false

    property bool pathFromComponentDire:true

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

    function modifyIcon(source, w = -1, h = -1)
    {
          setIconSource = source;

          if (w !== -1) setIconWidth = w;
          if (h !== -1) setIconHeight = h;
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
            rotation: setIconRotation
            Rectangle
            {
                id:button;
                width:setWidthButtons;
                height:setHeightButtons;
                color:setButtonBackColor;
                border.color:setButtonBorderColor;
                border.width: setButtonsBorderWidth;
                radius: setRadius;


                Image
                {
                    id:image
                    source: pathFromComponentDire ? "../" + setIconSource : setIconSource
                    width: setIconWidth
                    height: setIconHeight
                    // fillMode: Image.PreserveAspectFit
                    visible: setIconSource==="" ? false:true
                    mirrorVertically: setIconFlipVertical
                    mirror: setIconFlipHorizontal
                    anchors
                    {
                        // top:parent.top
                        // horizontalCenter:parent.horizontalCenter
                        centerIn:parent
                    }


                }
                Text
                {

                    text:setButtonText;
                    visible: setButtonText.length>0
                    color:setButtonFontColor;
                    font.bold: true
                    anchors
                    {
                        horizontalCenter:parent.horizontalCenter
                        top:image.bottom
                        topMargin:setTextMagin
                    }
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
        id:loader
        sourceComponent: buttonComponent;
    }
}
