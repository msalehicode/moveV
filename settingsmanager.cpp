#include "settingsmanager.h"


SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
{
    qInfo() << "Settings file location:" << m_settings.fileName();
    loadSettings();
}

SettingsManager::~SettingsManager()
{
    m_settings.sync(); // Explicit sync if needed
}

void SettingsManager::loadSettings()
{
    qInfo() << "Loading settings...";
    m_value.clear();

    // Default values if keys are not found
    if(!m_settings.contains("App/width")) m_settings.setValue("App/width","800");
    if(!m_settings.contains("App/height")) m_settings.setValue("App/height","400");
    if(!m_settings.contains("App/theme")) m_settings.setValue("App/theme","dark");
    if(!m_settings.contains("App/customCursorStatus")) m_settings.setValue("App/customCursorStatus",true);
    if(!m_settings.contains("App/customCursorIconPath")) m_settings.setValue("App/customCursorIconPath","");
    if(!m_settings.contains("App/steadyAudioDevice")) m_settings.setValue("App/steadyAudioDevice",false);
    if(!m_settings.contains("App/currentAudioOutput")) m_settings.setValue("App/currentAudioOutput","");
    if(!m_settings.contains("App/bluetoothHostStatus")) m_settings.setValue("App/bluetoothHostStatus",false);
    if(!m_settings.contains("App/bluetoothHostAlwaysDiscoverable")) m_settings.setValue("App/bluetoothHostAlwaysDiscoverable",false);
    if(!m_settings.contains("App/networkHostStatus")) m_settings.setValue("App/networkHostStatus",false);
    if(!m_settings.contains("App/mprisControl")) m_settings.setValue("App/mprisControl",false);
    if(!m_settings.contains("App/hostPasswordStatus")) m_settings.setValue("App/hostPasswordStatus",false);
    if(!m_settings.contains("App/hostPassword")) m_settings.setValue("App/hostPassword","pass123");
    if(!m_settings.contains("App/showControlsWhenRemoteCommand")) m_settings.setValue("App/showControlsWhenRemoteCommand",true);
    if(!m_settings.contains("App/wordTranslateLanguage")) m_settings.setValue("App/wordTranslateLanguage",true);


    //speedup and stop (SNS)
    if(!m_settings.contains("SNS/secBeforeSpeedup")) m_settings.setValue("SNS/secBeforeSpeedup",1); //x Seconds before subtitle make pace normal. (FOR SNS) (for those subtitles are not shown/matched when actor speak)
    if(!m_settings.contains("SNS/secAfterSpeedup")) m_settings.setValue("SNS/secAfterSpeedup",1);
    if(!m_settings.contains("SNS/speed")) m_settings.setValue("SNS/speed",2);
    if(!m_settings.contains("SNS/status")) m_settings.setValue("SNS/status",false);


    //Media
    if(!m_settings.contains("Media/speedHold")) m_settings.setValue("Media/speedHold",2);
    if(!m_settings.contains("Media/rotationAngle")) m_settings.setValue("Media/rotationAngle",0);
    if(!m_settings.contains("Media/muted")) m_settings.setValue("Media/muted",false);
    if(!m_settings.contains("Media/subtitleTimerInterval")) m_settings.setValue("Media/subtitleTimerInterval",200);
    if(!m_settings.contains("Media/autoLoadSubtitles")) m_settings.setValue("Media/autoLoadSubtitles",true);
    if(!m_settings.contains("Media/volume")) m_settings.setValue("Media/volume",1);
    if(!m_settings.contains("Media/rate")) m_settings.setValue("Media/rate",1);
    if(!m_settings.contains("Media/brightness")) m_settings.setValue("Media/brightness",0);
    if(!m_settings.contains("Media/speed")) m_settings.setValue("Media/speed",1);
    if(!m_settings.contains("Media/sub_removeDomains")) m_settings.setValue("Media/sub_removeDomains",false);
    if(!m_settings.contains("Media/sub_ignoreHTMLtags")) m_settings.setValue("Media/sub_ignoreHTMLtags",false);
    if(!m_settings.contains("Media/sub_cleanSubtitle")) m_settings.setValue("Media/sub_cleanSubtitle",false);
    if(!m_settings.contains("Media/sub_removeExtraInfo")) m_settings.setValue("Media/sub_removeExtraInfo",false);


    //subtitle 1
    if(!m_settings.contains("Subtitle1/status")) m_settings.setValue("Subtitle1/status",true);
    if(!m_settings.contains("Subtitle1/translateWordByClick")) m_settings.setValue("Subtitle1/translateWordByClick",false);
    if(!m_settings.contains("Subtitle1/wordByWord")) m_settings.setValue("Subtitle1/wordByWord",false);
    if(!m_settings.contains("Subtitle1/wordByWordChunks")) m_settings.setValue("Subtitle1/wordByWordChunks",1);
    if(!m_settings.contains("Subtitle1/textColor")) m_settings.setValue("Subtitle1/textColor","yellow");
    if(!m_settings.contains("Subtitle1/backColor")) m_settings.setValue("Subtitle1/backColor","black");
    if(!m_settings.contains("Subtitle1/backOpacity")) m_settings.setValue("Subtitle1/backOpacity",0.5);
    if(!m_settings.contains("Subtitle1/textSize")) m_settings.setValue("Subtitle1/textSize",50);
    if(!m_settings.contains("Subtitle1/posY")) m_settings.setValue("Subtitle1/posY",0.4);
    if(!m_settings.contains("Subtitle1/offset")) m_settings.setValue("Subtitle1/offset",0);


    //subtitle 2
    if(!m_settings.contains("Subtitle2/status")) m_settings.setValue("Subtitle2/status",true);
    if(!m_settings.contains("Subtitle2/translateWordByClick")) m_settings.setValue("Subtitle2/translateWordByClick",false);
    if(!m_settings.contains("Subtitle2/wordByWord")) m_settings.setValue("Subtitle2/wordByWord",false);
    if(!m_settings.contains("Subtitle2/wordByWordChunks")) m_settings.setValue("Subtitle2/wordByWordChunks",1);
    if(!m_settings.contains("Subtitle2/textColor")) m_settings.setValue("Subtitle2/textColor","yellow");
    if(!m_settings.contains("Subtitle2/backColor")) m_settings.setValue("Subtitle2/backColor","black");
    if(!m_settings.contains("Subtitle2/backOpacity")) m_settings.setValue("Subtitle2/backOpacity",0.5);
    if(!m_settings.contains("Subtitle2/textSize")) m_settings.setValue("Subtitle2/textSize",50);
    if(!m_settings.contains("Subtitle2/posY")) m_settings.setValue("Subtitle2/posY",0.8);
    if(!m_settings.contains("Subtitle2/offset")) m_settings.setValue("Subtitle2/offset",0);



    //------------store values in m_value -----

    // Default values if keys are not found
    m_value["App/width"] =  m_settings.value("App/width","800");
    m_value["App/height"] = m_settings.value("App/height","400");
    m_value["App/theme"] = m_settings.value("App/theme","dark");
    m_value["App/customCursorStatus"] = m_settings.value("App/customCursorStatus",true);
    m_value["App/customCursorIconPath"] = m_settings.value("App/customCursorIconPath","");
    m_value["App/steadyAudioDevice"] = m_settings.value("App/steadyAudioDevice",false);
    m_value["App/currentAudioOutput"] = m_settings.value("App/currentAudioOutput","");
    m_value["App/bluetoothHostStatus"] = m_settings.value("App/bluetoothHostStatus",false);
    m_value["App/bluetoothHostAlwaysDiscoverable"] = m_settings.value("App/bluetoothHostAlwaysDiscoverable",false);
    m_value["App/networkHostStatus"] = m_settings.value("App/networkHostStatus",false);
    m_value["App/mprisControl"] = m_settings.value("App/mprisControl",false);
    m_value["App/hostPasswordStatus"] = m_settings.value("App/hostPasswordStatus",false);
    m_value["App/hostPassword"] = m_settings.value("App/hostPassword","pass123");
    m_value["App/showControlsWhenRemoteCommand"] = m_settings.value("App/showControlsWhenRemoteCommand",true);
    m_value["App/wordTranslateLanguage"] = m_settings.value("App/wordTranslateLanguage",true);

    //speedup and stop (SNS)
    m_value["SNS/secBeforeSpeedup"] = m_settings.value("SNS/secBeforeSpeedup",1);
    m_value["SNS/secAfterSpeedup"] = m_settings.value("SNS/secAfterSpeedup",1);
    m_value["SNS/speed"] = m_settings.value("SNS/speed",2);
    m_value["SNS/status"] = m_settings.value("SNS/status",false);

    //Media
    m_value["Media/speedHold"] = m_settings.value("Media/speedHold",2);
    m_value["Media/rotationAngle"] = m_settings.value("Media/rotationAngle",0);
    m_value["Media/muted"] = m_settings.value("Media/muted",false);
    m_value["Media/subtitleTimerInterval"] = m_settings.value("Media/subtitleTimerInterval",200);
    m_value["Media/autoLoadSubtitles"] = m_settings.value("Media/autoLoadSubtitles",true);
    m_value["Media/volume"] = m_settings.value("Media/volume",1);
    m_value["Media/rate"] = m_settings.value("Media/rate",1);
    m_value["Media/brightness"] = m_settings.value("Media/brightness",0);
    m_value["Media/speed"] = m_settings.value("Media/speed",1);
    m_value["Media/sub_removeDomains"] = m_settings.value("Media/sub_removeDomains",false);
    m_value["Media/sub_ignoreHTMLtags"] = m_settings.value("Media/sub_ignoreHTMLtags",false);
    m_value["Media/sub_cleanSubtitle"] = m_settings.value("Media/sub_cleanSubtitle",false);
    m_value["Media/sub_removeExtraInfo"] = m_settings.value("Media/sub_removeExtraInfo",false);

    //subtitle 1
    m_value["Subtitle1/status"] = m_settings.value("Subtitle1/status",true);
    m_value["Subtitle1/translateWordByClick"] = m_settings.value("Subtitle1/translateWordByClick",false);
    m_value["Subtitle1/wordByWord"] = m_settings.value("Subtitle1/wordByWord",false);
    m_value["Subtitle1/wordByWordChunks"] = m_settings.value("Subtitle1/wordByWordChunks",1);
    m_value["Subtitle1/textColor"] = m_settings.value("Subtitle1/textColor","yellow");
    m_value["Subtitle1/backColor"] = m_settings.value("Subtitle1/backColor","black");
    m_value["Subtitle1/backOpacity"] = m_settings.value("Subtitle1/backOpacity",0.5);
    m_value["Subtitle1/textSize"] = m_settings.value("Subtitle1/textSize",50);
    m_value["Subtitle1/posY"] = m_settings.value("Subtitle1/posY",0.4);
    m_value["Subtitle1/offset"] = m_settings.value("Subtitle1/offset",0);


    //subtitle 2
    m_value["Subtitle2/status"] = m_settings.value("Subtitle2/status",true);
    m_value["Subtitle2/translateWordByClick"] = m_settings.value("Subtitle2/translateWordByClick",false);
    m_value["Subtitle2/wordByWord"] = m_settings.value("Subtitle2/wordByWord",false);
    m_value["Subtitle2/wordByWordChunks"] = m_settings.value("Subtitle2/wordByWordChunks",1);
    m_value["Subtitle2/textColor"] = m_settings.value("Subtitle2/textColor","yellow");
    m_value["Subtitle2/backColor"] = m_settings.value("Subtitle2/backColor","black");
    m_value["Subtitle2/backOpacity"] = m_settings.value("Subtitle2/backOpacity",0.5);
    m_value["Subtitle2/textSize"] = m_settings.value("Subtitle2/textSize",50);
    m_value["Subtitle2/posY"] = m_settings.value("Subtitle2/posY",0.8);
    m_value["Subtitle2/offset"] = m_settings.value("Subtitle2/offset",0);

    // qDebug() << "Loaded settings map:" << m_value;
}

QVariantMap SettingsManager::value() const
{
    return m_value;
}

void SettingsManager::setValue(const QVariantMap &settings)
{
    m_value = settings;
}

QString SettingsManager::getValue(const QString &key) const
{
    return getSetting(key,"").toString();
}


void SettingsManager::setSetting(const QString &key, const QVariant &value)
{
    // qDebug() << "setsettings key" << key << "val=" << value ;
    if (!m_value.contains(key) || m_value.value(key) != value)
    {
        if (!key.isEmpty())
        {
            m_value[key] = value;
            m_settings.setValue(key, value);
            // m_settings.sync(); // for immediate write
            qDebug() << "Setting changed and saved:" << key << "=" << value << "to QSettings key" << key;
        }
        else
        {
            qDebug() << "Warning: No QSettings key mapping found for QML setting key:" << key;
            // Optionally, you could store it in QSettings under the same key if it's simple.
            // m_settings.setValue(key, value);
        }

        emit settingChanged(key);
        emit valueChanged();
    }
}

QVariant SettingsManager::getSetting(const QString &key, const QVariant &defaultValue) const
{
    if (m_value.contains(key))
    {
        return m_value.value(key);
    }
    return m_settings.value(key, defaultValue);
}
