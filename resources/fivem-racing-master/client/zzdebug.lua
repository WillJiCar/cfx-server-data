--FiveM.racing various debug thingies
local debugMode = true

if not debugMode then
    function debugprint(txt)
    end

    return
end

function debugprint(txt)
	print("[racing] " ..txt)
end

server_state = ""
RegisterNetEvent('racing:serverState')
AddEventHandler('racing:serverState', function (state)
	server_state = state
end)

function DrawDebugUI()
	infostring = "S_STATE: " ..server_state .. "\nC_STATE: " .. client_state
	if client_state == ClientStates.INIT or client_state == ClientStates.LOADING then
	else
		infostring = infostring .. "\nTIME: " .. race.rules.timeofday
		infostring = infostring .. "\nWEATHER: " .. race.rules.weather
		infostring = infostring .. "\nTRAFFIC: " .. race.rules.trafficdensity
	end
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.25)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(infostring)
	DrawText(0.85, 0.01)
end
Citizen.CreateThread(function()
	while true do
		DrawDebugUI()
		Citizen.Wait(0)
	end
end)

-- debug commands
RegisterCommand("spawnveh", function(source, args, rawCommand)
    local ped = PlayerPedId()
	local veh = GetVehiclePedIsIn(ped, false)
	local pos = GetEntityCoords(ped)
	localheading = GetEntityHeading(ped)
	local model = args[1]
	if tonumber(model) ~= nil then
		model = tonumber(model)
	end
	local started_at = GetNetworkTime()
	while (not HasModelLoaded(model)) and GetNetworkTime()-started_at < 500 do
		RequestModel(model)
		Wait(0)
	end
	if HasModelLoaded(model) then
		local spawned_veh = CreateVehicle(model, pos, head, true, false)
		SetPedIntoVehicle(ped, spawned_veh, -1)
		if DoesEntityExist(veh) then
			DeleteEntity(veh)
		end
		local class = GetVehicleClassFromName(args[1])
		local lbl = "VEH_CLASS_" .. class
		print(lbl)
		print(GetLabelText(lbl))
	else
		print("could not spawn that model")
	end
end, false)

RegisterCommand("hash", function(source, args, rawCommand)
	print(GetHashKey(args[1]))
end, false)


-- --[[
-- PushScaleformMovieFunctionParameterString()
-- PushScaleformMovieFunctionParameterInt()
-- PushScaleformMovieFunctionParameterFloat()
-- PushScaleformMovieFunctionParameterBool()
-- ]]
-- -- SET_GRID_ITEM(i, sTitle, sTXD, sTXN, textureLoadType, verifiedType, eIcon, bCheck, rpMult, cashMult, bDisabled, iconCol)
-- Citizen.CreateThread(function()
    -- function Initialize(scaleform)
        -- local scaleform = RequestScaleformMovie(scaleform)
        -- while not HasScaleformMovieLoaded(scaleform) do
            -- Citizen.Wait(0)
        -- end

        -- PushScaleformMovieFunction(scaleform, "SET_TITLE")
        -- PushScaleformMovieFunctionParameterString("What Next?")
        -- PushScaleformMovieFunctionParameterString("Votes: ")
        -- PopScaleformMovieFunctionVoid()

        -- PushScaleformMovieFunction(scaleform, "SET_GRID_ITEM")
        -- PushScaleformMovieFunctionParameterInt(0)
        -- PushScaleformMovieFunctionParameterString("Some Cool Race")
        -- PushScaleformMovieFunctionParameterString("Votes: ")
        -- PushScaleformMovieFunctionParameterString("Votes: ")
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PushScaleformMovieFunctionParameterString("No")
        -- PushScaleformMovieFunctionParameterInt(2)
        -- PushScaleformMovieFunctionParameterInt(2)
        -- PushScaleformMovieFunctionParameterInt(3)
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PopScaleformMovieFunctionVoid()

        -- PushScaleformMovieFunction(scaleform, "SET_GRID_ITEM")
        -- PushScaleformMovieFunctionParameterInt(0)
        -- PushScaleformMovieFunctionParameterString("Some Cool Race")
        -- PushScaleformMovieFunctionParameterString("Votes: ")
        -- PushScaleformMovieFunctionParameterString("Votes: ")
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PushScaleformMovieFunctionParameterInt(2)
        -- --PushScaleformMovieFunctionParameterInt(0)
        -- --PushScaleformMovieFunctionParameterInt(0)
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PushScaleformMovieFunctionParameterInt(1)
        -- PopScaleformMovieFunctionVoid()

        -- return scaleform
    -- end
    -- scaleform = Initialize("mp_next_job_selection")
    -- while true do
        -- Citizen.Wait(0)
        -- DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    -- end
-- end)

-- Citizen.CreateThread(function()
    -- local hash = -2082168399
    -- while true do
        -- if (not IsNamedRendertargetRegistered("prop_ex_office_text")) then
            -- RegisterNamedRendertarget("prop_ex_office_text", 0)
            -- LinkNamedRendertarget(hash)
            -- if (not IsNamedRendertargetLinked(hash)) then
                -- ReleaseNamedRendertarget("prop_ex_office_text")
            -- end
        -- end
        -- local texttarget = GetNamedRendertargetRenderId("prop_ex_office_text")
        -- SetTextRenderId(texttarget)
        -- DrawRect(0.0, 0.0, 2.0, 2.0, 0, 0, 0, 255) -- Outer Box
        -- drawText('~r~Titlelicious',4,1,0.5,0.150,1.5,255,255,255,255)
        -- drawText('I like turtles',4,1,0.5,0.750,0.5,255,255,255,255)
        -- drawText('Meow',4,1,0.95,0.850,0.5,255,255,255,150)
        -- SetTextRenderId(GetDefaultScriptRendertargetRenderId())
        -- Citizen.Wait(0)
    -- end
-- end)

-- list of rendertarget names


-- cinscreen
-- npcphone
-- tvscreen
-- ex_tvscreen
-- gr_trailer_monitor_01
-- gr_trailer_monitor_02
-- gr_trailer_monitor_03
-- gr_trailerTV_01
-- gr_trailerTV_02
-- prop_clubhouse_laptop_01a
-- gr_bunker_laptop_01a
-- Prop_ImpExp_Lappy_01a
-- prop_ex_computer_screen
-- clubname_blackboard_01a
-- memorial_wall_president
-- memorial_wall_vice_president
-- memorial_wall_active_01
-- memorial_wall_active_02
-- memorial_wall_active_03
-- clubhouse_table
-- Prop_Screen_DCTL
-- prop_ex_computer_screen
-- prop_ex_office_text
-- clubhouse_Plan_01a
-- port_text
-- starb_text
-- stern_text
-- taxi
-- digiscanner
-- ECG
-- blimp_text
-- ID_Text
-- ID_Text_02