import QtQuick
import QtQuick.Controls

Item
{
    width: 200
    height: 100
    anchors.top:parent.top
    anchors.right: parent.right
    anchors.topMargin: 25
    anchors.rightMargin: 25

    property int secondsPassed: 0
    property string timerString: ""


    signal eachTrigger;
    signal timerRunningChanged;

    signal whenPaused;
    signal whenResumed;
    signal whenStarted;
    signal whenStoppped;

    function startTimer()
    {
        timerString="";
        secondsPassed=0;
        timer.running=true
        whenStarted()
    }
    function stopTimer()
    {
        timer.running=false;
        whenStoppped()
    }

    function pauseTimer()
    {
        timer.running=false
        whenPaused()
    }
    function resumeTimer()
    {
        timer.running=true
        whenResumed();
    }

    function status()
    {
        return timer.running
    }



    Timer {
        id: timer
        interval: 1000  // 1 second
        repeat: true
        running: false
        onRunningChanged:
        {
            timerRunningChanged();
        }

        onTriggered: {
            secondsPassed += 1

            // Calculate hours, minutes, seconds
            var hours = Math.floor(secondsPassed / 3600);
            var minutes = Math.floor((secondsPassed % 3600) / 60);
            var seconds = secondsPassed % 60;

            // Format as hh:mm:ss with leading zeros
            timerString = (hours < 10 ? "0" + hours : hours) + ":" +
                          (minutes < 10 ? "0" + minutes : minutes) + ":" +
                          (seconds < 10 ? "0" + seconds : seconds);

            // displayPassedTime.text = "Time passed: " + timerString;
            eachTrigger();
        }
    }

    // Label
    // {
    //     id:displayPassedTime
    //     anchors.centerIn: parent
    //     font.pixelSize: 20
    //     color:"cyan"
    // }
}
