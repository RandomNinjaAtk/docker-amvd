FROM lsiobase/ubuntu:focal
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Music Video Downloader"
ENV VERSION="0.0.1"
ENV MBRAINZMIRROR="https://musicbrainz.org"

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
		ffmpeg \
		cron && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install youtube-dl ************" && \
	curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl && \
	chmod a+rx /usr/local/bin/youtube-dl
	echo "************ install mp4 tagging software ************" && \
	pip3 install --no-cache-dir -U \
		mutagen

WORKDIR /

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
