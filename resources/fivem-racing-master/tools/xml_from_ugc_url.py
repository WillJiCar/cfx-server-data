import urllib2
import json
import re
import os
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
countrycodes = ["en", "de", "pt", "es", "mx", "pl", "cn", "ru", "it", "fr", "kr", "jp"]

def dashrepl(matchobj):
    return "-"
def getJSON(url):
    for code in countrycodes:
        try:
            json_url = url.replace("1_0.jpg","0_0_"+code+".json")
            json_url = json_url.replace("2_0.jpg","0_0_"+code+".json")
            response = urllib2.urlopen(json_url)
            return response
        except urllib2.HTTPError:
            continue
def getXmlMap(url):
    response = getJSON(url)
    data = response.read()
    d = json.loads(data)
    name = "".join(d["mission"]["gen"]["nm"])
    name = name.lower()
    name = name.replace(" ", "-")
    name = name.replace("---", "-")
    path = name +".json"
    print("Writing " + name)
    with open(path,'w+') as f:
       f.write(data)
    os.system("python ugc_to_xml.py "+path)
    os.remove(path)

if len(sys.argv) > 1:
    url = sys.argv[1]
    getXmlMap(url)
else:
    while True:
        url = raw_input("Paste UGC thumbnail url:\n")
        getXmlMap(url)
        print("-------------")

