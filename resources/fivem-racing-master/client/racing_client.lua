AddEventHandler('onClientMapStart', function()
	ShutdownLoadingScreen()

	TriggerServerEvent("racing:firstSpawn")
end)

AddEventHandler('onClientMapStop', function()
	DoScreenFadeOut(1000)
end)

ClientStates = {INIT = "INIT", LOADING = "LOADING", SPECTATING="SPECTATING", VEHICLE_SELECT = "VEHICLE_SELECT", READY="READY", PRE_CNTDWN="PRE_CNTDWN", COUNTDOWN="COUNTDOWN", ONGOING="ONGOING", FINISHED="FINISHED", POST="POST"}
client_state = ClientStates.INIT -- initial state

-- CONFIGURATION
local cp_radius = 10.0
local cp_height = 9.5
local cp_colour = 13 -- Checkpoint colour https://pastebin.com/d9aHPbXN
local cp_icon_colour = 134 -- Checkpoint icon colour

-- Script setup
local race_vehicle = nil
local start_time = nil
local cp_handle = nil
local cp_blip_handle = nil
local next_cp_blip_handle = nil
ready_for_race = false
race = {}
local players = {}
local next_cp_id = 1
local race_position = 1
local current_lap = 1
RequestScriptAudioBank("DLC_STUNT/STUNT_RACE_01", false, -1)
RequestScriptAudioBank("DLC_STUNT/STUNT_RACE_02", false, -1)
RequestScriptAudioBank("DLC_STUNT/STUNT_RACE_03", false, -1)
RequestAdditionalText("RACES", 0);
StatSetInt('MP0_STAMINA', 100, true)
StatSetInt('MP0_STRENGTH', 100, true)
StatSetInt('MP0_LUNG_CAPACITY', 100, true)
StatSetInt('MP0_WHEELIE_ABILITY', 100, true)
StatSetInt('MP0_FLYING_ABILITY', 100, true)
StatSetInt('MP0_SHOOTING_ABILITY', 100, true)
StatSetInt('MP0_STEALTH_ABILITY', 100, true)
local cp_r, cp_g, cp_b, cp_a = GetHudColour(cp_colour)
local cpi_r, cpi_g, cpi_b, cpi_a = GetHudColour(cp_icon_colour)
local pickups = {}
RequestModel("prop_mp_boost_01") -- boost pickup
RequestModel("prop_mp_rocket_0o1") -- rocket pickup
local got_boost = true
local selected_vehmodel = "turismor"
local vehselect_timeout_at = nil

-- Load Race from server XML
RegisterNetEvent('racing:loadrace')
AddEventHandler('racing:loadrace', function (race_data, spectatormode)
	debugprint("Received loadrace instruction from server")
	Citizen.CreateThread(function()
		TriggerEvent("racing:hideScoreboard")
		--Loading a new race. Initialize some variables:
		client_state = ClientStates.LOADING
		players = {}
		next_cp_id = 1
		current_lap = 1
		ready_for_race = false

		while IsScreenFadingOut() do
			Citizen.Wait(0)
		end

		RequestModel('a_m_m_skater_01')

		while not HasModelLoaded('a_m_m_skater_01') do
			Wait(0)
		end

		SetPlayerModel(PlayerId(), 'a_m_m_skater_01')

		if IsEntityDead(PlayerPedId()) then
			NetworkResurrectLocalPlayer(228.1, -1006.0, 100.0, 0.0, true, true, false)
		end
		
		--Going to garage for car selector
		SetLoadingPromptTextEntry("FMMC_PLYLOAD")
		--AddTextComponentSubstringPlayerName("Loading race")
		ShowLoadingPrompt(1)
		SetEntityCoords(PlayerPedId(), vector3(228.1,-1006,-100)) --teleport to garage
		StopPlayerSwitch()
		unloadMap()
		unloadRaceCheckpoints()
		unloadRaceVehicle()
		unloadPickups()
		gfx.cancel()
		debugprint("Unloaded old map, checkpoints, vehicle, pickups")
		race = parseRaceXML(race_data)
		race.vehlist = {"banshee", "vagner", "turismor", "zentorno", "voodoo", "ztype", "tropos", "xa21", "shotaro", "sanchez", "dune", "sandking", "tribike", "tractor"}
		if race.vehmodel then
			race.vehlist = {race.vehmodel}
		end
		local override_rules = false
		if override_rules then -- APPLY GAMEMODE RULES
			race.rules.timeofday = 12
			race.rules.weather = "CLEAR"
			race.rules.trafficdensity = 1.0
		end
		debugprint("Parsed race data")

		--in the meantime, load the map
		local map_loaded = false
		loadMap(race.map, function()
			map_loaded = true
			debugprint("Loaded new map")
		end)
		
		debugprint("Setting weather to "..race.rules.weather)
			SetWeatherTypeNow(race.rules.weather)
			SetForcePedFootstepsTracks(race.rules.weather=="XMAS")
			SetForceVehicleTrails(race.rules.weather=="XMAS")
			SetOverrideWeather(race.rules.weather)
		
		-- setup vehicle selector
		local spawnPreviewCar = function(model)
			if not IsModelValid(model)then
				debugprint("previewcar ERROR: "..model.." is not a valid model")
				return
			end
			-- check if previous vehicle exists
			if race_vehicle then
				SetEntityAsMissionEntity(race_vehicle,true,true)
				DeleteVehicle(race_vehicle)
				debugprint("Deleted old preview vehicle")
			end
			while not HasModelLoaded(model) do
				RequestModel(model)
				Wait(0)
			end		
			race_vehicle = CreateVehicle(model, vector3(228.11,-993.37,-99.84), 200.0, false, false)
			while not HasCollisionLoadedAroundEntity(race_vehicle) do
				Wait(0)
			end
			SetVehicleOnGroundProperly(race_vehicle)
			local playername = GetPlayerName(PlayerId())
			SetVehicleNumberPlateText(race_vehicle, playername)
			SetEntityInvincible(race_vehicle, true)
			FreezeEntityPosition(race_vehicle, true)
			debugprint("Created race_vehicle preview: "..model)
		end
		
		Citizen.CreateThread(function() --create cam pointed towards car spawn
			garage_cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 231.7532, -998.0372, -98.1409, -16.25972, 0.0, 41.81086, 45.0, 2, 2)
			SetCamActive(garage_cam, true)
			RenderScriptCams(true, 0, 3000, 1, 0)
		end)
		debugprint("Created garage_cam")
		vehselect_timeout_at = GetNetworkTime() + 30000
		client_state = ClientStates.VEHICLE_SELECT
	
		ClearAreaOfVehicles(vector3(228.11,-993.37,-99.84), 100.0, 0, 0, 0, 0, false)
		ClearAreaOfVehicles(vector3(228.11,-993.37,-99.84), 100.0, 0, 0, 1, 0, false)
		ClearAreaOfVehicles(vector3(228.11,-993.37,-99.84), 100.0, 0, 0, 0, 1, false)
		
		local selected_id = 0
		selected_vehmodel = race.vehlist[selected_id+1]
		spawnPreviewCar(selected_vehmodel) --initial car in car selector
		
		while not (DoesEntityExist(race_vehicle)) do
			Citizen.Wait(0)
		end
		RemoveLoadingPrompt()
		DoScreenFadeIn(1000)
		
		--AddTextEntry("GARAGE_HELPTEXT", "Select a ~b~vehicle ~w~with ~INPUT_CELLPHONE_LEFT~ and ~INPUT_CELLPHONE_RIGHT~ \nPress ~INPUT_FRONTEND_ACCEPT~ to ~g~ready up~w~.")
		--BeginTextCommandDisplayHelp("GARAGE_HELPTEXT")
		--EndTextCommandDisplayHelp(0, true, true, -1)
		repeat
			if(IsControlJustPressed(1,174)) then -- LEFT
				selected_id = (selected_id - 1) % #race.vehlist
				selected_vehmodel = race.vehlist[selected_id+1]
				spawnPreviewCar(selected_vehmodel)
			elseif(IsControlJustPressed(1,175)) then -- RIGHT
				selected_id = (selected_id + 1) % #race.vehlist
				selected_vehmodel = race.vehlist[selected_id+1]
				spawnPreviewCar(selected_vehmodel)
			elseif(IsControlJustPressed(1,201)) then -- ENTER
				ready_for_race = true				
			else
			end

			-- did we reset state?
			if client_state ~= ClientStates.VEHICLE_SELECT then
				print('Bailing out of vehicle selection...')
				return
			end

			Citizen.Wait(0)
		until (ready_for_race and map_loaded) or (vehselect_timeout_at - GetNetworkTime() <= 0)
		client_state = ClientStates.READY
		-- Now the map has loaded and the player is ready, we can indicate to server that this client is ready
		TriggerServerEvent("racing:readyForRace")
		ClearAllHelpMessages()
		debugprint("Ready for race & map loaded, waiting for server instructions.")

		-- if spectatormode then
			-- debugprint("Going to SPECTATING state")
			-- client_state = ClientStates.SPECTATING
			-- DoScreenFadeIn(1000)
			-- RemoveLoadingPrompt()
		-- else
		--end
	end)
end)

RegisterNetEvent('racing:startingGrid')
AddEventHandler('racing:startingGrid', function (position_in_grid)
	Citizen.CreateThread(function()
		debugprint("Received startingGrid ("..position_in_grid..") instruction from server.")
		client_state = ClientStates.PRE_CNTDWN
		GTAOTransition(race.grid.pos, race.grid.heading, function()
			DeleteEntity(race_vehicle)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 0, 0, false)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 1, 0, false)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 0, 1, false)
			RenderScriptCams(false, 0, 3000, 1, 0)
			local vehpos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), (-1*(-1)^position_in_grid)*3.0, -4.2 - position_in_grid*6.0, 0.0)
			race_vehicle = CreateVehicle(selected_vehmodel, vehpos, race.grid.heading, true, false)
			while not HasCollisionLoadedAroundEntity(race_vehicle) do
				Wait(0)
			end
			local playername = GetPlayerName(PlayerId())
			SetVehicleNumberPlateText(race_vehicle, playername)
			SetPedIntoVehicle(PlayerPedId(), race_vehicle, -1)
			SetPedCanBeKnockedOffVehicle(GetPlayerPed(-1), true)
			SetVehicleDoorsLockedForAllPlayers(race_vehicle, true)
			SetVehicleDoorsLocked(race_vehicle, 4)
			SetEntityInvincible(race_vehicle, true)
			SetVehicleOnGroundProperly(race_vehicle)
			FreezeEntityPosition(race_vehicle, true)
			debugprint("Finished transition to starting grid")
			Citizen.Wait(2000)
			gfx.showIntro(race.name, "Race")
		-- if race.rules.gta then
			-- loadPickups(race.pickups)
		-- end
		end)
	end)
end)

function loadPickups(pickup_arr)
	for _, pickup in ipairs(pickup_arr) do
		local type = pickup.type
		local pos = pickup.pos
		local rot = vector3(0.0, 0.0, 0.0)
		local flag = 8
		local amount = 1000
		local modelHash = 0
		local subtype = pickup.subtype
		if type == -1514616151 then -- PICKUP_VEHICLE_CUSTOM_SCRIPT
			modelHash = GetHashKey(GetModelForPickupSubtype(subtype))
		end
		local handle = CreatePickupRotate(pickup.type, pickup.pos, 0.0, 0.0, 0.0, 1026, 0, 2, true, modelHash)
		--local handle = CreatePickupRotate(GetHashKey("pickup_vehicle_custom_script"), pickup.pos, 0.0, 0.0, 0.0, 512, 1000, 2, 1, GetHashKey("prop_mp_rocket_01"))
		table.insert(pickups, handle)
	end
end

function GetModelForPickupSubtype(subtype)
	if subtype == 0 then return "prop_mp_boost_01"--WT_BOOST
	elseif subtype == 1 then return 0--WT_SPIKE
	elseif subtype == 2 then return "prop_mp_rocket_01"--WT_V_SPACERKT -- HUD_ROCKET
	elseif subtype == 3 then return 0
	else return "prop_mp_rocket_01"
	end
end

function parseRaceXML(race_xml)
	local race = {grid = {}, name = "Unnamed Race", checkpoints = {}, map = {}, vehmodel = nil, rules={}, pickups={}}
	local xml = SLAXML:dom(race_xml)
	if xml and xml.root then
		if xml.root.name == "Race" then
			xml = processXml(xml.root)
			race.grid.pos = vector3(tonumber(xml.Grid[1].Pos[1].X[1]),tonumber(xml.Grid[1].Pos[1].Y[1]),tonumber(xml.Grid[1].Pos[1].Z[1]))
			race.grid.heading = tonumber(xml.Grid[1].Heading[1])
			race.map = xml.Map[1]
			race.name = race.map.Name[1]
			race.description = race.map.Description[1]
			race.laps = tonumber(xml.Laps[1])
			if race.laps < 1 then
				race.laps = 1 -- 1 lap means point to point
			end
			for i=1,race.laps do -- insert these checkpoints multiple times to account for laps (a very shoddy approach but sue me I want to be first to market)
				for _, cp in ipairs(xml.Checkpoints[1].Checkpoint) do
					local checkp = {}
					checkp.pos = vector3(tonumber(cp.Pos[1].X[1]),tonumber(cp.Pos[1].Y[1]),tonumber(cp.Pos[1].Z[1]))
					checkp.heading = tonumber(cp.Heading[1])
					checkp.round = (cp.Round[1] == "True")
					table.insert(race.checkpoints, checkp)
				end
			end
			allowed_veh_model = 0
			if xml.AllowedVehicleModel then
				allowed_veh_model = tonumber(xml.AllowedVehicleModel[1])
				debugprint("Allowed vehicle model: " .. allowed_veh_model)
			end
			if IsModelValid(allowed_veh_model) then
				race.vehmodel = allowed_veh_model
			end
			if xml.Rules then
				local rules = {}
				rules.timeofday = tonumber(xml.Rules[1].TimeOfDay[1])
				rules.weather = xml.Rules[1].Weather[1]
				rules.trafficdensity = tonumber(xml.Rules[1].TrafficDensity[1]) * 1.0
				race.rules = rules
			else
				race.rules.trafficdensity = 1.0
				race.rules.weather = "CLEAR"
				race.rules.timeofday = 12
			end
			if xml.Pickups then
				if xml.Pickups[1] then
					for _, p in ipairs(xml.Pickups[1].Pickup) do
						local pickup = {}
						pickup.pos = vector3(tonumber(p.Pos[1].X[1]),tonumber(p.Pos[1].Y[1]),tonumber(p.Pos[1].Z[1]))
						pickup.heading = tonumber(p.Heading[1])
						pickup.type = tonumber(p.Type[1])
						if p.Subtype then
							pickup.subtype = tonumber(p.Subtype[1])
						else
							pickup.subtype = 0
						end
						table.insert(race.pickups, pickup)
					end
				end
			end
			return race
		end
	end
	error("XML PARSING FAILED, WHAT THE FUCK DID THE SERVER SEND?")
	-- If we are here, something is wrong and we can't parse.
end

-- countdown stuff
RegisterNetEvent('racing:countdown')
AddEventHandler('racing:countdown', function (countFrom)
	debugprint("Received COUNTDOWN instruction from server")
	client_state = ClientStates.COUNTDOWN
	gfx.startCountdown(countFrom)
end)

RegisterNetEvent('racing:GO') -- Server instructs clients to GO
AddEventHandler('racing:GO', function ()
	debugprint("Received GO instruction from server")
	client_state = ClientStates.ONGOING
	start_time = GetNetworkTime()
	race_vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
	FreezeEntityPosition(race_vehicle, false)
	SetVehicleForwardSpeed(race_vehicle, 15.0) --R* uses 25.0 and 5.0, no idea yet which type of races have 5.0
	
	if IsThisModelAHeli(GetEntityModel(race_vehicle)) then -- if helicopter race, set blades to full speed etc
		SetHeliBladesFullSpeed(race_vehicle)
	end
	
	local effectname = "FocusOut" -- MP_Celeb_Preload_Fade, MP_Celeb_Win_Out, MinigameTransitionIn, FocusOut, MinigameTransitionOut, MP_job_load, MinigameEndNeutral
	StartScreenEffect(effectname, 0, 0)
	-- Show HelpText for special vehicles
	Citizen.CreateThread(function()
		local model = GetEntityModel(race_vehicle)
		local specialveh = false
		if model == GetHashKey("voltic2") then
			specialveh = true
			BeginTextCommandDisplayHelp("SVM_VOLTIC2_HELP3")
			EndTextCommandDisplayHelp(0, 0, 0, 10000)
		elseif model == GetHashKey("ruiner2") then
			specialveh = true
			local combined_txt = GetLabelText("SVM_RUINER2_HELP1") .. "\n" .. GetLabelText("SVM_RUINER2_HELP2")
			AddTextEntry("RUINER2_COMBOHELP", combined_txt)
			BeginTextCommandDisplayHelp("RUINER2_COMBOHELP")
			EndTextCommandDisplayHelp(0, 0, 0, 10000)
		elseif model == GetHashKey("blazer5") then
			specialveh = true
			BeginTextCommandDisplayHelp("SVM_BLAZER5_HELP2")
			EndTextCommandDisplayHelp(0, 0, 0, 10000)
		end
		if specialveh then
			Citizen.Wait(10000)
		end
		BeginTextCommandDisplayHelp("HEIST_HELP_44")
		EndTextCommandDisplayHelp(0, 0, 0, 10000)
	end)
	
	--Setting up first checkpoint and first two blips
	local first_cp = race.checkpoints[1].pos
	local next_cp = race.checkpoints[2].pos
	cp_handle = CreateCheckpoint(5, first_cp.x, first_cp.y, first_cp.z+5.0, next_cp.x, next_cp.y, next_cp.z, cp_radius, cp_r, cp_g, cp_b, 180, 0)
	SetCheckpointCylinderHeight(cp_handle, cp_height, cp_height, 100.0);
	SetCheckpointIconRgba(cp_handle, cpi_r, cpi_g, cpi_b, cpi_a)
	cp_blip_handle = AddBlipForCoord(first_cp)
	SetBlipSprite(cp_blip_handle, 1)
	SetBlipColour(cp_blip_handle, 66)
	next_cp_blip_handle = AddBlipForCoord(next_cp)
	SetBlipSprite(next_cp_blip_handle, 1)
	SetBlipColour(next_cp_blip_handle, 66)
	SetBlipScale(next_cp_blip_handle, 0.5)
	
	--Starting the OnTick methods for this race instance
	StartRaceOnTick()
	StartUpdatePosition()
	
	race.no_collision = true
	if race.no_collision then
		StartNoCollisionHandler()
	end
end)

function IsPlayerWithinCPTrigger(cp)
	local pos = GetEntityCoords(GetPlayerPed(-1))
	local cp_center = cp.pos
	local trigger_radius = cp_radius + 2.0
	if race.checkpoints[next_cp_id].round then
		cp_center = cp_center + vector3(0.0,0.0,10.0)
		trigger_radius = 20.0
	end
	local distanceToCheckpoint = Vdist(pos,  cp_center)
	return (distanceToCheckpoint < trigger_radius)
end

function GetNumberOfArrowsToDraw(cp)
	thisCP = race.checkpoints[cp].pos
	previousCP = race.checkpoints[cp-1].pos
	nextCP = race.checkpoints[cp+1].pos
	prevToNow = thisCP - previousCP
	nowToNext = nextCP - thisCP
	angle = GetAngleBetween_2dVectors(prevToNow.x, prevToNow.y, nowToNext.x, nowToNext.y)
	angle = Absf(angle)
	if angle < 80.0 then
		return 0
	elseif angle < 140.0 then
		return 1
	elseif angle < 180.0 then
		return 2
	else
		return 0
	end
end

function StartRaceOnTick()
Citizen.CreateThread(function()
	local respawnKey_start = nil
	local res = {};
	res.x, res.y = GetScreenResolution()
	local textscale = 0.5
	local fontid = 1
	local respawn_hold_time = 1500
	while client_state == ClientStates.ONGOING do
	
		-- BEGIN RESPAWNING KEY
		if IsControlJustPressed(0, 75) then
			respawnKey_start = GetNetworkTime()
		end
		if IsControlJustReleased(0, 75) then
			respawnKey_start = nil
		end
		if respawnKey_start then
			elapsed = GetNetworkTime() - respawnKey_start
			DrawRect(0.5, 0.5,  elapsed/respawn_hold_time, 0.05, 255, 0, 0, 100)
			BeginTextCommandWidth("STRING")
			AddTextComponentSubstringPlayerName("HOLD TO RESPAWN")
			SetTextFont(fontid)
			SetTextScale(textscale, textscale)
			local width = EndTextCommandGetWidth(1)
			local height = GetTextScaleHeight(textscale, fontid)
			BeginTextCommandDisplayText("STRING")
			AddTextComponentSubstringPlayerName("HOLD TO RESPAWN")
			SetTextFont(fontid)
			--SetTextProportional(1)
			SetTextScale(textscale, textscale)
			SetTextColour(255, 255, 255, 255)
			EndTextCommandDisplayText(0.5 - (width/2.0), 0.5 - (height/2.0))
			if elapsed >= respawn_hold_time then
				local p, h
				if next_cp_id == 1 then -- still have to pass first CP
					p = race.grid.pos
					h = race.grid.heading
				else
					p = race.checkpoints[next_cp_id-1].pos
					h = race.checkpoints[next_cp_id-1].heading
				end
				SetEntityCoords(race_vehicle, p, 1, 0, 0, 1)
				SetEntityHeading(race_vehicle, h, 1, 0, 0, 1)
				SetVehicleFixed(race_vehicle)
				SetVehicleDeformationFixed(race_vehicle)
				SetVehicleDirtLevel(race_vehicle, 0)
				SetVehicleEngineHealth(race_vehicle, 1000.0)
				SetVehiclePetrolTankHealth(race_vehicle, 1000.0)
				SetVehicleUndriveable(race_vehicle, false)
				SetVehicleEngineCanDegrade(race_vehicle, false)
				SetVehicleEngineOn(race_vehicle, true)
				SetPedIntoVehicle(GetPlayerPed(-1), race_vehicle, -1)
				SetGameplayCamRelativeHeading(0.0)
				SetVehicleForwardSpeed(race_vehicle, 20.0)
				if IsThisModelAHeli(GetEntityModel(race_vehicle)) then -- if helicopter race, set blades to full speed etc
					SetHeliBladesFullSpeed(race_vehicle)
				end
				StartScreenEffect("SwitchShortNeutralIn", 0, 0);
				PlaySoundFrontend(-1, "Hit", "RESPAWN_ONLINE_SOUNDSET", 1);
				respawnKey_start = nil
			end
		end
		-- END RESPAWNING KEY

		if IsPlayerWithinCPTrigger(race.checkpoints[next_cp_id]) then
			TriggerServerEvent("racing:passedCP", next_cp_id)
			FadeoutAndDeleteCheckpoint(cp_handle)
			--DeleteCheckpoint(cp_handle)

			if next_cp_id == #race.checkpoints then -- PASSED THE FINISH
				PlaySoundFrontend(-1, "Checkpoint_Finish", "DLC_Stunt_Race_Frontend_Sounds", 0)
				RemoveBlip(cp_blip_handle)
				break
			else
				if (next_cp_id % ((#race.checkpoints)/race.laps) == 0) then -- finished a lap
					current_lap = current_lap + 1
					PlaySoundFrontend(-1, "Checkpoint_Lap", "DLC_Stunt_Race_Frontend_Sounds", 1)
				else -- a normal checkpoint
					PlaySoundFrontend(-1, "Checkpoint", "DLC_Stunt_Race_Frontend_Sounds", 0)
				end
				
				next_cp_id = next_cp_id + 1
				RemoveBlip(cp_blip_handle)
				cp_blip_handle = next_cp_blip_handle
				SetBlipScale(cp_blip_handle, 1.0)
				if next_cp_id == #race.checkpoints then -- creating the finish marker
					local cp = race.checkpoints[next_cp_id].pos
					cp_handle = CreateCheckpoint(4, cp.x, cp.y, cp.z, cp.x, cp.y, cp.z, cp_radius, cp_r, cp_g, cp_b, 180, 0)
					SetCheckpointIconRgba(cp_handle, cpi_r, cpi_g, cpi_b, cpi_a)
				else
					local previous_cp = race.checkpoints[next_cp_id].pos
					local next_cp = race.checkpoints[next_cp_id+1].pos
					local type = 5
					local z_offset = 5.0
					local radius = cp_radius
					if race.checkpoints[next_cp_id].round then
						type = 10
						z_offset = 10.0
						radius = 20.0
					end
					type = type + GetNumberOfArrowsToDraw(next_cp_id)
					cp_handle = CreateCheckpoint(type, previous_cp.x, previous_cp.y, previous_cp.z + z_offset, next_cp.x, next_cp.y, next_cp.z, radius, cp_r, cp_g, cp_b, 180, 0)
					SetCheckpointCylinderHeight(cp_handle, cp_height, cp_height, 100.0);
					SetCheckpointIconRgba(cp_handle, cpi_r, cpi_g, cpi_b, cpi_a)
					if next_cp_id+1 == #race.checkpoints  then -- creating the finish blip
						next_cp_blip_handle = AddBlipForCoord(race.checkpoints[next_cp_id+1].pos)
						SetBlipSprite(next_cp_blip_handle, 38)
					else
						next_cp_blip_handle = AddBlipForCoord(race.checkpoints[next_cp_id+1].pos)
						SetBlipSprite(next_cp_blip_handle, 1)
						SetBlipColour(next_cp_blip_handle, 66)		
						SetBlipScale(next_cp_blip_handle, 0.5)							
					end
				end
			end
		end
		if IsControlJustPressed(0, 51) then
			--DoBoost()
			--DoRockets()
		end
		Citizen.Wait(0)
	end
end)
end

function FadeoutAndDeleteCheckpoint(cp)
Citizen.CreateThread(function()
	SetCheckpointRgba(cp, 255, 255, 255, 0)
	local fadeout_duration = 500
	local start_fadeout = GetNetworkTime()
	while GetNetworkTime() - start_fadeout < 500 do
		local alpha = Round(((500 - (GetNetworkTime() - start_fadeout))/500)*255)
		SetCheckpointIconRgba(cp, 255, 255, 255, alpha)
		Citizen.Wait(0)
	end
	DeleteCheckpoint(cp)
end)
end

function DoBoost()
Citizen.CreateThread(function()
	StartScreenEffect("RaceTurbo", 0, 0)
	SetVehicleBoostActive(race_vehicle, true)
	local max_speed = GetVehicleModelMaxSpeed(GetEntityModel(race_vehicle))
	SetVehicleForwardSpeed(race_vehicle, max_speed)
	got_boost = false
	Citizen.Wait(1400)
	SetVehicleBoostActive(race_vehicle, false)
end)
end

function DoRockets() -- Based on how R* does it
Citizen.CreateThread(function()
	local weapon = GetHashKey("weapon_vehicle_rocket")
	local Dmin, Dmax = GetModelDimensions(GetEntityModel(race_vehicle))
	while not HasWeaponAssetLoaded(weapon) do
		RequestWeaponAsset(weapon, 31, 0)
		Citizen.Wait(0)
	end
	from1 = GetOffsetFromEntityInWorldCoords(race_vehicle, (Dmin.x - 0.2), (Dmax.y + 0.5), (Dmin.z + 0.75))
	from2 = GetOffsetFromEntityInWorldCoords(race_vehicle, (Dmax.x + 0.2), (Dmax.y + 0.5), (Dmin.z + 0.75))
	to1 = GetOffsetFromEntityInWorldCoords(race_vehicle, (Dmin.x - 0.2), (Dmax.y + 100.0), (Dmin.z + 0.75))
	to2 = GetOffsetFromEntityInWorldCoords(race_vehicle, (Dmin.x + 0.2), (Dmax.y + 100.0), (Dmin.z + 0.75))
	projectile_speed = 400.0
	vehspeed = GetEntitySpeed(race_vehicle)
	if vehspeed*vehspeed > 400.0 then
		projectile_speed = ((vehspeed * vehspeed) + 100.0)
	end
	Citizen.InvokeNative(0xFACE170EB74A63E6,from1, to1, 250, 1, weapon, PlayerPedId(), 1, 1, projectile_speed, race_vehicle, 0)
	Citizen.InvokeNative(0xFACE170EB74A63E6,from2, to2, 250, 1, weapon, PlayerPedId(), 1, 1, projectile_speed, race_vehicle, 0)
end)
end

function HideHUDThisFrame()
	--HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideScriptedHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

function DisableMovementControls()
	DisableControlAction(1, 22)
	DisableControlAction(1, 23)
	DisableControlAction(1, 24)
	DisableControlAction(1, 30)
	DisableControlAction(1, 31)
	DisableControlAction(1, 32)
	DisableControlAction(1, 33)
	DisableControlAction(1, 34)
	DisableControlAction(1, 35)
	DisableControlAction(1, 36)
	DisableControlAction(1, 37)
	DisableControlAction(1, 44)
	DisableControlAction(1, 45)
	DisableControlAction(1, 59) -- veh L/R
	DisableControlAction(1, 68) -- veh aim
	DisableControlAction(1, 71) -- veh accel
	DisableControlAction(1, 72) -- brake
	DisableControlAction(1, 79) -- look behind
	DisableControlAction(1, 80) -- cinematic cam
	DisableControlAction(1, 86) -- horn
	DisableControlAction(1, 87) -- veh_fly_throttle_up
	DisableControlAction(1, 88) -- veh_fly_throttle_down
	DisableControlAction(1, 89) -- veh_fly_yaw_left
	DisableControlAction(1, 90) -- veh_fly_yaw_right
	
end

function StartUpdatePosition()
Citizen.CreateThread(function()
	while client_state == ClientStates.ONGOING do
		local position = 1
		for server_id, data in pairs(players) do
			server_id = tonumber(server_id)
			if not (server_id == GetPlayerServerId(PlayerId())) then
				--print("checking position with player "..server_id..", cp: "..players[tostring(server_id)].cp)
				if data.finishPosition then
					--print("They finished")
					position = position +1
				elseif data.cp > next_cp_id - 1 then
					--print("They are a checkpoint ahead")
					position = position + 1
				elseif data.cp == (next_cp_id - 1) then
					local next_cp_coords = race.checkpoints[next_cp_id].pos
					local my_coords = GetEntityCoords(GetPlayerPed(-1))
					local their_coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(server_id)))
					local my_distance = Vdist(next_cp_coords, my_coords)
					local their_distance = Vdist(next_cp_coords, their_coords)
					if their_distance < my_distance then
						--print("They have same checkpoint but are closer")
						position = position + 1
					end
				else
					-- nothing
				end
			end
		end
		race_position = position
		Citizen.Wait(500)
	end
end)
end

function StartNoCollisionHandler()
Citizen.CreateThread(function()
	while client_state == ClientStates.ONGOING do
		for server_id, data in pairs(players) do
			server_id = tonumber(server_id)
			if not (server_id == GetPlayerServerId(PlayerId())) then
				if NetworkIsPlayerActive(GetPlayerFromServerId(server_id)) then
					local their_ped = GetPlayerPed(GetPlayerFromServerId(server_id))
					local their_veh = GetVehiclePedIsIn(their_ped)
					SetEntityNoCollisionEntity(their_veh, race_vehicle, false)
					SetEntityAlpha(their_veh, 180, false)
					SetEntityAlpha(their_ped, 180, false)
				end
			end
		end
		Citizen.Wait(10)
	end
end)
end

Citizen.CreateThread(function() -- Rules thread
	while true do
		if client_state ~= ClientStates.INIT and client_state ~= ClientStates.LOADING then
			NetworkOverrideClockTime(race.rules.timeofday, 0, 0)
			SetPedDensityMultiplierThisFrame(race.rules.trafficdensity);
			SetScenarioPedDensityMultiplierThisFrame(race.rules.trafficdensity, race.rules.trafficdensity);
			SetVehicleDensityMultiplierThisFrame(race.rules.trafficdensity);
			SetRandomVehicleDensityMultiplierThisFrame(race.rules.trafficdensity);
			SetParkedVehicleDensityMultiplierThisFrame(race.rules.trafficdensity);
		end
		if client_state == ClientStates.PRE_CNTDWN or client_state == ClientStates.COUNTDOWN then
			FreezeEntityPosition(race_vehicle, true)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 0, 0, false)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 1, 0, false)
			ClearAreaOfVehicles(race.grid.pos, 3000.0, 0, 0, 0, 1, false)
		end
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function() -- UI thread
AddTextEntry("GARAGE_HELPTEXT", "Select a ~b~vehicle ~w~with ~INPUT_CELLPHONE_LEFT~ and ~INPUT_CELLPHONE_RIGHT~ \nPress ~INPUT_FRONTEND_ACCEPT~ to ~g~ready up~w~.")
	
	while true do
		if client_state == ClientStates.VEHICLE_SELECT or client_state == ClientStates.READY then
			DrawReady(ready_for_race, math.floor((vehselect_timeout_at - GetNetworkTime())/1000))
			HideHUDThisFrame()
			DrawInfoAboutLoadedRace(race)
			DrawSelectedCarInfo(selected_vehmodel)
			DisplayHelpTextThisFrame("GARAGE_HELPTEXT")
		elseif client_state == ClientStates.PRE_CNTDWN then
			
		elseif client_state == ClientStates.ONGOING then
			DrawRaceUI()
		elseif client_state == ClientStates.FINISHED or client_state == ClientStates.POST then
			HideHUDThisFrame()
		elseif client_state == ClientStates.SPECTATING then
			local spectator_buttons = gfx.setupInstructionalButtons({175, 174}, {"", "Switch players"}) -- when inside the loop it reacts to changing between kb+m / gamepad
			DrawScaleformMovieFullscreen(spectator_buttons, 255, 255, 255, 255, 0)
		else
		end
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function() -- Invisibility & control thread
	while true do
		if client_state == ClientStates.INIT or client_state == ClientStates.LOADING or client_state == ClientStates.VEHICLE_SELECT or client_state == ClientStates.READY or client_state == ClientStates.FINISHED or client_state == ClientStates.POST then
			SetEntityVisible(GetPlayerPed(-1), false, 0)
			DisableMovementControls()
		else
			SetEntityVisible(PlayerPedId(), true, 0)
		end
		Citizen.Wait(0)
	end
end)


function DrawReady(ready_for_race, timeleft)
	local txt = "NOT READY"
	if ready_for_race then
		txt = "READY"
	end
	SetTextFont(2)
	SetTextProportional(1)
	SetTextScale(0.0, 0.6)
	if ready_for_race then
		SetTextColour(0, 255, 0, 255)
	else
		SetTextColour(255, 0, 0, 255)
	end
	
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(txt)
	DrawText(0.1, 0.8)
	if ready_for_race then
		SetTextFont(0)
		SetTextProportional(1)
		SetTextScale(0.0, 0.25)
		SetTextColour(255, 255, 255, 255)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextEdge(1, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString("Waiting for other players...")
		DrawText(0.1, 0.83)
	else
		SetTextFont(0)
		SetTextProportional(1)
		SetTextScale(0.0, 0.25)
		SetTextColour(255, 255, 255, 255)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextEdge(1, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString("Time left: "..timeleft)
		DrawText(0.1, 0.83)
	end
end

function DrawInfoAboutLoadedRace(race)
	SetTextFont(1)
	SetTextProportional(1)
	SetTextScale(0.0, 1.2)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString("Next race:")
	DrawText(0.03, 0.25)
	
	SetTextFont(1)
	SetTextProportional(1)
	SetTextScale(0.0, 1.2)
	SetTextColour(100, 100, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(race.name)
	DrawText(0.03, 0.3)
	
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.3)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextWrap(0.03, 0.3)
	AddTextEntry("RACE_DESCRIPTION", race.description)
	SetTextEntry("RACE_DESCRIPTION")
	DrawText(0.03, 0.4)
end

function DrawSelectedCarInfo(model)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.0, 1.2)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry(model)
	DrawText(0.5, 0.8)
end

function DrawRaceUI()
	local elapsed_time = GetNetworkTime() - start_time
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.25)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString("Lap: "..current_lap.."/"..race.laps.."\nCheckpoint: ".. next_cp_id-1 .. "/"..#race.checkpoints.."\nELAPSED TIME: "..GetTimeAsString(elapsed_time).."\nPOSITION: " .. race_position .."/"..tablelength(players)+1)
	DrawText(0.17, 0.9)
	
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(1.0, 1.0)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(ordinal_number(race_position))
	DrawText(0.94, 0.7)

	-- SetTextFont(0)
	-- SetTextProportional(1)
	-- SetTextScale(0.5, 0.5)
	-- SetTextColour(255, 255, 255, 255)
	-- SetTextDropshadow(0, 0, 0, 0, 255)
	-- SetTextEdge(1, 0, 0, 0, 255)
	-- SetTextDropShadow()
	-- SetTextOutline()
	-- SetTextEntry("STRING")
	-- AddTextComponentString("Boost: " .. tostring(got_boost))
	-- DrawText(0.5, 0.1)
end

function unloadRaceCheckpoints()
	DeleteCheckpoint(cp_handle)
	RemoveBlip(cp_blip_handle)
	RemoveBlip(next_cp_blip_handle)
end

function unloadRaceVehicle()
	if DoesEntityExist(race_vehicle) then
		DeleteEntity(race_vehicle)
	end
end
function unloadPickups()
	for i, p in ipairs(pickups) do
		RemovePickup(p)
	end
end

function processXml(el) -- source: blattersturm/cfx-object-loader
	local v = {}
	local text
	for _,kid in ipairs(el.kids) do
		if kid.type == 'text' then
			text = kid.value
		elseif kid.type == 'element' then
			if not v[kid.name] then
				v[kid.name] = {}
			end

			table.insert(v[kid.name], processXml(kid))
		end
	end
	v._ = el.attr
	if #el.attr == 0 and #el.el == 0 then
		v = text
	end
	return v
end

RegisterNetEvent('racing:setParticipants') -- Server informs clients of the participating racers
AddEventHandler('racing:setParticipants', function (player_server_ids)
	local my_id = tonumber(GetPlayerServerId(PlayerId()))
	players = {}
	for _, id in ipairs(player_server_ids) do
		if tonumber(id) ~= my_id then
			players[id] = {}
			players[id].cp = 1
			local their_local_id = GetPlayerFromServerId(tonumber(id))
			local their_ped = GetPlayerPed(their_local_id)
			local their_blip = GetBlipFromEntity(their_ped)
			if not DoesBlipExist(their_blip) then
				their_blip = AddBlipForEntity(their_ped)
				SetBlipSprite(their_blip, 103)
				SetBlipColour(their_blip, 1)
				SetBlipScale(their_blip, 0.5)
			end
		else
			--nothing
		end
	end
end)

RegisterNetEvent('racing:playerCP') -- Server informs clients that someone passed the cp_id-th checkpoint
AddEventHandler('racing:playerCP', function (player_server_id, cp_id)
	player_server_id = tostring(player_server_id)
	if players[player_server_id] then
		players[player_server_id].cp = cp_id
	else
		if tonumber(player_server_id) ~= GetPlayerServerId(PlayerId()) then
			debugprint("ERROR: Got a playerCP update for a player ("..player_server_id..") that was not configured via setParticipants")
		end
	end
end)

RegisterNetEvent('racing:playerFINISHED') -- Server informs clients that someone finished
AddEventHandler('racing:playerFINISHED', function (player_server_id, position, result_time)
	local my_id = tonumber(GetPlayerServerId(PlayerId()))
	player_server_id = tonumber(player_server_id)
	if my_id == player_server_id then
		NetworkFadeOutEntity(race_vehicle, true, false)
		client_state = ClientStates.FINISHED
		gfx.showCelebration(position, result_time)
	else
		players[tostring(player_server_id)].finishPosition = position
		local their_ped = GetPlayerPed(GetPlayerFromServerId(player_server_id))
		local their_veh = GetVehiclePedIsIn(their_ped)
		ResetEntityAlpha(their_ped)
		ResetEntityAlpha(their_veh)
		local playername = GetPlayerName(GetPlayerFromServerId(player_server_id))
		SetNotificationTextEntry( "STRING" )
		AddTextComponentString("~b~<C>" .. playername .. "</C>~w~ finished " .. ordinal_number(position))
		DrawNotification(false, false ) -- first boolean true makes it flash twice
		--PlaySoundFrontend(-1, audioname, audioref, false) 
	end
end)

RegisterNetEvent("racing:POST") -- Server tells clients to show POST results
AddEventHandler('racing:POST', function (data)
	debugprint("Server gave POST instruction with the following data: \n"..data)
	client_state = ClientStates.POST
	TriggerEvent('racing:showScoreboard', data)
end)

function ordinal_number(n) -- https://stackoverflow.com/a/20694458
  local ordinal, digit = {"st", "nd", "rd"}, string.sub(n, -1)
  if tonumber(digit) > 0 and tonumber(digit) <= 3 and string.sub(n,-2) ~= 11 and string.sub(n,-2) ~= 12 and string.sub(n,-2) ~= 13 then
    return n .. ordinal[tonumber(digit)]
  else
    return n .. "th"
  end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function GTAOTransition(pos, heading, finished_callback)
	Citizen.CreateThread(function()
		local x, y, z = table.unpack(pos)
		local lPed = GetPlayerPed(-1)
		local Lx,Ly,Lz = GetEntityCoords(lPed)
		local distance = Vdist(x, y, z, Lx, Ly , Lz)
		RequestCollisionAtCoord(x, y, z)
		if true then
			local switchingtype = 0
			if distance > 1000 then
				switchingtype = 1 -- far
				else
				switchingtype = 2 -- middle
			end
			local pedhash = GetHashKey("S_M_Y_Clown_01") -- gotta use something ¯\_(ツ)_/¯
			RequestModel(pedhash)
			while not HasModelLoaded(pedhash) do
				Citizen.Wait(0)
			end
			local ped = CreatePed(4, pedhash, x, y, z, 0.0, false, false) -- not networked for obvious reasons
			SetEntityVisible(ped, false, 0)
			StartPlayerSwitch(GetPlayerPed(-1), ped, 0, switchingtype)
			Citizen.Wait(500)
			DeleteEntity(ped) -- don't need him anymore
			while Citizen.InvokeNative(0x470555300D10B2A5) ~= 8 and Citizen.InvokeNative(0x470555300D10B2A5) ~= 10 do -- IS PLAYER SWITCHING (8 is the state where the cam is coming down)
				Citizen.Wait(0)
			end
		end
		SetEntityCoords(lPed, x, y, z, true, false, false, true)
		SetEntityHeading(lPed, heading)
		finished_callback()
	end)
end