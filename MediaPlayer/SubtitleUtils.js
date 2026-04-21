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

function getSubtitleForTime(subs, timeMs)
{
    if (!Array.isArray(subs)) return "";
    for (let i = 0; i < subs.length; i++) {
        if (timeMs >= subs[i].start && timeMs <= subs[i].end)
            return subs[i].text;
    }
    return "";
}


function getSubtitleEntry(subs, timeMs) {
    if (!Array.isArray(subs)) return null;
    for (let i = 0; i < subs.length; i++) {
        if (timeMs >= subs[i].start && timeMs <= subs[i].end)
            return subs[i];
    }
    return null;
}



function giveWordByWordSubtitle(data, subtitleOffsetMs, wordByWordChunks ,mediaPlayerPosition, duration = 2000)
{
    const offsetInMs = subtitleOffsetMs * 1000;
    const effectivePlayerPosition = mediaPlayerPosition + offsetInMs; // Time used for subtitle lookup and elapsed calculation

    // Detect subtitle change
    // This condition might need refinement if the offset causes subtitles to appear/disappear
    // prematurely relative to the *actual* mediaPlayerPosition.
    // A better trigger might be checking if the *current* subtitle text has changed,
    // regardless of the offset's effect on timing.
    // For now, let's assume data.currentSubtitle reflects the correct text for effectivePlayerPosition.
    if (data.currentSubtitle !== data.lastSubtitle) {
        data.lastSubtitle = data.currentSubtitle;
        data.wordIndex = 0; // Reset word index when subtitle text changes

        if (data.currentSubtitle === "") {
            data.wordList = [];
        } else {
            var lines = data.currentSubtitle.split(/\n+/);
            data.wordList = [];
            for (var i = 0; i < lines.length; i++) {
                var words = lines[i].trim().split(/\s+/);
                for (var w = 0; w < words.length; w++) {
                    if (words[w] !== "") {
                        data.wordList.push(words[w]);
                    }
                }
            }

            // GET SUBTITLE TIMING using the *effective* player position
            var entry = getSubtitleEntry(
                data.subtitle,
                effectivePlayerPosition // <-- Use effective position for lookup
            );

            if (entry) {
                // Store the start and end times of the FOUND entry.
                // These define the duration for the current subtitle text.
                data.subtitleStart = entry.start;
                data.subtitleEnd = entry.end;
                data.subtitleDuration = data.subtitleEnd - data.subtitleStart;
                // Ensure duration is not negative or zero if start/end are bad
                if (data.subtitleDuration <= 0) {
                    data.subtitleDuration = duration; // Fallback to default
                    data.subtitleStart = effectivePlayerPosition - duration/2; // Try to center it loosely
                }
            } else {
                // Fallback: If no entry found at the effective position,
                // use the effective position as the reference start and a default duration.
                data.subtitleStart = effectivePlayerPosition;
                data.subtitleDuration = duration;
            }
        }
    }

    // No subtitle → clear
    if (data.currentSubtitle === "") {
        return "";
    }

    // CALCULATE ELAPSED TIME
    // Calculate elapsed time based on the *effective* player position
    // relative to the determined start time of the current subtitle.
    var elapsed = effectivePlayerPosition - data.subtitleStart; // <-- Use effective position
    if (elapsed < 0) elapsed = 0;

    // Ensure elapsed time does not exceed the subtitle's duration
    if (data.subtitleDuration > 0 && elapsed > data.subtitleDuration) {
        elapsed = data.subtitleDuration;
    } else if (data.subtitleDuration <= 0) {
        // Handle potential issues with duration calculation from entry
        elapsed = 0; // Or potentially clamp to 'duration' if that makes more sense
    }


    // Progress calculation remains the same, using elapsed and duration
    var progress = data.subtitleDuration > 0 ? (elapsed / data.subtitleDuration) : 0;

    var totalWords = data.wordList.length;
    if (totalWords === 0) return "";

    // Current word position based on progress
    var currentWordIndex = Math.floor(progress * totalWords);

    // Clamp index to the last word if progress reaches 100%
    if (currentWordIndex >= totalWords) {
        currentWordIndex = totalWords - 1;
    }
    // Ensure index is not negative
    if (currentWordIndex < 0) {
        currentWordIndex = 0;
    }


    // Determine block index (prevents overlapping)
    var blockIndex = Math.floor(currentWordIndex / wordByWordChunks);

    var startIndex = blockIndex * wordByWordChunks;
    var endIndex = Math.min(startIndex + wordByWordChunks, totalWords);

    // Ensure startIndex is not greater than endIndex (can happen if totalWords is 0 or due to rounding)
    if (startIndex >= totalWords) {
        return ""; // No words to show
    }
    if (startIndex > endIndex) {
        endIndex = startIndex; // Should not happen with Math.min, but as a safeguard
    }


    var wordsToShow = data.wordList.slice(startIndex, endIndex);

    return wordsToShow.join(" ");
}
