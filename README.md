# moveV
is a fork from Qt6 example MediaPlayer but with **cool features.**

preview:
<img width="1920" height="1080" alt="Screenshot from 2026-02-15 23-49-18" src="https://github.com/user-attachments/assets/57326292-a409-4408-90f6-24a85cc2fc3e" />

## Features Added:
- brightness manager (an overlay to manage brightness)
- SNS (speedup and stop when there is no subtitle) also can set speeup pace and seconds before subtitle e.g: 1s before subtitle make video speed to normal (for those subtitles don't match with actor voice)  
- can set to
    - ignore domains and IDs (advertisements)
    - remote HTML tags
    - clear subtitle positioning from subtitle data.
- hold to speedup (hold mouse Left Click to speedup)
- change volume and brightness via mouse wheel (brightness is on the left side, volume is on the right side)
- manage media by keyboard buttons.
- manage media by handsfree or media keys
  - also can see metadata media and play/pause/next/previous media from notifications system (e.g: gnome shell notification bar)
- change audio output device by select it from available medias on settings
- auto find subtitles (.srt) from selected media living directory (those .srt situated beside .mp4/..)
- auto load matching subtitle (those situated beside media file) pick that most matched for media (episode/season/quality)
- two subtitles for media with separated settings (sync, color, position, font size,..) also can drag subtitles up and down.

## upcoming features:
- manage media and settings via running application on phone by connecting phone to system via bluetooth to manage media from long distance of living room
- connect to server to make lobby and watch movie online with friends from long distance. (just stream control actions)
