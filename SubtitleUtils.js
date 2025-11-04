function parseSrt(srtString) {
    if (!srtString) return [];

    // Remove BOM and trim
    srtString = srtString.replace(/^\uFEFF/, '').trim();

    let entries = [];
    let blocks = srtString.split(/\r?\n\r?\n/);

    for (let block of blocks) {
        let lines = block.split(/\r?\n/).filter(line => line.trim() !== "");

        if (lines.length >= 2 && lines[1].includes(" --> ")) {
            let timeParts = lines[1].split(" --> ");
            if (timeParts.length < 2) continue;

            let startParts = timeParts[0].split(/[:,]/);
            let endParts = timeParts[1].split(/[:,]/);
            if (startParts.length < 4 || endParts.length < 4) continue;

            let startMs = parseInt(startParts[0]) * 3600000 +
                          parseInt(startParts[1]) * 60000 +
                          parseInt(startParts[2]) * 1000 +
                          parseInt(startParts[3]);
            let endMs = parseInt(endParts[0]) * 3600000 +
                        parseInt(endParts[1]) * 60000 +
                        parseInt(endParts[2]) * 1000 +
                        parseInt(endParts[3]);
            let text = lines.slice(2).join("\n");
            entries.push({ start: startMs, end: endMs, text: text });
        }
    }

    return entries;
}


function getSubtitleForTime(subs, timeMs)
{
    for (let i = 0; i < subs.length; i++)
    {
        if (timeMs >= subs[i].start && timeMs <= subs[i].end)
            return subs[i].text;
    }
    return "";
}
