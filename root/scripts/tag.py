#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import enum
import argparse
from mutagen.mp4 import MP4, MP4Cover

parser = argparse.ArgumentParser(description='Optional app description')
# Argument
parser.add_argument('--file', help='A required integer positional argument')
parser.add_argument('--songtitle', help='A required integer positional argument')
parser.add_argument('--songalbum', help='A required integer positional argument')
parser.add_argument('--songartist', help='A required integer positional argument')
parser.add_argument('--songartistalbum', help='A required integer positional argument')
parser.add_argument('--songtracknumber', help='A required integer positional argument')
parser.add_argument('--songdate', help='A required integer positional argument')
parser.add_argument('--songgenre', help='A required integer positional argument')
parser.add_argument('--songartwork', help='A required integer positional argument')
parser.add_argument('--quality', help='A required integer positional argument')
args = parser.parse_args()

filename = args.file
trackn = int(args.songtracknumber)
videoquality = int(args.quality)
title = args.songtitle
album = args.songalbum
artist = args.songartist
artistalbum = args.songartistalbum
date = args.songdate
genre = args.songgenre
picture = args.songartwork
tracknumber = (trackn, 0)


audio = MP4(filename)
audio["\xa9nam"] = [title]
audio["\xa9alb"] = [album]
audio["\xa9ART"] = [artist]
audio["aART"] = [artistalbum]
audio["\xa9day"] = [date]
audio["\xa9gen"] = [genre]
audio["trkn"] = [tracknumber]
audio["hdvd"] = [videoquality]
audio["stik"] = [6]
with open(picture, "rb") as f:
    audio["covr"] = [
        MP4Cover(f.read(), MP4Cover.FORMAT_JPEG)
    ]
#audio["\xa9lyr"] = [syncedlyrics]
audio.pprint()
audio.save()
