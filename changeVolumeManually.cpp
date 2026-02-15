// #include <QProcess>
// #include <QObject>

//// pactl set-sink-input-volume 727 50%

// class MediaPlayer : public QObject {
//     Q_OBJECT

// public:
//     MediaPlayer(QObject *parent = nullptr) : QObject(parent) {}

//     // Mute function that uses pactl to mute the app
//     Q_INVOKABLE void muteApp(int sinkInputId) {
//         QString command = QString("pactl set-sink-input-mute %1 1").arg(sinkInputId);
//         QProcess::execute(command);  // Execute the command to mute
//     }

//     // Unmute function that uses pactl to unmute the app
//     Q_INVOKABLE void unmuteApp(int sinkInputId) {
//         QString command = QString("pactl set-sink-input-mute %1 0").arg(sinkInputId);
//         QProcess::execute(command);  // Execute the command to unmute
//     }

//     // You can also add more functions like adjusting volume if needed
// };

