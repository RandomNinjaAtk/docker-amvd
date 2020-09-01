FROM lsiobase/ubuntu:focal
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Music Video Downloader (AMVD)"
ENV TITLESHORT="AMVD"
ENV VERSION="1.0.5"
ENV MBRAINZMIRROR="https://musicbrainz.org"

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install & upgrade packages ************" && \
	apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends \
		jq \
		python3 \
		python3-pip \
		ffmpeg \
		mkvtoolnix && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
		youtube_dl \
		mutagen \
		tidal-dl

# copy local files
COPY root/ /

WORKDIR /config

# ports and volumes
VOLUME /config
