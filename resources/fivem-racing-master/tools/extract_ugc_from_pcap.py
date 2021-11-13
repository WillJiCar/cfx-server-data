import pyshark
import urllib2
import json
import re
import glob, os

convert_to_xml = True

def dashrepl(matchobj):
    return "-"

pcapfile = glob.glob("*.pcap")[0]
print("Extracting from "+pcapfile)
cap = pyshark.FileCapture(pcapfile, display_filter='http.request.method=="GET" and http.request.uri matches "^/ugc.*jpg"')
for packet in cap:
    uri = packet.http.request_full_uri.replace("2_0.jpg","0_0_en.json")
    response = urllib2.urlopen(uri)
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
    if convert_to_xml:
        os.system("python ugc_to_xml.py "+path)
        os.remove(path)
