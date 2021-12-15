FROM lsiobase/ubuntu:a7da6fde-ls13
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Music Video Downloader (AMVD)"
ENV TITLESHORT="AMVD"
ENV VERSION="1.0.7"
ENV MBRAINZMIRROR="https://musicbrainz.org"

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install & upgrade packages ************" && \
	apt-get update -y && \
	apt-get install -y --no-install-recommends \
		jq \
		python3 \
		python3-pip \
		ffmpeg \
		tidy \
		mkvtoolnix && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
		youtube_dl \
		yt-dlp \
		mutagen \
		yq
		

# copy local files
COPY root/ /

WORKDIR /config

# ports and volumes
VOLUME /config
