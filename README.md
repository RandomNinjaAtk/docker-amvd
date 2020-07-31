# AMVD - Automated Music Video Downloader 

[RandomNinjaAtk/amvd](https://github.com/RandomNinjaAtk/docker-amvd) is a Lidarr Companion script to automatically download and tag Music Videos for use in various media applications

[![RandomNinjaAtk/amvd](https://raw.githubusercontent.com/RandomNinjaAtk/unraid-templates/master/randomninjaatk/img/amvd.png)](https://github.com/RandomNinjaAtk/docker-amvd)


### Video Example (Kodi)
<img src="https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/images/kodi-music-videos.png" width="700px">

## Features
* Downloading **Music Videos** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Support for IMVDb (https://imvdb.com) to find videos
  * Support for Musicbrainz Database (https://musicbrainz.org) to find videos
  * Downloads using Highest available quality for both audio and video
  * Saves thumbnail of video locally for Plex/Kodi/Jellyfin/Emby usage
  * iTunes compatible files, drag and drop iTunes support
  * Optimize files for faststart playback
  * Matching videos with Musicbrainz Artist track info
  * Embed subtitles if available matching desired language
  * Writes metadata into Kodi/Jellyfin/Emby compliant NFO file
    * Tagged Data includes
      * Matched Title (MusicBrainz), fallback to IMVDb or Record Title (MusicBrainz)
      * Matched Year (MusicBrainz)
      * Matched Artist (MusicBrainz)
      * Thumbnail Image
      * Matched Release Genre Tags (MusicBrainz), fallback to Artist Genere Tags (MusicBrainz)
      * Director (If available from IMVDb)      
      * Matched Album (MusicBrainz), fallback to YouTube (If available)
  * Embeds metadata into Music Video file
    * Tagged Data includes
      * Matched Title (MusicBrainz), fallback to IMVDb or Record Title (MusicBrainz)
      * Matched Year (MusicBrainz)
      * Matched Artist (MusicBrainz)
      * Matched Album Artist (MusicBrainz)
      * Thumbnail Image
      * Matched Release Genre Tags (MusicBrainz), fallback to Artist Genere Tags (MusicBrainz)
      * Matched Album (MusicBrainz), fallback to YouTube (If available)


## Supported Architectures

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | amd64-latest |

## Version Tags

| Tag | Description |
| :----: | --- |
| latest | Newest release code |


## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| --- | --- |
| `-p 8686` | Application WebUI |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-v /config` | Configuration files for Lidarr. |
| `-e LIBRARY="/path/to/music-videos"` | Location of music videos, also add a volume to match the location |
| `-e AUTOSTART="true"` | true = Enabled :: Runs script automatically on startup |
| `-e LidarrUrl="http://127.0.0.1:8686"` | Set domain or IP to your Lidarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `-e LidarrAPIkey="08d108d108d108d108d108d108d108d1"` | Lidarr API key. |
| `-e MBRAINZMIRROR="https://musicbrainz.org"` | OPTIONAL :: Only change if using a different mirror |
| `-e MBRATELIMIT=1` | OPTIONAL: musicbrainz rate limit, musicbrainz allows only 1 connection per second, max setting is 10 |
| `-e CountryCode=us` | Set the country code for preferred video matching, uses Musicbrainz Country Codes, lowercase only. |
| `-e RequireVideoMatch=true` | true = enabled :: Only keep videos that could be matched to a Musicbrainz music track. |
| `-e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio[ext=m4a]"` | For guidence, please see youtube-dl documentation |
| `-e subtitlelanguage="en"` | Desired Language Code :: For guidence, please see youtube-dl documentation. |
| `-e videofilter="live"` | This will filter out videos Matching MusicBrainz secondary release type and album disambiguation (single word only) |
| `-e WriteNFOs="false"` | true = enabled :: Create NFO and Local Thumbnail for use in applications such as Kodi |
| `-e FilePermissions=666` | Based on chmod linux permissions |

# Script Information
* Script will automatically run when enabled, if disabled, you will need to manually execute with the following command:
  * From Host CLI: `docker exec -it amvd /bin/bash -c 'bash /config/scripts/download.bash'`
  * From Docker CLI: `bash /config/scripts/download.bash`
  
## Directories:
* <strong>/config/scripts</strong>
  * Contains the scripts that are run
* <strong>/config/logs</strong>
  * Contains the log output from the script
* <strong>/config/cache</strong>
  * Contains the artist data cache to speed up processes
* <strong>/config/coookies</strong>
  * Store your cookies.txt file in this location, may be required for youtube-dl to work properly
  
  
<br />
<br />
<br />
<br />
  
 
 ##### Attribution 
 Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>
