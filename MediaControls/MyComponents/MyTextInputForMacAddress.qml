import QtQuick

Item {
    width:setWidth
    height:setHeight
    property int setWidth: 200
    property int setHeight: 50
    property string enteredAddress:""
    Rectangle
    {
        color:"transparent"
        anchors.fill: parent

        Row
        {
            id:inputRow
            anchors.fill: parent
            spacing: 5
            Repeater
            {
                id:repeater
                model:6
                anchors.horizontalCenter: parent.horizontalCenter
                delegate: CustomTextInputWithMask
                {
                    setWidth:40//parent.width/7
                    setHeight:45//parent.height/1.25
                    setBgColor:"white"
                    setFontColor:"black"
                    setMaxCharacter:2
                    onTheTextIsFilledFully:
                    {
                        var item;
                        var currentIndex=model.index;
                        var i;
                        var finalAddress=""
                        if(currentIndex===5)//put entered values together
                        {
                            for (i = 0; i < repeater.count; i++)
                            {
                                item = repeater.itemAt(i);
                                if (item)
                                {
                                    if(i===0)
                                        finalAddress+=item.theText;
                                    else
                                        finalAddress+=":"+item.theText;
                                }
                                else
                                {
                                    console.log("invalid item repeater to read.")
                                    finalAddress+=":"+ (" " * setMaxCharacter) //put how many max with empty character for this invalid round
                                }
                            }
                            enteredAddress=finalAddress
                        }
                        else //set focus for next input
                        {
                            for (i = currentIndex; i < repeater.count; i++)
                            {
                                item = repeater.itemAt(i);
                                if (item)
                                {
                                    if(item.theText.length<setMaxCharacter)
                                    {
                                        item.setFocus=true
                                        break;
                                    }
                                }
                            }
                        }



                    }
                }
            }
        }


    }
}
