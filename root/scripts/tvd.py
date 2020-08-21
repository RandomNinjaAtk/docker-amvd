#!/usr/bin/env python3
from aigpy.stringHelper import isNull
import aigpy.m3u8Helper as m3u8Helper
from aigpy.pathHelper import replaceLimitChar
import aigpy.stringHelper as stringHelper

from getpass import getpass
import sys
import os
import subprocess
import os.path as path

from tidal_dl.tidal import TidalAPI
from tidal_dl.settings import UserSettings
from tidal_dl.enum import Type, VideoQuality

import base64
import json
import requests

class TVD:
    def __init__(self):
        self.api = TidalAPI()
        self.api2 = None
        self.user = UserSettings.read()
        self.token1, self.token2 = self.api.getToken()
        self.checkLogin()

    def login(self, email="", password=""):
        if path.isfile('/config/scripts/login'):
            with open("/config/scripts/login", 'r') as f:
                email = f.readline()
                password = f.readline()
        else:
            while email == "" and password == "":
                email = input("email: ")
                password = getpass("password: ")
            with open("login", 'w') as f:
                f.write(email+"\n"+password)
        while True:
            msg, check = self.api.login(email, password, self.token1)
            if check == False:
                print(msg)
                email = ""
                password = ""
                continue
            self.api2 = TidalAPI()
            msg, check = self.api2.login(email, password, self.token2)
            break

        self.user.username = email
        self.user.password = password
        self.user.userid = self.api.key.userId
        self.user.countryCode = self.api.key.countryCode
        self.user.sessionid1 = self.api.key.sessionId
        self.user.sessionid2 = self.api2.key.sessionId

    def checkLogin(self):
        if not isNull(self.user.assesstoken):
            mag, check = self.api.loginByAccessToken(self.user.assesstoken)
            if check == False:
                print("Invalid accesstoken")
        if not isNull(self.user.sessionid1) and not self.api.isValidSessionID(self.user.userid, self.user.sessionid1):
            self.user.sessionid1 = ""
        if not isNull(self.user.sessionid2) and self.api.isValidSessionID(self.user.userid, self.user.sessionid2):
            self.user.sessionid2 = ""
        if isNull(self.user.sessionid1) or isNull(self.user.sessionid2):
            self.login(self.user.username, self.user.password)

    def getArtistVideos(self, artist_id):
        return self.api.__get__(f'artists/{artist_id}/videos', {'limit': '999'})[1]

    def getVideoStreamUrl(self, video_id, quality):
        paras = {"videoquality": "HIGH", "playbackmode": "STREAM", "assetpresentation": "FULL"}
        msg, data = self.api.__get__('videos/' + str(video_id) + "/playbackinfopostpaywall", paras)
        if msg is not None:
            return msg, None

        if "vnd.tidal.emu" in data['manifestMimeType']:
            manifest = json.loads(base64.b64decode(data['manifest']).decode('utf-8'))
            url = manifest['urls'][0]

            qualityArray = []
            txt = requests.get(url).text
            array = txt.split("#EXT-X-STREAM-INF")
            for item in array:
                if "RESOLUTION=" not in item:
                    continue
                stream = {}
                stream['codec'] = stringHelper.getSub(item, "CODECS=\"", "\"")
                stream['m3u8Url'] = "http" + stringHelper.getSubOnlyStart(item, "http").strip()
                stream['resolution'] = stringHelper.getSub(item, "RESOLUTION=", "http").strip()
                if ',FRAME-RATE' in stream['resolution']:
                    stream['resolution'] = stream['resolution'][:stream['resolution'].find(',FRAME-RATE')]
                stream['resolutions'] = stream['resolution'].split("x")
                qualityArray.append(stream)

            icmp = int(quality)
            index = 0
            for item in qualityArray:
                if icmp >= int(item['resolutions'][1]):
                    break
                index += 1
            if index >= len(qualityArray):
                index = len(qualityArray) - 1
            return "", qualityArray[index]
        return "", None

    def downloadVideo(self, video, quality):
        #msg, video = self.api.__get__(f'videos/{video}')
        self.api.key.accessToken = self.user.assesstoken
        self.api.key.userId = self.user.userid
        self.api.key.countryCode = self.user.countryCode
        self.api.key.sessionId = self.user.sessionid2 if not isNull(self.user.sessionid2) else self.user.sessionid1
        msg, stream = self.getVideoStreamUrl(video['id'], quality)
        if not isNull(msg):
            print(video['title'] + "." + msg)
            return
        # CHANGE THIS LINE TO CHANGE THE FILENAME
        videofile = library + "/" + replaceLimitChar(f"{artist} - {video['title']} ({video['id']})", "_")+".mkv"
        path = library + "/" + replaceLimitChar(f"{video['title']} ({video['id']})", "_")+".mp4"
        filename = str(video['id'])
        filtetitle = str(video['title'])
        if not os.path.exists("/config/logs/tidal/" + replaceLimitChar(f"{artist} - {video['title']} ({video['id']})", "_")):
            if not m3u8Helper.download(stream['m3u8Url'], path):
                print("\nDownload failed!")
            else:
                subprocess.call(['ffmpeg', '-y', '-ss', '10', '-i', path, '-frames:v', '1', '-vf', str("scale=640:-2"), 'cover.jpg'])    
                subprocess.call(['ffmpeg', '-i', path, '-c', 'copy', '-metadata', 'title=' + filtetitle, '-metadata', 'ARTIST=' + artist, '-metadata', 'ENCODED_BY=AMVD', '-metadata', 'CONTENT_TYPE=Music Video', '-attach', 'cover.jpg', '-metadata:s:t', 'mimetype=image/jpeg', '-y', videofile])
                subprocess.call(['mkvpropedit', videofile, '--add-track-statistics-tags'])
                subprocess.call(['rm', path])
                subprocess.call(['rm', 'cover.jpg'])
                f = open("/config/logs/tidal/" + replaceLimitChar(f"{artist} - {video['title']} ({video['id']})", "_"), "w")
                f.write("Download Success")
                f.close()
        else: 
            print("Already Downloaded!!!")
        
if __name__ == '__main__':
    app = TVD()
    if len(sys.argv) >= 4:
        art_id = sys.argv[1]
        artist = sys.argv[2]
        library = sys.argv[3]
        videos = app.getArtistVideos(art_id)
        tot = len(videos['items'])
        for pos, video in enumerate(videos['items'], start=1):
            print(f"{pos} of {tot} :: {video['title']}")
            app.downloadVideo(video, 1080)
