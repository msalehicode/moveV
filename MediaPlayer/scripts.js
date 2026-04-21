function containsDomain(text) {
    if (!text)
        return false;

    // Regex explanation:
    // 1. Standard domains/URLs (http(s), www, etc.)
    // 2. @username style handles
    // 3. Underscore-prefixed tokens like _com
    var domainRegex = /\b((https?:\/\/)?(www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(\/\S*)?\b|@\w+|\b_[a-zA-Z0-9]+\b/;

    return domainRegex.test(text);
}



function stripHtmlClean(text) {
    if (!text) return "";
    return text
        .replace(/<[^>]+>/g, "")   // remove HTML tags
        .trim();
}


function cleanSubtitleText(text) {
    if (!text) return "";

    return text
        // Remove ASS/SSA override tags like {\pos(...)} {\an8} {\k20}
        .replace(/\{[^}]+\}/g, "")
        // Remove multiple spaces but preserve newlines
        .replace(/[ \t]+/g, " ")
        // Clean spaces after newlines
        .replace(/\n\s+/g, "\n")
        // Trim leading/trailing whitespace
        .trim();
}


function removeExtraInfo(text) {
    if (!text) return "";

    return text
        // Remove ( ... )
        .replace(/\([^)]*\)/g, "")

        // Remove [ ... ]
        .replace(/\[[^\]]*\]/g, "")

        // Remove < ... >
        .replace(/<[^>]*>/g, "")

        // Remove « ... »
        .replace(/«[^»]*»/g, "")

        // // Remove ** ... **
        // .replace(/\*\*[^*]*\*\*/g, "")

        // // Remove - ... -  (only when surrounded by spaces)
        // .replace(/ -[^-]*- /g, " ")

        // // Cleanup extra spaces
        // .replace(/[ \t]+/g, " ")
        // .replace(/\n\s+/g, "\n")
        .trim();
}



function asBool(value) {
    if (typeof value === "boolean")
        return value

    if (typeof value === "number")
        return value !== 0

    if (typeof value === "string") {
        const v = value.trim().toLowerCase()
        if (["true", "1", "yes", "on"].includes(v))
            return true
        if (["false", "0", "no", "off", ""].includes(v))
            return false
    }

    // fallback: anything else → false
    return false
}

function asPath(value) {
    if (value === undefined || value === null)
        return ""

    if (value.toString) {
        var s = value.toString()
        if (s.startsWith("file:///"))
            return s.replace("file://", "")
    }

    // If it's really a QUrl object, try .toLocalFile()
    try {
        if (typeof value.toLocalFile === "function")
            return value.toLocalFile()
    } catch(e) {}

    return String(value)
}


function asFloat(value) {
    if (value === undefined || value === null) return 0.0;

    const num = Number(value);
    return isNaN(num) ? 0.0 : num;
}

function asInt(value)
{
    if (value === undefined || value === null)
        return 0;

    return Number(value)
}


function isSubtitle(fileName)
{
    fileName=String(fileName)
    const supportedSubtitleExtensions = [".srt", ".sub"];
    const extension = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();

    return supportedSubtitleExtensions.includes(extension);
}

function isSupportedFormat(fileName,returnFormat=false)
{
    fileName=String(fileName)
    const supportedVideoExtensions = [".mkv", ".mp4", ".gif", ".avi", ".mov", ".webm"];
    const supportedAudioExtensions = [".mp3", ".wav", ".aac", ".aiff"];
    const extension = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
    if(returnFormat)
        return extension

    return supportedVideoExtensions.includes(extension) || supportedAudioExtensions.includes(extension);
}

function isMovie(path) {
    const paths = path.split('.')
    const extension = paths[paths.length - 1]
    const musicFormats = ["mp3", "wav", "aac", "aiff"]
    for (const format of musicFormats) {
        if (format === extension) {
            return false
        }
    }
    return true
}
