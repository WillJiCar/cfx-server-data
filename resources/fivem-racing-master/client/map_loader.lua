-- This file is part of the FiveMapEditor, it reads xml map files in 5me (MEME) and Guadmaz formats, spawns the entities and gives their handles back to FiveMapEditor.
local prop_list = {}

local function func_192(sba) -- from decompiled R* scripts
	if sba == 1 then
		return 0.3
	elseif sba == 2 then
		return 0.4
	elseif sba == 3 then
		return 0.5
	elseif sba == 4 then
		return 0.5
	elseif sba == 5 then
		return 0.5
	else
		return 0.4
	end
end

local function func_193(sba) -- from decompiled R* scripts
	if sba == 1 then
		return 15
	elseif sba == 2 then
		return 25
	elseif sba == 3 then
		return 35
	elseif sba == 4 then
		return 45
	elseif sba == 5 then
		return 100
	else
		return 25
	end
end

local function func_190(sba) -- from decompiled R* scripts
	if sba == 1 then
		return 44
	elseif sba == 2 then
		return 30
	elseif sba == 3 then
		return 16
	else
		return 30
	end
end

local function func_191(hash) -- from decompiled R* scripts
	if (hash == 346059280 or hash == 620582592 or hash == 85342060 or hash == 483832101 or hash == 930976262 or hash == 1677872320 or hash == 708828172 or hash == 950795200 or hash == -1260656854 or hash == -1875404158 or hash == -864804458 or hash == -1302470386 or hash == 1518201148 or hash == 384852939 or hash == 117169896 or hash == -1479958115) then
		return 1
	else
		return 0
	end
end

local function joaat(s)
	return GetHashKey(s)
end

local function setSBA(obj, sba) -- from decompiled R* scripts, no idea what SBA is an abbrev for
	local hash = GetEntityModel(obj)
	if (hash == joaat("stt_prop_track_speedup") or hash == joaat("stt_prop_track_speedup_t1") or hash == joaat("stt_prop_track_speedup_t2") or hash == joaat("stt_prop_stunt_tube_speed") or hash == joaat("stt_prop_stunt_tube_speedb")) then
		Citizen.InvokeNative(0x7BAC110ED504814D, obj, func_193(sba))
		Citizen.InvokeNative(0x4E91E2848E9525BB, obj, func_192(sba))
	elseif (hash == joaat("stt_prop_track_slowdown") or hash == joaat("stt_prop_track_slowdown_t1") or hash == joaat("stt_prop_track_slowdown_t2") or func_191(hash))then
		Citizen.InvokeNative(0x7BAC110ED504814D, obj, func_190(sba))
	end
end

function loadMap(map, loaded_callback)
Citizen.CreateThread(function()
	--name = map.Name[1]
	--creator = map.Creator[1]
	if map.Description[1] ~= nil then
		description = map.Description[1]
	end
	local props = map.Props
	if props ~= nil and #props > 0 then
		props = props[1].Prop
		for _,prop in ipairs(props) do
			local hash = tonumber(prop.Hash[1])
			local pos = vector3(tonumber(prop.Pos[1].X[1]),tonumber(prop.Pos[1].Y[1]),tonumber(prop.Pos[1].Z[1]))
			local rot = vector3(tonumber(prop.Rot[1].X[1]),tonumber(prop.Rot[1].Y[1]),tonumber(prop.Rot[1].Z[1]))
			local dynamic = false
			local colorid = 0
			if prop.Color then
				colorid = tonumber(prop.Color[1])
			end
			while not HasModelLoaded(hash) do
				RequestModel(hash)
				Wait(0)
			end
			local obj = CreateObjectNoOffset(hash, pos, false, false, dynamic)
			SetEntityRotation(obj, rot, 2, true)
			FreezeEntityPosition(obj, true)
			SetObjectTextureVariant(obj, colorid)
			if prop.SBA then
				local sba = tonumber(prop.SBA[1])
				setSBA(obj, sba)
			end
			if hash == GetHashKey("stt_prop_hoop_constraction_01a") then
				local dict = "scr_stunts"
				Citizen.InvokeNative(0x4B10CEA9187AFFE6, dict)
				if Citizen.InvokeNative(0xC7225BF8901834B2, dict) then
					Citizen.InvokeNative(0xFF62C471DC947844, dict)
					Citizen.InvokeNative(0x2FBC377D2B29B60F, "scr_stunts_fire_ring", obj, vector3(0, 0, 25), vector3(-12.5, 0, 0), 1.0, 0,0,0)
				end
			elseif hash == GetHashKey("stt_prop_hoop_small_01") then
				local dict = "core"
				Citizen.InvokeNative(0x4B10CEA9187AFFE6, dict)
				if Citizen.InvokeNative(0xC7225BF8901834B2, dict) then
					Citizen.InvokeNative(0xFF62C471DC947844, dict)
					Citizen.InvokeNative(0x2FBC377D2B29B60F, "ent_amb_fire_ring", obj, vector3(0, 0, 4.5), vector3(0, 0, 90), 3.5, 0,0,0)
				end								
			end
			table.insert(prop_list, obj)
		end
	end
	loaded_callback()
end)
end

function unloadMap()
	Citizen.Trace("[racing:map_loader] UNLOAD MAP")
	for _, prop in ipairs(prop_list) do -- delete current props
		DeleteObject(prop)
	end
	prop_list = {}
end