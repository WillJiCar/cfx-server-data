from haralyzer import HarParser
import urllib2
import json
import re
import glob, os
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
countrycodes = ["en", "de", "pt", "es", "mx", "pl", "cn", "ru", "it", "fr", "kr", "jp"]

def getJSON(url):
    for code in countrycodes:
        try:
            json_url = url.replace("1_0.jpg","0_0_"+code+".json")
            json_url = json_url.replace("2_0.jpg","0_0_"+code+".json")
            response = urllib2.urlopen(json_url)
            return response
        except urllib2.HTTPError:
            continue

convert_to_xml = True

def dashrepl(matchobj):
    return "-"

harfile = glob.glob("*.har")[0]
print("Extracting from "+harfile)

with open(harfile, 'r') as f:
    har_parser = HarParser(json.loads(f.read()))

for page in har_parser.pages:
    for asset in page.entries:
        if not re.search(r"/ugc.*jpg", asset["request"]["url"]):
            continue

        response = getJSON(asset["request"]["url"])
        data = response.read()
        d = json.loads(data)
        name = "".join(d["mission"]["gen"]["nm"])
        name = re.sub(r'[^a-zA-Z0-9 \-]' ,r'', name)
        name = name.lower()
        name = name.replace(" ", "-")
        name = name.replace("---", "-")
        path = name +".json"
        print("Writing " + name)
        with open(path,'w+') as f:
            f.write(data)
        if convert_to_xml:
            os.system("python ugc_to_xml.py "+path)
            os.remove(path)
