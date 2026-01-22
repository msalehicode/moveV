function parseSubtitle(subString, frameRate = 25) {
    if (!subString || typeof subString !== "string") {
        console.warn("parseSubtitle: invalid input");
        return [];
    }

    subString = subString.replace(/^\uFEFF/, '').trim();
    let entries = [];

    // Detect format
    if (subString.includes('-->')) {
        // ---------- SRT PARSER ----------
        let blocks = subString.split(/\r?\n\r?\n/);
        for (let block of blocks) {
            if (!block.trim()) continue;
            let lines = block.split(/\r?\n/).filter(line => line.trim() !== "");
            if (!lines || lines.length < 2) continue;

            if (lines[1].includes(" --> ")) {
                let [startTime, endTime] = lines[1].split(" --> ");
                if (!startTime || !endTime) continue;

                let startMs = timeStringToMs(startTime);
                let endMs = timeStringToMs(endTime);
                let text = lines.slice(2).join("\n");
                entries.push({ start: startMs, end: endMs, text });
            }
        }
    } else if (/{\d+}{\d+}/.test(subString)) {
        // ---------- SUB (MicroDVD) PARSER ----------
        let lines = subString.split(/\r?\n/);
        for (let line of lines) {
            if (!line.trim()) continue;
            let match = line.match(/{(\d+)}{(\d+)}(.*)/);
            if (match) {
                let startFrame = parseInt(match[1]);
                let endFrame = parseInt(match[2]);
                let text = (match[3] || "").trim().replace(/\|/g, '\n');
                let startMs = (startFrame / frameRate) * 1000;
                let endMs = (endFrame / frameRate) * 1000;
                entries.push({ start: startMs, end: endMs, text });
            }
        }
    } else {
        console.warn("parseSubtitle: unknown subtitle format");
    }

    return entries;
}

function timeStringToMs(timeStr) {
    if (!timeStr) return 0;
    let parts = timeStr.split(/[:,]/);
    if (parts.length < 4) return 0;
    return (
        parseInt(parts[0]) * 3600000 +
        parseInt(parts[1]) * 60000 +
        parseInt(parts[2]) * 1000 +
        parseInt(parts[3])
    );
}

function getSubtitleForTime(subs, timeMs) {
    if (!Array.isArray(subs)) return "";
    for (let i = 0; i < subs.length; i++) {
        if (timeMs >= subs[i].start && timeMs <= subs[i].end)
            return subs[i].text;
    }
    return "";
}
