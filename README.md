# moveV
is a fork from Qt6 example MediaPlayer but with **cool features.**
which can be managed from long or short distance depend on connection bluetooth or network by android phone or desktop
#### Remote app: <a href="https://github.com/msalehicode/mediaPlayerRemote"> github repo</a>

## Table of Contents
- [preview](#preview)
- [features](#developed-features)
- [bugs](#bugs)
- [upcoming](#upcoming)



## preview
###### MP4 (2minutes, 10MB):
https://github.com/user-attachments/assets/c70a75a0-df3f-41ca-a2f4-1be553235790

###### GIF (spedup, 1.2MB):
<img width="800" height="450" alt="moveV-preview1 1 3spedup" src="https://github.com/user-attachments/assets/7dfcfd29-4e7a-4974-9fc7-f99dc00f7e13" />

###### MP4 spedup (26s, 5MB):
https://github.com/user-attachments/assets/8f535441-e6b3-46e1-8cf5-d48432a16f3f


## Developed Features
- brightness manager (an overlay to lower brightness)
- SNS (speedup and stop when there is no subtitle) also can set speeup pace and seconds before subtitle e.g: 1s before subtitle make video speed to normal (for those subtitles don't match with actor voice)  
- can active filters for subtitle
    - ignore domains and IDs (advertisements)
    - remote HTML tags
    - clear subtitle positioning from subtitle data.
- hold to speedup (hold mouse Left Click to speedup)
- change volume and brightness via mouse wheel (brightness is on the left side, volume is on the right side)
- manage media by keyboard buttons.
- manage media by handsfree or media keys (for now only linux supported MPRIS)
  - also can see metadata media and play/pause/next/previous media from notifications system (e.g: gnome shell notification bar)
- change audio output device by select it from available medias on settings
- auto find subtitles (.srt) from selected media living directory (those .srt situated beside .mp4/..)
- auto load matching subtitle (those situated beside media file) pick that most matched for media (episode/season/quality)
- two subtitles for media with separated settings (sync/offset , font color, background opacity, font size) also can adjust subtitles Y position up and down over media.
- steady Audio Device: if it's ON => when audio output device changed pause media.
- custom cursor icon over media (to find cursor easier over movie) with your selected custom small icon
- drag & drop media/subtitle into window supported
- click on word to translate (loads a dictionary webpage for that word)
- can set subtitle to word by word mode to show word by word approximate time when actor says that word..
- manage most of features by remote app 
- enable/disable mpris (mediakeys) to control mediplayer or not
- rotate video by dial 0-360 degree
- start hosting over Bluetooth to host for bluetooth remotes. (also it's possible to set it always discoverable or not after a while bluetooth become private and connectable only via direct connection [by entering MAC address bluetooth])
- start hosting over Network to host for nearby/in network remotes
- set password for remotes to prevent unauthenticated access
- see connected remotes and their details such as (remote verison, operation system, address, ping, connection type (Bluetooth or network))
- kick, ban, unban connected remotes
- after a while if user dont send back ping resposne to host, user status would consider as connection-lost and when exceeded than maximum from Config.h would kick that user due to connection lost , this is for when remote's connection has been lost and server have to after a while remove them from connected users.
- at initial remote connection host checks versions compatability if version is outdated or invalid would refuse conenction.

# bugs
- on broken media files, app suicide :)
- sometimes app's volume on system settings goes down
- when media file has high quality it takes too much time to load..

# upcoming
- auto brightness manager (preserve flash bangs at night..)
- auto audio balancing (to balance loud SFX/Musics with actor's speech)
- upgrade ui/ux
- server version to run on VPS (host for long distance connections without port forwarding on Home Network)
- run on android (extract subtitle via FFMPEG)
- 
