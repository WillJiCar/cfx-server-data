import os
import json
from dicttoxml import dicttoxml
from xml.dom.minidom import parseString
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

def isSBAProp(hash):
    hash_uint = hash & 0xffffffff
    return hash_uint in [3287988974,3906373800,4228722453,3124504613,993442923,4067691788,1431235846,1832852758,346059280,620582592,85342060,483832101,930976262,1677872320,708828172,950795200,3034310442,2419563138,3430162838,2992496910,1518201148,117169896,2815009181]


path = sys.argv[1]
d={}
with open(path, 'r') as ugc_json:
    d = json.load(ugc_json)

name = "".join(d["mission"]["gen"]["nm"])
desc = "".join(d["mission"]["gen"]["dec"])
creator = d["mission"]["gen"]["ownerid"]
if "_RSN_" in creator:
    creator = "Rockstar"

if ("propno" in d["mission"]["gen"]):
    propno = d["mission"]["gen"]["propno"]
    if propno > 0:
        deleted_props = d["mission"]["dhprop"]
        props = d["mission"]["prop"]
        positions = props["loc"]
        models = props["model"]
        rotations = props["vRot"]
        colors = props["prpclr"]
        speedboostarguments = props["prpsba"]
elif "no" in d["mission"]["prop"]:
    propno = d["mission"]["prop"]["no"]
    if propno > 0:
        deleted_props = d["mission"]["dprop"]
        props = d["mission"]["prop"]
        positions = props["loc"]
        models = props["model"]
        rotations = props["vRot"]
        colors = [0] * propno
        speedboostarguments = [0] * propno
else:
    propno = 0
    
this_is_a_race = "race" in d["mission"]
if this_is_a_race:
    ivm = d["mission"]["gen"]["ivm"] # initial vehicle model? eg 989294410 for voltic2
    race = d["mission"]["race"]
    chp_no = race["chp"]
    chp_loc = race["chl"]
    chp_heading = race["chh"]
    if "rndchk" in race:
        chp_round = race["rndchk"]
    elif "cpbs1" in race:
        chp_round = [val > 1 for val in race["cpbs1"]]
    else:
        chp_round = [False for val in chp_loc]
    laps = race["lap"]
    grid_pos = race["grid"]
    grid_heading = race["head"]
    rules = d["mission"]["rule"]
    pickup_no = d["mission"]["weap"]["no"]
    pickup_heading = d["mission"]["weap"]["head"]
    pickup_loc = d["mission"]["weap"]["loc"]
    pickup_type = d["mission"]["weap"]["type"]
    pickup_subtype = d["mission"]["weap"]["sub"]


map = {}
map["Name"] = name
map["Description"] = desc
map["Creator"] = creator
proplist = []
for i in range(0,propno):
    prop = {}
    prop["Hash"] = models[i]
    prop["Pos"] = {"X":positions[i]["x"], "Y":positions[i]["y"], "Z":positions[i]["z"]}
    prop["Rot"] = {"X":rotations[i]["x"], "Y":rotations[i]["y"], "Z":rotations[i]["z"]}
    prop["Color"] = colors[i]
    if isSBAProp(int(models[i])):
        prop["SBA"] = speedboostarguments[i]
    proplist.append(prop)

map["Props"] = proplist

item_func = lambda x: x[:-1]

def SaveRace():
    race = {}
    race["Map"] = map
    race["AllowedVehicleModel"] = ivm
    race["Laps"] = laps
    race["Grid"] = {"Pos":{"X":grid_pos["x"],"Y":grid_pos["y"],"Z":grid_pos["z"]},"Heading":grid_heading}
    chplist = []
    for i in range(0,chp_no):
        chp = {}
        chp["Pos"] = {"X":chp_loc[i]["x"], "Y":chp_loc[i]["y"], "Z":chp_loc[i]["z"]}
        chp["Heading"] = chp_heading[i]
        chp["Round"] = chp_round[i]
        chplist.append(chp)
    race["Checkpoints"] = chplist
    rules_d = GetRuleDictFromXML(rules)
    race["Rules"] = rules_d
    pickup_list = []
    for i in range(0, pickup_no):
        pickup = {}
        pickup["Heading"] = pickup_heading[i]
        pickup["Pos"] = {"X":pickup_loc[i]["x"], "Y":pickup_loc[i]["y"], "Z":pickup_loc[i]["z"]}
        pickup["Type"] = pickup_type[i]
        subtype = int(pickup_subtype[i])
        if subtype > 0:
            pickup["Subtype"] = subtype
        pickup_list.append(pickup)
    race["Pickups"] = pickup_list
    
    
    xml = dicttoxml(race, attr_type=False, custom_root='Race', item_func=item_func)
    pretty_xml = parseString(xml).toprettyxml().replace("<Map>", '<Map version="5me-v1">').encode('utf-8')
    new_dir = path[:-4] + '/'

    try:
        os.mkdir(new_dir)
    except:
        pass

    new_fn = path[:-4] + path[-4:].replace("json","xml")
    new_path = new_dir + new_fn
    with open(new_path,'w+') as f:
        f.write(pretty_xml)

    with open(new_dir + '__resource.lua','w+') as f:
        f.write('resource_type \'map\' { gameTypes = { ["fivem-racing"] = true }, name = [[%s]] }\n' % name)
        f.write('race [[%s]]' % new_fn)

    print("Converted UGC to XML race")
    print("Name: "+name)
    print("Creator: "+creator)
    #print("Description:\n"+desc)
    print("Contains " + str(propno) + " props, " + str(pickup_no) + " pickups.")

def GetRuleDictFromXML(xml):
    rules = {}
    tod = int(xml["tod"])
    if tod == 1:
        tod = 6
    elif tod == 2:
        tod = 12
    elif tod == 3:
        tod = 22
    else:
        tod = 12
    rules["TimeOfDay"] = tod
    
    traf = int(xml["traf"])
    if traf == 1: #OFF
        traf = 0
    elif traf == 2: #LOW
        traf = 0.1
    elif traf == 3: #MEDIUM
        traf = 0.5
    elif traf == 4: #HIGH
        traf = 1.5
    else:
        traf = 1.0
    rules["TrafficDensity"] = traf
    
    weth = int(xml["weth"])
    if weth == 1:
        weth = "CLEAR"
    elif weth == 2:
        weth = "RAINING"
    else:
        weth = "CLEAR"
    rules["Weather"] = weth
    
    return rules

def SaveMap():
    my_item_func = lambda x: 'Prop'
    xml = dicttoxml(map, attr_type=False, custom_root='Map', item_func=item_func)
    pretty_xml = parseString(xml).toprettyxml().replace("<Map>", '<Map version="5me-v1">')
    new_path = path[:-4] + path[-4:].replace("json","xml")
    with open(new_path,'w+') as f:
        f.write(pretty_xml)
    print("Converted UGC to XML map")
    print("Name: "+name)
    print("Creator: "+creator)
    print("Description:\n"+desc)
    print("Contains " + str(propno) + " props.")        
    
if this_is_a_race:
    #save_as_race = raw_input("Save this as a FiveRace XML? (y/n) ")
    if True:#save_as_race == "y":
        SaveRace()
    else:
        SaveMap()
else:
    SaveMap()
