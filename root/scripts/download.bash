#!/usr/bin/with-contenv bash
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
agent="automated-music-video-downloader ( https://github.com/RandomNinjaAtk/docker-amvd )"

Configuration () {
	processstartid="$(ps -A -o pid,cmd|grep "start.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	processdownloadid="$(ps -A -o pid,cmd|grep "download.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	log "To kill script, use the following command:"
	log "kill -9 $processstartid"
	log "kill -9 $processdownloadid"
	log ""
	log ""
	sleep 2
	log "############################################ $TITLE"
	log "############################################ SCRIPT VERSION 1.1.43"
	log "############################################ DOCKER VERSION $VERSION"
	log "############################################ CONFIGURATION VERIFICATION"
	error=0

	if [ "$AUTOSTART" == "true" ]; then
		log "$TITLESHORT Script Autostart: ENABLED"
		if [ -z "$SCRIPTINTERVAL" ]; then
			log "WARNING: $TITLESHORT Script Interval not set! Using default..."
			SCRIPTINTERVAL="15m"
		fi
		log "$TITLESHORT Script Interval: $SCRIPTINTERVAL"
	else
		log "$TITLESHORT Script Autostart: DISABLED"
	fi

	# Verify Musicbrainz DB Connectivity
	musicbrainzdbtest=$(curl -s -A "$agent" "${MBRAINZMIRROR}/ws/2/artist/f59c5520-5f46-4d2c-b2c4-822eabf53419?fmt=json")
	musicbrainzdbtestname=$(echo "${musicbrainzdbtest}"| jq -r '.name')
	if [ "$musicbrainzdbtestname" != "Linkin Park" ]; then
		log "ERROR: Cannot communicate with Musicbrainz"
		log "ERROR: Expected Response \"Linkin Park\", received response \"$musicbrainzdbtestname\""
		log "ERROR: URL might be Invalid: $MBRAINZMIRROR"
		log "ERROR: Remote Mirror may be throttling connection..."
		log "ERROR: Link used for testing: ${MBRAINZMIRROR}/ws/2/artist/f59c5520-5f46-4d2c-b2c4-822eabf53419?fmt=json"
		log "ERROR: Please correct error, consider using official Musicbrainz URL: https://musicbrainz.org"
		error=1
	else
		log "Musicbrainz Mirror Valid: $MBRAINZMIRROR"
		if echo "$MBRAINZMIRROR" | grep -i "musicbrainz.org" | read; then
			if [ "$MBRATELIMIT" != 1 ]; then
				MBRATELIMIT="1.5"
			fi
			log "Musicbrainz Rate Limit: $MBRATELIMIT (Queries Per Second)"
		else
			log "Musicbrainz Rate Limit: $MBRATELIMIT (Queries Per Second)"
			MBRATELIMIT="0$(echo $(( 100 * 1 / $MBRATELIMIT )) | sed 's/..$/.&/')"
		fi
	fi

	# verify downloads location
	if [ -d "/downloads-amvd" ]; then
		LIBRARY="/downloads-amvd"
		log "Music Video Library Location: $LIBRARY"
	else
		if [ ! -z "$LIBRARY" ]; then
			log "Music Video Library Location: $LIBRARY"
			if [ ! -d "$LIBRARY" ]; then
				log "ERROR: LIBRARY setting invalid, currently set to: $LIBRARY"
				log "ERROR: The LIBRARY Folder does not exist, create the folder accordingly to resolve error"
				log "HINT: Check the path using the container CLI to verify it exists, command: ls \"$LIBRARY\""
				error=1
			fi
		else
			log "ERROR: Music Video Library Location Not Found! (/downloads-amvd)"
			log "ERROR: To correct error, please add a \"/downloads-amvd\" volume"
			error=1
		fi
	fi

	if [[ "$SOURCE_CONNECTION" != "lidarr" && "$SOURCE_CONNECTION" != "ama" ]]; then
		log "ERROR :: SOURCE_CONNECTION not configured"
		log "ERROR :: Set SOURCE_CONNECTION to \"lidarr\" or \"ama\""
		error=1
	fi

	if [ "$SOURCE_CONNECTION" == "ama" ]; then
		log "Music Video Artist List Source: $SOURCE_CONNECTION"
		if [ ! -d "/ama/list" ]; then
			log "ERROR :: AMA List folder not found (/ama/list)"
			log "ERROR :: To correct, mount AMA config folder as \"/ama\" volume"
			error=1
		fi
	fi

	if [ "$SOURCE_CONNECTION" == "lidarr" ]; then
		log "Music Video Artist List Source: $SOURCE_CONNECTION"

		# Verify Lidarr Connectivity
		lidarrtest=$(curl -s "$LidarrUrl/api/v1/system/status?apikey=${LidarrAPIkey}" | jq -r ".version")
		if [ ! -z "$lidarrtest" ]; then
			if [ "$lidarrtest" != "null" ]; then
				log "Music Video Source: Lidarr Connection Valid, version: $lidarrtest"
			else
				log "ERROR: Cannot communicate with Lidarr, most likely a...."
				log "ERROR: Invalid API Key: $LidarrAPIkey"
				error=1
			fi
		else
			log "ERROR: Cannot communicate with Lidarr, no response"
			log "ERROR: URL: $LidarrUrl"
			log "ERROR: API Key: $LidarrAPIkey"
			error=1
		fi
	fi


	# Country Code
	if [ ! -z "$CountryCode" ]; then
		log "Music Video Country Code: $CountryCode"
	else
		log "ERROR: CountryCode is empty, please configure wtih a valid Country Code (lowercase)"
		error=1
	fi

	# RequireVideoMatch
	if [ "$RequireVideoMatch" = "true" ]; then
		log "Music Video Require Match: ENABLED"
	else
		log "Music Video Require Match: DISABLED"
	fi

	# videoformat
	if [ ! -z "$videoformat" ]; then
		log "Music Video Format Set To: $videoformat"
	fi

	# videofilter
	if [ ! -z "$videofilter" ]; then
		log "Music Video Filter: ENABLED ($videofilter)"
	else
		log "Music Video Filter: DISABLED"
	fi

	# subtitlelanguage
	if [ ! -z "$subtitlelanguage" ]; then
		subtitlelanguage="${subtitlelanguage,,}"
		log "Music Video Subtitle Language: $subtitlelanguage"
	else
		subtitlelanguage="en"
		log "Music Video Subtitle Language: $subtitlelanguage"
	fi

	if [ "$WriteNFOs" == "true" ]; then
		log "Music Video NFO Writer: ENABLED"
	else
		log "Music Video NFO Writer: DISABLED"
	fi

	if [ ! -z "$USEFOLDERS" ]; then
		if [ "$USEFOLDERS" == "true" ]; then
			log "Music Video Use Folders: ENABLED"
			if [ ! -z "$FolderPermissions" ]; then
				log "Music Video Foldder Permissions: $FolderPermissions"
			fi
			if [ "$USEVIDEOFOLDERS" == "true" ]; then
				log "Music Video Use Video Folders: ENABLED"
			else
				log "Music Video Use Video Folders: DISABLED"
			fi
		else
			log "Music Video Use Folders: DISABLED"
		fi
	else
		log "WARNING: USEFOLDERS not set, using default..."
		USEFOLDERS="false"
		log "Music Video Use Folders:: DISABLED"
	fi

	if [ ! -z "$FilePermissions" ]; then
		log "Music Video File Permissions: $FilePermissions"
	fi

	if [ $error = 1 ]; then
		log "Please correct errors before attempting to run script again..."
		log "Exiting..."
		exit 1
	fi
	sleep 5
}

CacheEngine () {

	if [ -d "/config/temp" ]; then
		rm -rf "/config/temp"
	fi
		
		artistImvdbUrl=$(echo $artistdata | jq -r '.links[] | select(.name=="imvdb") | .url')
		

		LidArtistNameCap="$(echo "${artistdata}" | jq -r " .artistName")"
		artistnamepath="$(echo "${artistdata}" | jq -r " .path")"
		sanitizedartistname="$(basename "${artistnamepath}" | sed 's% (.*)$%%g')"
		if  [ "$LidArtistNameCap" == "Various Artists" ]; then
			log "$artistnumber of $artisttotal :: $LidArtistNameCap :: MBZDB CACHE :: Skipping, not processed by design..."
			return
		fi			

		if [ ! -f "/config/cache/$sanitizedartistname-$mbid-info.json" ]; then
			log "$artistnumber of $artisttotal :: $LidArtistNameCap :: MBZDB CACHE :: Caching Musicbrainz Artist Info..."
			curl -s -A "$agent" "${MBRAINZMIRROR}/ws/2/artist/$mbid?inc=url-rels+genres&fmt=json" -o "/config/cache/$sanitizedartistname-$mbid-info.json"
			sleep $MBRATELIMIT
		else
			log "$artistnumber of $artisttotal :: $LidArtistNameCap :: MBZDB CACHE :: Musicbrainz Artist Info Cache Valid..."
		fi
	
		imvdburl="echo $artistImvdbUrl"
		if [ ! -z "$imvdburl" ]; then

			

			if [ -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
				cachedimvdbcount="$(cat "/config/cache/$sanitizedartistname-$mbid-imvdb.json" | jq -r '.[] | .id' | wc -l)"
				if [ $cachedimvdbcount -ne 0 ]; then
					if ! [[ $(find "/config/cache/$sanitizedartistname-$mbid-imvdb.json" -mtime +7 -print) ]]; then
						log "$artistnumber of $artisttotal :: $artistname :: IMVDB CACHE :: Artist Cache Valid, skipping..."
						imvdbarurllistcount=1
						return
					else
						log "$artistnumber of $artisttotal :: $artistname :: IMVDB CACHE :: Artist Cache Expired :: Updating..."
						rm  "/config/cache/$sanitizedartistname-$mbid-imvdb.json" 
					fi
				fi
			else
				cachedimvdbcount="0"
			fi


			imvdbslug="$(basename "$imvdburl")"
			imvdbarurlfile="$(curl -s "https://imvdb.com/n/$imvdbslug")"
			imvdbarurllist=($(echo "$imvdbarurlfile" | grep -Eoi '<a [^>]+>' |  grep -Eo 'href="[^\"]+"' | grep -Eo '(http|https)://[^"]+' |  grep -i ".com/video" | grep -i "$imvdbslug" | sort -u))
			imvdbarurllistcount=$(echo "$imvdbarurlfile" | grep -Eoi '<a [^>]+>' |  grep -Eo 'href="[^\"]+"' | grep -Eo '(http|https)://[^"]+' |  grep -i ".com/video" | grep -i "$imvdbslug" | sort -u | wc -l)
			if [ $imvdbarurllistcount = 0 ]; then
				log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: 0 Videos Found :: Skipping..."
				return
			fi

			

			if [ $imvdbarurllistcount -ne $cachedimvdbcount ]; then
				log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: Cache out of date"
				if [ -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
					rm "/config/cache/$sanitizedartistname-$mbid-imvdb.json"
				fi
			else
				log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: Cache Valid"
			fi

			if [ ! -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
				log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: Caching Releases"
				if [ ! -d "/config/temp" ]; then
					mkdir "/config/temp"
					sleep 0.1
				fi
				for id in ${!imvdbarurllist[@]}; do
					urlnumber=$(( $id + 1 ))
					url="${imvdbarurllist[$id]}"
					imvdbvideoid=$(curl -s "$url" | grep -Eoi '<img [^>]+>' |  grep -Eo 'src="[^\"]+"' | grep -Eo '(http|https)://[^"]+' | grep "/video/" | grep -o '[[:digit:]]*' | grep -o -w '\w\{6,20\}' | head -n1)
					log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: Downloading Release $urlnumber Info"
					curl -s "https://imvdb.com/api/v1/video/$imvdbvideoid?include=sources" -o "/config/temp/$mbid-imvdb-$urlnumber.json"
					sleep 0.1
				done
				if [ ! -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
					jq -s '.' /config/temp//$mbid-imvdb-*.json > "/config/cache/$sanitizedartistname-$mbid-imvdb.json"
				fi
				if [ -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
					log "$artistnumber of $artisttotal :: $LidArtistNameCap :: IMVDB CACHE :: Caching Complete"
				fi
				if [ -d "/config/temp" ]; then
					sleep 0.1
					rm -rf "/config/temp"
				fi
			fi
		fi
		touch "/config/cache/$sanitizedartistname-$mbid-cache-complete"
	
}

DownloadVideos () {

	CountryCodelowercase="$(echo ${CountryCode,,})"

	if [ -f "/config/cookies/cookies.txt" ]; then
		cookies="--cookies /config/cookies/cookies.txt"
	else
		cookies=""
	fi

	if [ -z "$videofilter" ]; then
		videofilter=""
	fi

	if  [ "$artistname" == "Various Artists" ]; then
		log "$artistnumber of $artisttotal :: $artistname :: Skipping, not processed by design..."
		return
	fi



	if [ -f "/config/cache/$sanitizedartistname-$mbid-download-complete" ]; then
		if ! [[ $(find "/config/cache/$sanitizedartistname-$mbid-download-complete" -mtime +7 -print) ]]; then
			log "$artistnumber of $artisttotal :: $artistname :: Artist already processed previously, skipping until cache expires..."
			return
		fi
	fi

	log "$artistnumber of $artisttotal :: $artistname :: Processing"
	log "$artistnumber of $artisttotal :: $artistname :: Normalizing MBZDB Release Info (Capitalization)"
	imvdburl="$(echo "$mbzartistinfo" | jq -r ".relations[] | .url | select(.resource | contains(\"imvdb\")) | .resource")"
	imvdbslug="$(basename "$imvdburl")"

	if [ -f "/config/cache/$sanitizedartistname-$mbid-imvdb.json" ]; then
		db="IMVDb"
		log "$artistnumber of $artisttotal :: $artistname :: IMVDB :: Aritst Link Found, using it's database for videos..."
		imvdbcache="$(cat "/config/cache/$sanitizedartistname-$mbid-imvdb.json")"
		imvdbids=($(echo "$imvdbcache" |  jq -r ".[] | select(.sources[] | select(.source==\"youtube\")) | .id"))
		videocount="$(echo "$imvdbcache" | jq -r ".[] | select(.sources[] | select(.source==\"youtube\")) | .id" | wc -l)"
		for id in ${!imvdbids[@]}; do
			currentprocess=$(( $id + 1 ))
			imvdbid="${imvdbids[$id]}"
			imvdbvideodata="$(echo "$imvdbcache" | jq -r ".[] | select(.id==$imvdbid) | .")"
			videotitle="$(echo "$imvdbvideodata" | jq -r ".song_title")"
			videodisambiguation=""
			videotitlelowercase="${videotitle,,}"
			videodirectors="$(echo "$imvdbvideodata" | jq -r ".directors[] | .entity_name")"
			videoimage="$(echo "$imvdbvideodata" | jq -r ".image.o")"
			videoyear="$(echo "$imvdbvideodata" | jq -r ".year")"
			sanitizevideotitle="$(echo "$videotitle"  |  sed -e "s%[^[:alpha:][:digit:]._()' -]% %g" -e "s/  */ /g")"
			youtubeid="$(echo "$imvdbvideodata" | jq -r ".sources[] | select(.source==\"youtube\") | .source_data" | head -n 1)"
			youtubeurl="https://www.youtube.com/watch?v=$youtubeid"
			if ! [ -f "/config/logs/download.txt" ]; then
				touch "/config/logs/download.txt"
			fi
			if cat "/config/logs/download.txt" | grep -i ":: $youtubeid ::" | read; then
				log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} :: Already downloaded... (see: /config/logs/download.txt)"
				continue
			fi
			if cat "/config/logs/download.txt" | grep -i "$youtubeurl" | read; then
				log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} :: Already downloaded... (see: /config/logs/download.txt)"
				continue
			fi

			youtubedata="$(python3 /usr/local/bin/youtube-dl ${cookies} -j $youtubeurl 2> /dev/null)"
			if [ -z "$youtubedata" ]; then
				continue
			fi
			youtubeuploaddate="$(echo "$youtubedata" | jq -r '.upload_date')"
			if [ "$imvdbvideoyear" = "null" ]; then
				videoyear="$(echo ${youtubeuploaddate:0:4})"
			fi
			youtubeaveragerating="$(echo "$youtubedata" | jq -r '.average_rating')"
			videoalbum="$(echo "$youtubedata" | jq -r '.album')"
			sanitizedvideodisambiguation=""
			log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: MBZDB MATCH :: ${videotitle}${nfovideodisambiguation} :: Checking for match"

			VideoMatch

			if [ "$trackmatch" = "false" ]; then
				log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: MBZDB MATCH :: ERROR :: ${videotitle}${nfovideodisambiguation} :: Could not be matched to Musicbrainz"
				if [ "$RequireVideoMatch" = "true" ]; then
					log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: MBZDB MATCH :: ERROR :: ${videotitle}${nfovideodisambiguation} :: Require Match Enabled, skipping..."
					continue
				fi
			fi

			VideoDownload

			if [ "$WriteNFOs" == "true" ]; then
				VideoNFOWriter
			else
				if find "$destination" -type f -iname "*.jpg" | read; then
					rm "$destination"/*.jpg
				fi
				if find "$destination" -type f -iname "*.nfo" | read; then
					rm "$destination"/*.nfo
				fi
			fi
			done
	else
		if ! [ -f "/config/logs/imvdberror.log" ]; then
			touch "/config/logs/imvdberror.log"
		fi
		if [ -f "/config/logs/imvdberror.log" ]; then
			log "$artistnumber of $artisttotal :: $artistname :: MBZDB :: ERROR :: musicbrainz id: $mbid is missing IMVDB link, see: \"/config/logs/imvdberror.log\" for more detail..."
			if cat "/config/logs/imvdberror.log" | grep "$mbid" | read; then
				sleep 0.1
			else
				log "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/$mbid/relationships for \"${artistname}\" with IMVDB Artist Link" >> "/config/logs/imvdberror.log"
			fi
		fi
	fi

	
			
	
	downloadcount=$(find "$destination" -mindepth 1 -maxdepth 3 -type f -iname "*.mkv" | wc -l)
	log "$artistnumber of $artisttotal :: $artistname :: $downloadcount Videos Downloaded!"
	log "$artistnumber of $artisttotal :: $artistname :: MARKING ARTIST AS COMPLETE"
	touch "/config/cache/$sanitizedartistname-$mbid-download-complete"

}

VideoNFOWriter () {

	if [ -f "${filelocation}.mkv" ]; then
		if [ ! -f "${filelocation}.nfo" ]; then
			nfo="${filelocation}.nfo"
			echo "<musicvideo>" >> "$nfo"
			echo "	<title>${videotitle}${nfovideodisambiguation}</title>" >> "$nfo"
			echo "	<userrating>$youtubeaveragerating</userrating>" >> "$nfo"
			if [ "$trackmatch" = "true" ]; then
				echo "	<track>$videotrackposition</track>" >> "$nfo"
			else
				echo "	<track/>" >> "$nfo"
			fi
			if [ "$videoalbum" != "null" ]; then
				echo "	<album>$videoalbum</album>" >> "$nfo"
			else
				echo "	<album>Music Videos</album>" >> "$nfo"
			fi
			echo "	<plot/>" >> "$nfo"
			if [ ! -z "$imvdbid" ]; then
				echo "	<imvdbid>$imvdbid</imvdbid>" >> "$nfo"
			fi
			# Genre
			if [ ! -z "$videogenres" ]; then
				genres="$(echo "$videogenres" | sort -u)"
				OUT=""
				SAVEIFS=$IFS
				IFS=$(echo -en "\n\b")
				for f in $genres
				do
					echo "	<genre>${f,,}</genre>" >> "$nfo"
				done
				IFS=$SAVEIFS
			else
				OLDIFS="$IFS"
				IFS=$'\n'
				artistgenres=($(echo $artistdata | jq -r ".genres[]"))
				IFS="$OLDIFS"
				for genre in ${!artistgenres[@]}; do
					artistgenre="${artistgenres[$genre]}"
					echo "	<genre>$artistgenre</genre>" >> "$nfo"
				done
			fi
			if [ ! -z "$videodirectors" ]; then
				OUT=""
				SAVEIFS=$IFS
				IFS=$(echo -en "\n\b")
				for f in $videodirectors
				do
					echo "	<director>$f</director>" >> "$nfo"
				done
				IFS=$SAVEIFS
			else
				director="    <director/>" >> "$nfo"
			fi
			
			if [ "$trackmatch" = "true" ]; then
				echo "	<premiered>$releasegroupdate</premiered>" >> "$nfo"
			else
				echo "	<premiered/>" >> "$nfo"
			fi
			if [ "$videoyear" != "null" ]; then
				echo "	<year>$videoyear</year>" >> "$nfo"
			else
				echo "	<year/>" >> "$nfo"
			fi
			echo "	<studio/>" >> "$nfo"
			echo "	<artist>$artistname</artist>" >> "$nfo"
			echo "	<musicBrainzArtistID>$mbid</musicBrainzArtistID>" >> "$nfo"
			artistcountry="$(cat "/config/cache/$sanitizedartistname-$mbid-info.json" | jq -r ".country")"
			if [ ! -z "$artistcountry" ]; then
				echo "	<country>$artistcountry</country>" >> "$nfo"
			else
				echo "	<country/>" >> "$nfo"
			fi
			if [ -f "${filelocation}.jpg" ]; then
				echo "	<thumb>${thumbnailname}.jpg</thumb>" >> "$nfo"
			else
				echo "	<thumb/>" >> "$nfo"
			fi
			echo "</musicvideo>" >> "$nfo"
			tidy -w 2000 -i -m -xml "$nfo" &>/dev/null
			chmod $FilePermissions "$nfo"
			chown abc:abc "$nfo"
			log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: NFO WRITER :: Writing NFO for ${videotitle}${nfovideodisambiguation}"
			log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: NFO WRITER :: Writing NFO for ${videotitle}${nfovideodisambiguation}"
		fi
	fi

}

VideoMatch () {

	trackmatch="false"
	filter="false"
	skip="false"
	releaseid=""
	videotitlelowercase="$(echo $videotitlelowercase | sed 's/"/\\"/g')"
	# album match first...
	# Preferred Country
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"$CountryCodelowercase\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"album\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# WorldWide
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"xw\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"album\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# Everywhere
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"album\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# single match second...
	# Preferred Country
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"$CountryCodelowercase\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"single\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# WorldWide
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"xw\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"single\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# Everywhere
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"single\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# ep match third...
	# Preferred Country
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"$CountryCodelowercase\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"ep\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# WorldWide
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"xw\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"ep\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# Everywhere
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .status==\"official\") | select(.\"release-group\".\"primary-type\"==\"ep\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# match any type fourth...
	# Preferred Country
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"$CountryCodelowercase\" and .status==\"official\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# WorldWide
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .country==\"xw\" and .status==\"official\") | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# Everywhere
	if [ -z "$releaseid" ]; then
		releaseid=($(echo "$releasesfilelowercase" | jq -s -r ".[] | .[] | .releases | sort_by(.date) | .[] | select(.date!=\"\" and .status==\"official\" ) | select(.media[] | .tracks[] | .title==\"$videotitlelowercase\") | .id"))
	fi

	# Loop through matched track releaseid's to find a corresponding release-group match
	if [ ! -z "$releaseid" ]; then
		for id in ${!releaseid[@]}; do
			subprocess=$(( $id + 1 ))
			trackreleaseid="${releaseid[$id]}"
			releasedata="$(echo "$releasesfile" | jq -r ".[] | .releases[] | select(.id==\"$trackreleaseid\")")"
			releasedatalowercase="$(echo ${releasedata,,})"
			releasetrackid="$(echo "$releasedatalowercase" | jq -r ".media[] | .tracks[] | select(.title==\"$videotitlelowercase\") | .id" | head -n 1)"
			releasetracktitle="$(echo "$releasedata" | jq -r ".media[] | .tracks[] | select(.id==\"$releasetrackid\") | .title" | head -n 1)"
			releasetrackposition="$(echo "$releasedata" | jq -r ".media[] | .tracks[] | select(.id==\"$releasetrackid\") | .position")"
			releasetitle="$(echo "$releasedata" | jq -r ".title")"
			releasestatus="$(echo "$releasedata" | jq -r ".status")"
			releasecountry="$(echo "$releasedata" | jq -r ".country")"
			releaselanguage="$(echo "$releasedata" | jq -r '."text-representation".language')"
			releasegrouptitle="$(echo "$releasedata" | jq -r '."release-group"."title"')"
			releasegroupdate="$(echo "$releasedata" | jq -r '."release-group"."first-release-date"')"
			releasegroupyear="$(echo ${releasegroupdate:0:4})"
			releasegroupstatus="$(echo "$releasedata" | jq -r '."release-group" | ."primary-type"')"
			releasegroupsecondarytype="$(echo "$releasedata" | jq -r '."release-group" | ."secondary-types"[]')"
			releasegroupgenres="$(echo "$releasedata" | jq -r '."release-group" | .genres[] | .name' | sort -u)"
			# Skip null country
			if [ "$releasecountry" = null ]; then
				skip=true
			fi

			if [ ! -z "$videofilter" ]; then
				# Skip filter album matches
				if echo "$releasegroupsecondarytype" | grep -i "$videofilter" | read; then
					skip=true
					filter=true
				fi

				# Skip filter album matches
				if [ ! -z "$videodisambiguation" ]; then
					if echo "$videodisambiguation" | grep -i "$videofilter" | read; then
						skip=true
						filter=true
					fi
				fi
			fi

			# Use artist genres, if release group genres don't exist
			if [ -z "$releasegroupgenres" ]; then
				releasegroupgenres="$(echo "$mbzartistinfo" | jq -r '.genres[] | .name' | sort -u | sed -e "s/\b\(.\)/\u\1/g")"
			fi

			if [ "$skip" = false ]; then
				trackmatch=true
				filter=false
				log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: MBZDB MATCH :: Track $releasetrackposition :: $releasetracktitle :: $releasegrouptitle :: $releasestatus :: $releasecountry :: $releasegroupstatus :: $releasegroupyear"
				videotrackposition="$releasetrackposition"
				videotitle="$releasetracktitle"
				sanitizevideotitle="$(echo "$videotitle" | sed -e "s%[^[:alpha:][:digit:]._()' -]% %g" -e "s/  */ /g")"
				videoyear="$releasegroupyear"
				videoalbum="$releasegrouptitle"
				videogenres="$(echo "$releasegroupgenres" | sed -e "s/\b\(.\)/\u\1/g")"
				break
			else
				trackmatch=false
				skip=false
				continue
			fi
		done
	fi
}

VideoDownload () {
	if [ ! -z "$videodisambiguation" ]; then
		nfovideodisambiguation=" ($videodisambiguation)"
		sanitizedvideodisambiguation=" ($(echo "${videodisambiguation}" | sed -e "s%[^[:alpha:][:digit:]._()' -]% %g" -e "s/  */ /g"))"
	else
		nfovideodisambiguation=""
		sanitizedvideodisambiguation=""
	fi
	if [ "$videoyear" != "null" ]; then
		year="$videoyear"
	else
		year=""
	fi
	if [ "$videoalbum" != "null" ]; then
		album="$videoalbum"
	else
		album=""
	fi
	# Genre
	if [ ! -z "$videogenres" ]; then
		genres="$(echo "$videogenres" | sort -u)"
		OUT=""
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		for f in $genres
		do
			OUT=$OUT"$f / "
		done
		IFS=$SAVEIFS
		genre="${OUT%???}"
		genre="${genre,,}"
	else
		OLDIFS="$IFS"
		IFS=$'\n'
		artistgenres=($(echo $artistdata | jq -r ".genres[]"))
		IFS="$OLDIFS"
		for genre in ${!artistgenres[@]}; do
			artistgenre="${artistgenres[$genre]}"
			OUT=$OUT"$artistgenre / "
		done
		genre="${OUT%???}"
		genre="${genre,,}"
		
	fi
	if [ "$trackmatch" = "true" ]; then
		track="$videotrackposition"
	else
		track=""
	fi

	if [ "$USEFOLDERS" == "true" ]; then
		destination="$LIBRARY/$artistfolder"
		if [ ! -d "$destination" ]; then
			mkdir -p "$destination"
			chmod $FolderPermissions "$destination"
			chown abc:abc "$destination"
		fi
		if [ "$USEVIDEOFOLDERS" == "true" ]; then
			filelocation="$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}/${sanitizevideotitle}${sanitizedvideodisambiguation}"
			thumbnailname="${sanitizevideotitle}${sanitizedvideodisambiguation}"
		else
			filelocation="$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}"
			thumbnailname="$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}"
		fi
	else
		destination="$LIBRARY"
		filelocation="$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}"
		thumbnailname="$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}"
	fi
	
	if [ -f "${filelocation}.mkv" ] || [ -f "${filelocation}.mp4" ] ; then
		log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} ::  ${videotitle}${nfovideodisambiguation} already downloaded!"
		if cat "/config/logs/download.txt" | grep -i ":: $youtubeid ::" | read; then
			sleep 0.1
		else
			log "Video :: Downloaded :: $db :: ${artistname} :: $youtubeid :: $youtubeurl :: ${videotitle}${nfovideodisambiguation}" >> "/config/logs/download.txt"
		fi
		return
	fi


	log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} :: Processing ($youtubeurl)... with youtube-dl"
	log "=======================START YOUTUBE-DL========================="
	yt-dlp -o "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}" ${videoformat} --write-sub --sub-lang $subtitlelanguage --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "$youtubeurl"
	log "========================STOP YOUTUBE-DL========================="
	if [ -f "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" ]; then
		log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} :: Complete!"
		audiochannels="$(ffprobe -v quiet -print_format json -show_streams "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" | jq -r ".[] | .[] | select(.codec_type==\"audio\") | .channels" | head -n 1)"
		width="$(ffprobe -v quiet -print_format json -show_streams "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .width" | head -n 1)"
		height="$(ffprobe -v quiet -print_format json -show_streams "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .height" | head -n 1)"
		if [[ "$width" -ge "3800" || "$height" -ge "2100" ]]; then
			videoquality=3
			qualitydescription="UHD"
		elif [[ "$width" -ge "1900" || "$height" -ge "1060" ]]; then
			videoquality=2
			qualitydescription="FHD"
		elif [[ "$width" -ge "1260" || "$height" -ge "700" ]]; then
			videoquality=1
			qualitydescription="HD"
		else
			videoquality=0
			qualitydescription="SD"
		fi

		if [ "$audiochannels" -ge "3" ]; then
			channelcount=$(( $audiochannels - 1 ))
			audiodescription="${audiochannels}.1 Channel"
		elif [ "$audiochannels" == "2" ]; then
			audiodescription="Stereo"
		elif [ "$audiochannels" == "1" ]; then
			audiodescription="Mono"
		fi

		if [ ! -z "$videoimage" ]; then
			curl -s "$videoimage" -o "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg"
		fi

		if [ ! -f "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg" ]; then
			ffmpeg -y \
				-i "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" \
				-vframes 1 -an -s 640x360 -ss 30 \
				"$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg" &> /dev/null
		fi

		if [ ! -z "$videodirectors" ]; then
			mkvdirector="$(echo "$videodrectors" | head -n 1)"
			mkvdirectormetadata="-metadata DIRECTOR="$videodrectors""
		else
			mkvdirectormetadata=""
		fi
		mv "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" "$destination/temp.mkv"
		cp "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg" "$destination/cover.jpg"
		log "========================START FFMPEG========================"
		ffmpeg -y \
			-i "$destination/temp.mkv" \
			-map 0 \
			-c copy \
			-metadata ENCODED_BY="AMVD" \
			-metadata:s:v:0 title="$qualitydescription" \
			-metadata:s:a:0 title="$audiodescription" \
			"$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv"
		log "========================STOP FFMPEG========================="
		
		rm "$destination/cover.jpg"
		rm "$destination/temp.mkv"
		chmod $FilePermissions "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv"
		chmod $FilePermissions "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg"
		chown abc:abc "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv"
		chown abc:abc "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg"
		if [ "$USEVIDEOFOLDERS" == "true" ]; then
			if [ ! -d "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}" ]; then
				mkdir -p "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}"
				chmod $FolderPermissions "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}"
				chown abc:abc "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}"
			fi
			mv "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}/${sanitizevideotitle}${sanitizedvideodisambiguation}.mkv" 
			mv "$destination/$sanitizedartistname - ${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg" "$destination/${sanitizevideotitle}${sanitizedvideodisambiguation}/${sanitizevideotitle}${sanitizedvideodisambiguation}.jpg"
		fi
	
		# reset language
		releaselanguage="null"

		log "Video :: Downloaded :: $db :: ${artistname} :: $youtubeid :: $youtubeurl :: ${videotitle}${nfovideodisambiguation}" >> "/config/logs/download.txt"
	else
		log "$artistnumber of $artisttotal :: $artistname :: $db :: $currentprocess of $videocount :: DOWNLOAD :: ${videotitle}${nfovideodisambiguation} :: Downloaded Failed!"
	fi
}

log () {
    m_time=`date "+%F %T"`
    echo $m_time" "$1
}

LidarrConnection () {

	lidarrdata=$(curl -s --header "X-Api-Key:"${LidarrAPIkey} --request GET  "$LidarrUrl/api/v1/Artist/")
	artisttotal=$(echo "${lidarrdata}"| jq -r '.[].sortName' | wc -l)
	lidarrlist=($(echo "${lidarrdata}" | jq -r ".[].foreignArtistId"))
	log "############################################ YouTube Video Downloads"

	for id in ${!lidarrlist[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${lidarrlist[$id]}"
		artistdata=$(echo "${lidarrdata}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\")")
		artistname="$(echo "${artistdata}" | jq -r " .artistName")"
		artistnamepath="$(echo "${artistdata}" | jq -r " .path")"
		sanitizedartistname="$(basename "${artistnamepath}" | sed 's% (.*)$%%g')"
		artistfolder="$(basename "${artistnamepath}")"
		CacheEngine
		if [ $imvdbarurllistcount -ne 0 ]; then
			DownloadVideos
		fi

	done
	totaldownloadcount=$(find "$LIBRARY" -mindepth 1 -maxdepth 3 -type f -iname "*.mkv" | wc -l)
	log "############################################ $totaldownloadcount VIDEOS DOWNLOADED"
}

AMAConnection () {

	log "############################################ YouTube Video Downloads"


	artisttotal=$(ls /ama/list/*-lidarr 2> /dev/null | sort -u | wc -l)

	if [ $artisttotal == 0 ]; then
		log "ERROR :: AMA List Folder contains no compatible artist IDs (####-lidarr)"
		exit
	fi

	amalist=($(ls /ama/list/*-lidarr | sort -u))


	for id in ${!amalist[@]}; do
		artistnumber=$(( $id + 1 ))
		amafile="${amalist[$id]}"
		deezerid=$(echo "$amafile" | grep -o '[[:digit:]]*')
		mbid=$(cat $amafile)
		artistname="$(echo "$deeezerartistinfo" | jq -r ".name")"
		sanitizedartistname="$(echo "$artistname" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g'  -e "s/  */ /g")"
		artistfolder="$sanitizedartistname ($deezerid)"
		CacheEngine
		DownloadVideos

	done
	totaldownloadcount=$(find "$LIBRARY" -mindepth 1 -maxdepth 3 -type f -iname "*.mkv" | wc -l)
	log "############################################ $totaldownloadcount VIDEOS DOWNLOADED"
}

Main () {

	Configuration
	if [ "$SOURCE_CONNECTION" == "ama" ]; then
		AMAConnection
	fi
	if [ "$SOURCE_CONNECTION" == "lidarr" ]; then
		LidarrConnection
	fi

	log "############################################ SCRIPT COMPLETE"
	if [ "$AUTOSTART" == "true" ]; then
		log "############################################ SCRIPT SLEEPING FOR $SCRIPTINTERVAL"
	fi

}

Main
exit 0
