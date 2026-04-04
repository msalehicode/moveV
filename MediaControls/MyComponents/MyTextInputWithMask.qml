import QtQuick
import QtQuick.Controls

Item
{
    width:setWidth
    height:setHeight
    visible: setVisible

    property int setWidth: 200
    property int setHeight: 50
    property color setBgColor:"black"
    property color setBordercolor: "red"
    property int setBorderWidth:0
    property int setFontSize:15
    property color setFontColor: "white"
    property color setErrorColor:"red"
    property int setRadius:10
    property string setTitleText:""
    property string theText:""
    property string setErrorPrefix: " (Error:"
    property bool setFocus:false
    property string setErrorPosfix: ")"
    property bool setVisible:true
    property int setIntputMask;
    property bool errorStatus:false
    property int setMaxCharacter:5
    signal theTextAccepted;

    signal theTextIsFilledFully;

    function clear()
    {
        theText="";
    }


    function openPhoneKeyboard()
    {
        theTextinput.forceActiveFocus()
        Qt.inputMethod.show()
    }

    function invalidInput(errorText)
    {
        console.log("invalidInput errorText=",errorText)
        //change border color and add error text
        errorStatus = true

        titleText.text = setErrorPrefix+errorText+setErrorPosfix
        titleText.color = setErrorColor
        baseCustomTextInput.border.color = setErrorColor
    }

    onTheTextChanged:
    {
        //revert error colors
        if(errorStatus)
        {
            errorStatus=false
            titleText.text = setTitleText
            titleText.color = setFontColor
            baseCustomTextInput.border.color = setBordercolor
        }
    }

    Rectangle
    {
        id:baseCustomTextInput
        color:setBgColor
        anchors.fill: parent
        radius:setRadius
        border.width: setBorderWidth
        border.color: setBordercolor
        Rectangle
        {
            color:setBgColor
            width: titleText.implicitWidth
            height:10
            visible: titleText.text.length > 0 ? true : false
            anchors
            {
                top:parent.top
                topMargin:-4
                left:parent.left
                leftMargin:15
            }
            Text
            {
                id:titleText
                text:setTitleText
                color: setFontColor
                font.pixelSize: setFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }



        Rectangle
        {
            color:"transparent"
            anchors.fill: parent
            clip:true
            TextInput
            {
                id:theTextinput
                text:theText
                color:setFontColor
                focus: setFocus
                maximumLength: setMaxCharacter
                validator: RegularExpressionValidator
                {
                    regularExpression: /[0-9A-Za-z]+/
                }
                font.pixelSize: setFontSize

                anchors
                {
                    left:parent.left
                    right:parent.right
                    top:parent.top
                    bottom:parent.bottom
                    leftMargin:7
                    topMargin:11
                }
                onTextChanged:
                {
                    theText = text
                    if(length>=setMaxCharacter)
                        theTextIsFilledFully()
                }
                Keys.onReturnPressed:
                {
                    theTextAccepted()
                }

                // onAccepted:
                // {
                //     theTextAccepted()
                // }
            }
        }
    }

}
