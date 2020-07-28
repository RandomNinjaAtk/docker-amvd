ARG ffmpeg_tag=snapshot-ubuntu
FROM jrottenberg/ffmpeg:${ffmpeg_tag} as ffmpeg
FROM lsiobase/ubuntu:bionic
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Music Video Downloader"
ENV VERSION="0.0.1"
ENV MBRAINZMIRROR="https://musicbrainz.org"

# Add files from ffmpeg
COPY --from=ffmpeg /usr/local/ /usr/local/

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install packages ************" && \
	apt-get update -y && \
	apt-get install -y --no-install-recommends \
		wget \
		nano \
		unzip \
		git \
		jq \
		python3 \
		python3-pip \
		cron && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install youtube-dl ************" && \
	curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl && \
	chmod a+rx /usr/local/bin/youtube-dl

RUN \
	echo "************ install updated ffmpeg ************" && \
	chgrp users /usr/local/bin/ffmpeg && \
 	chgrp users /usr/local/bin/ffprobe && \
	chmod g+x /usr/local/bin/ffmpeg && \
	chmod g+x /usr/local/bin/ffprobe && \
	apt-get update -y && \
	apt-get install -y --no-install-recommends libva-drm2 libva2 i965-va-driver && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

WORKDIR /

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
