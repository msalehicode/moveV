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
