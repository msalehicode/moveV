import QtQuick
import QtQuick.Controls

Item
{
    width:setWidth
    height:setHeight

    //base
    property int setRadius: 10
    property int setWidth: 100
    property int setHeight: 100


    //button
    property string setTitle: "Title:"
    property color setBgColorButton: "red"
    property int setTextFontSize: 15
    property color setTextColor: "white"
    property string setIconArrow: ""
    property bool pathFromComponentDire:true

    //content
    property int setContentHeight: 100
    property bool setOpen : false
    property color setBgContent: "grey"
    default property alias content: contentArea.children //to beable add content/other Components inside this component. like buttons,...


    signal collapsed;

    onSetOpenChanged:
    {
        if(setOpen)
            open();
        else
            close();


        collapsed()

    }

    function open()
    {
        baseContent.visible= true
    }

    function close()
    {
        baseContent.visible= false
    }

    Rectangle
    {
        id:basePanel
        width:parent.width
        height:parent.height
        color:"transparent"
        radius:setRadius
        Column
        {
            width:parent.width
            height:parent.height
            Rectangle
            {
                id:manageButton
                width:parent.width
                height:50
                color: setBgColorButton
                radius:setRadius
                clip:true
                Text
                {
                    id:popupContentText
                    text:setTitle
                    font.pixelSize: setTextFontSize
                    color:setTextColor
                    anchors
                    {
                        verticalCenter:parent.verticalCenter
                        left:parent.left
                        leftMargin:30
                    }

                    width:parent.width/1.75
                    height:implicitHeight
                    wrapMode: Text.WordWrap
                }
                Rectangle
                {
                    id:iconArrowBase
                    color:"transparent"
                    width:40
                    height:40
                    rotation: setOpen ? -90 : 0
                    anchors.right:parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        source: pathFromComponentDire ? "../" + setIconArrow : setIconArrow
                        visible: setIconArrow.length>0 ? true : false
                        anchors.centerIn: parent
                        width:20
                        height:20
                    }
                }
                MouseArea
                {
                    anchors.fill: parent
                    onClicked:
                    {
                        setOpen = !setOpen
                    }
                }
            }



            Rectangle
            {
                id:baseContent
                color:setBgContent
                width: parent.width
                height: setContentHeight
                visible: false
                clip:true
                Item
                {
                    id: contentArea
                    anchors.fill: parent
                }
            }

        }

    }

    Component.onCompleted:
    {
        //to make sure if setOpen is true set right height
        collapsed();
    }

}
