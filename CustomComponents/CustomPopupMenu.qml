import QtQuick
import QtQuick.Controls

Item
{
    width:setWidth
    height:setHeight
    property int setWidth: popupMenu.width
    property int setHeight: popupMenu.height

    property color setBgColor:"white"
    property color setFontColor:"black"
    property color setBgItemColor: "grey"
    property int setFontSize: 15

    property int setHeightItem: 50
    property int setSpacingBetweenItems: 10
    property bool pathFromComponentDire:true

    function open()
    {
        popupMenu.open()
    }

    signal itemClicked(int tid,string iaction,string ttext)



    function openWhereOnClicked(parentName, listName)
    {
        var itemX = parentName.x;
        var itemY = parentName.y;

        var globalX = parentName.mapToItem(listName, Qt.point(itemX, itemY)).x;
        var globalY = parentName.mapToItem(listName, Qt.point(itemX, itemY)).y;

        console.log("Global Position: x = " + globalX + ", y = " + globalY);

        popupMenu.x=globalX//+popupMenu.width/2
        popupMenu.y=globalY+popupMenu.height/2
        open()
    }

    function close()
    {
        popupMenu.close()
    }

    function addItem(itemMessag,itemText,ttid,actionStr,icon,)
    {
        menuModel.append({
                        message: itemMessag+" "+itemText, //+ (menuModel.count + 1),
                        text: itemText,
                        isDynamic:true,
                        tid:ttid,
                        iaction: actionStr,
                        iicon: icon,

                    });
    }

    ListModel {
        id: menuModel
    }
    Menu {
        id: popupMenu
        width: parent.width
        height: implicitHeight
        title: "Menu"

        background: Rectangle
        {
            color: setBgColor
            radius: 10
        }

        onClosed:
        {
            //clear all
            menuModel.clear();

            //remove 2 last items
            // if (menuModel.count > 0)
            // {
            //     menuModel.remove(menuModel.count - 2);
            // }


            //remove those with isDynamic=true
            // for (var i = menuModel.count - 1; i >= 0; i--)
            // {
            //     if (menuModel.get(i).isDynamic)
            //     {
            //         menuModel.remove(i);
            //     }
            // }
        }

        contentItem: Column {
            spacing: setSpacingBetweenItems
            Repeater {
                model: menuModel
                delegate: Rectangle
                {
                    width:parent.width
                    height:setHeightItem
                    color:setBgItemColor
                    Text
                    {
                        id:textItem
                        anchors.centerIn: parent
                        text:model.message
                        color:setFontColor
                        font.pixelSize: setFontSize
                    }
                    Image
                    {
                        source: pathFromComponentDire ? "../"+ model.iicon : model.iicon
                        width:20
                        height:20
                        anchors
                        {
                            right:textItem.left
                            top:textItem.top
                        }
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            itemClicked(model.tid,model.iaction,model.text)
                        }
                    }
                }
            }
        }
    }


}
