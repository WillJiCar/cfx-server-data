-- FiveM.racing scaleform stuff
local canceled = false

local function showIntro(race_name, race_type)
	canceled = false
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)      
			local scaleforms = {}
			scaleforms.mp_celeb_bg = RequestScaleformMovie("MP_CELEBRATION_BG") --A_0
			scaleforms.mp_celeb_fg = RequestScaleformMovie("MP_CELEBRATION_FG") -- A_0+4
			--scaleforms.mp_celeb = RequestScaleformMovie("MP_CELEBRATION") -- A_0 +8
			while not haveScaleformsLoaded(scaleforms) do
				Citizen.Wait(0)
			end
			CreateStatWall(scaleforms, "ch", "HUD_COLOUR_BLUE", -1)
			SetPauseDuration(scaleforms, 3.0)
			AddTextEntry("MRAES_MAPNAME", " ")
			AddTextEntry("MRAES_RACETYPE", " ")
			AddIntroToWall(scaleforms, "ch", "MRAES_RACETYPE", "", "MRAES_MAPNAME", "", nil, nil, nil, nil)
			AddBackgroundToWall(scaleforms, "ch")
			ShowStatWall(scaleforms, "ch")
	   scaleform = RequestScaleformMovie("MP_CELEBRATION")
	   
       while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
       end
       PushScaleformMovieFunction(scaleform, "CREATE_STAT_WALL")
	   PushScaleformMovieFunctionParameterInt(1)
	   PopScaleformMovieFunctionVoid()
	   
	   PushScaleformMovieFunction(scaleform, "ADD_BACKGROUND_TO_WALL")
	   PushScaleformMovieFunctionParameterInt(1)
	   PopScaleformMovieFunctionVoid()
       
	   PushScaleformMovieFunction(scaleform, "ADD_INTRO_TO_WALL")
	   PushScaleformMovieFunctionParameterInt(1)
	   PushScaleformMovieFunctionParameterString(race_type)
	   PushScaleformMovieFunctionParameterString(race_name)
	   PushScaleformMovieFunctionParameterString("")
	   PushScaleformMovieFunctionParameterString("")
	   PushScaleformMovieFunctionParameterString("")
	   PushScaleformMovieFunctionParameterInt()
	   PushScaleformMovieFunctionParameterInt()
	   PushScaleformMovieFunctionParameterString("")
	   PushScaleformMovieFunctionParameterBool(true)
	   PopScaleformMovieFunctionVoid()
		PushScaleformMovieFunction(scaleform, "SET_PAUSE_DURATION")
		PushScaleformMovieFunctionParameterFloat(3.0)
		PopScaleformMovieFunctionVoid()
	   
	   PushScaleformMovieFunction(scaleform, "SHOW_STAT_WALL")
	   PushScaleformMovieFunctionParameterInt(1)
	   PopScaleformMovieFunctionVoid()
			local starttime = GetNetworkTime()
            while GetNetworkTime() - starttime < 4500 and not canceled do
				DrawScaleformMovieFullscreenMasked(scaleforms.mp_celeb_bg, scaleforms.mp_celeb_fg, 0, 255, 255, 180)
				DrawScaleformMovieFullscreen(scaleform, 255,255,255,255)
				HideHUDThisFrame()
				Citizen.Wait(0)
            end
			CleanUp(scaleforms, "ch")
		PushScaleformMovieFunction(scaleform, "CLEANUP")
		PushScaleformMovieFunctionParameterInt(1)
		PopScaleformMovieFunctionVoid()
		SetScaleformMovieAsNoLongerNeeded(scaleform)
			return -- end thread
		end
  end)
end

local function startCountdown(countFrom)
	canceled = false
	Citizen.CreateThread(function()
			local scaleform = RequestScaleformMovie("COUNTDOWN")
			while not HasScaleformMovieLoaded(scaleform) do
				Citizen.Wait(0)
			end
			
			for i=countFrom,1,-1 do
				PlaySoundFrontend(-1, "Countdown_1", "DLC_Stunt_Race_Frontend_Sounds", false)
				PushScaleformMovieFunction(scaleform, "SET_MESSAGE")
				PushScaleformMovieFunctionParameterString(tostring(i))
				PushScaleformMovieFunctionParameterInt(240)
				PushScaleformMovieFunctionParameterInt(200)
				PushScaleformMovieFunctionParameterInt(80)
				PushScaleformMovieFunctionParameterBool(true) -- isMP
				PopScaleformMovieFunctionVoid()
				local starttime = GetNetworkTime()
				while GetNetworkTime() - starttime < 1000 do
					DrawScaleformMovieFullscreen(scaleform, 255,255,100,20)
					HideHUDThisFrame()
					Citizen.Wait(0)
				end
			end
			local r, g, b, _ = GetHudColour(18)
			PlaySoundFrontend(-1, "Checkpoint_Finish", "DLC_Stunt_Race_Frontend_Sounds", true)
			PushScaleformMovieFunction(scaleform, "SET_MESSAGE")
			PushScaleformMovieFunctionParameterString("CNTDWN_GO")
			PushScaleformMovieFunctionParameterInt(r)
			PushScaleformMovieFunctionParameterInt(g)
			PushScaleformMovieFunctionParameterInt(b)
			PushScaleformMovieFunctionParameterBool(true)
			PopScaleformMovieFunctionVoid()
			starttime = GetNetworkTime()
			while GetNetworkTime() - starttime < 1000 and not canceled do
				DrawScaleformMovieFullscreen(scaleform, 255,255,100,20)
				HideHUDThisFrame()
				Citizen.Wait(0)
			end
			return
	end)
end

local function setupInstructionalButtons(buttonTbl, txtTbl)
	local scaleform = RequestScaleformMovie("instructional_buttons")
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end
	PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
	PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()
	if #buttonTbl ~= #txtTbl then
		debugprint("Args to setupInstructionalButtons not ok")
	end
	for i=1,#buttonTbl do
		local keyCode = buttonTbl[i]
		print(keyCode)
		local txt = txtTbl[i]
		PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(i-1)
		local btn = GetControlInstructionalButton(0, keyCode, true)
		PushScaleformMovieFunctionParameterString(btn)
		PushScaleformMovieFunctionParameterString(txt)
		PopScaleformMovieFunctionVoid()
		i = i +1
	end
	PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()
	
    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()
	
	return scaleform
end

local function showCelebration(position, result_time)
	canceled = false
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)      
			local scaleforms = {}
			scaleforms.mp_celeb_bg = RequestScaleformMovie("MP_CELEBRATION_BG") --A_0
			scaleforms.mp_celeb_fg = RequestScaleformMovie("MP_CELEBRATION_FG") -- A_0+4
			scaleforms.celeb = RequestScaleformMovie("MP_CELEBRATION") -- A_0 +8
			while not haveScaleformsLoaded(scaleforms) do
				Citizen.Wait(0)
			end
			CreateStatWall(scaleforms, "ch", "HUD_COLOUR_BLACK", -1)
			SetPauseDuration(scaleforms, 4.0)
			AddPositionToWall(scaleforms, "ch", position, "You finished") -- any text is possible
			AddTimeToWall(scaleforms, "ch", Round(result_time), "CELEB_TOTAL_TIME", nil)
			AddBackgroundToWall(scaleforms, "ch")
			ShowStatWall(scaleforms, "ch")
			local starttime = GetNetworkTime()
            while GetNetworkTime() - starttime < 9500 and not canceled do
				DrawScaleformMovieFullscreenMasked(scaleforms.mp_celeb_bg, scaleforms.mp_celeb_fg, 255, 255, 255, 255)
				DrawScaleformMovieFullscreen(scaleforms.mp_celeb, 255,255,255,255)
				HideHUDThisFrame()
				Citizen.Wait(0)
            end
			StartScreenEffect("MinigameEndNeutral", 0, 0)
			PlaySoundFrontend(-1, "SCREEN_FLASH", "CELEBRATION_SOUNDSET")
			CleanUp(scaleforms)
			return -- end thread
		end
	end)
end

local function cancel()
	canceled = true
end

gfx = {showIntro = showIntro, startCountdown = startCountdown, showCelebration = showCelebration, setupInstructionalButtons = setupInstructionalButtons, cancel = cancel}

-- Scaleform functions
function haveScaleformsLoaded(scaleforms)
	local loaded = true
	for _, scaleform in pairs(scaleforms) do
		if not HasScaleformMovieLoaded(scaleform) then
			loaded = false
			break
		end
	end
	return loaded
end

function CreateStatWall(scaleforms, wallID, colourName, fgAlpha)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "CREATE_STAT_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(colourName) -- can be from the HUD_COLOUR_* list
		EndTextCommandScaleformString()
		if fgAlpha then
			PushScaleformMovieFunctionParameterInt(fgAlpha)
		end
		PopScaleformMovieFunctionVoid()
	end
end

function SetPauseDuration(scaleforms, duration)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "SET_PAUSE_DURATION")
		PushScaleformMovieFunctionParameterFloat(duration)
		PopScaleformMovieFunctionVoid()
	end
end

function AddBackgroundToWall(scaleforms, wallID, bgAlpha, textureId)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_BACKGROUND_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		if bgAlpha then
			PushScaleformMovieFunctionParameterInt(bgAlpha)
		end
		if textureId then
			PushScaleformMovieFunctionParameterInt(textureId) -- id=0: nothing, id=1: weird texture, id=2 = the shardtextures (circles from GTA:O) on left and right
		end
		PopScaleformMovieFunctionVoid()
	end
end

function ShowStatWall(scaleforms, wallID)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "SHOW_STAT_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddScoreToWall(scaleforms, wallID, textLabel, score)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_SCORE_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(textLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(score)
		PopScaleformMovieFunctionVoid()
	end
end

function AddPositionToWall(scaleforms, wallID, position, positionLabel)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_POSITION_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(position)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(positionLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterBool(true) -- isPositionLabelRawText
		PushScaleformMovieFunctionParameterBool(false)-- isScore
		PopScaleformMovieFunctionVoid()
	end
end

function AddChallengeWinnerToWall(scaleforms, wallID, challengeTextLabel, winLoseTextLabel, crewName, challengeName, cashAmount, isInFlow, isWinner, isMission, teamName)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_CHALLENGE_WINNER_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengeTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(winLoseTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(crewName)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengeName)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(cashAmount)
		PushScaleformMovieFunctionParameterBool(isInFlow)
		PushScaleformMovieFunctionParameterBool(isWinner)
		PushScaleformMovieFunctionParameterBool(isMission)
		PushScaleformMovieFunctionParameterBool(true) -- isWinLoseLabelRawText
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(teamName)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddTimeToWall(scaleforms, wallID, time, timeTitleLabel, timeDifference)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_TIME_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(time)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(timeTitleLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(timeDifference)
		PopScaleformMovieFunctionVoid()
	end
end

function AddChallengeSetToWall(scaleforms, wallID, score, time, setTextLabel, challengeName)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_CHALLENGE_SET_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(score)
		PushScaleformMovieFunctionParameterInt(time)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(setTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengeName)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddStatNumericToWall(scaleforms, wallID, statLabel, statValue, xAlign)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_STAT_NUMERIC_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(statLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(statValue)
		PushScaleformMovieFunctionParameterInt(xAlign)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(xAlign)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddCashWonToWall(scaleforms, wallID, statLabel, statValue, potentialValue, xAlign)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_CASH_WON_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(statLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(statValue)
		PushScaleformMovieFunctionParameterInt(potentialValue)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(xAlign)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterBool(true)
		PopScaleformMovieFunctionVoid()
	end
end

function AddWaveReachedToWall(scaleforms, wallID, waveText, reachedLabel)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_WAVE_REACHED_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(waveText)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(reachedLabel)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddWorldRecordToWall(scaleforms, wallID, time)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_WORLD_RECORD_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(time)
		PopScaleformMovieFunctionVoid()
	end
end

function AddTournamentToWall(scaleforms, wallID, playlistName, qualificationLabel, resultText, isResultTextRawText, resultValue)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_TOURNAMENT_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(playlistName)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(qualificationLabel)
		EndTextCommandScaleformString()
		Citizen.InvokeNative(0xE83A3E3557A56640, resultText)
		PushScaleformMovieFunctionParameterBool(isResultTextRawText)
		PushScaleformMovieFunctionParameterInt(resultValue)
		PopScaleformMovieFunctionVoid()
	end
end

function AddIntroToWall(scaleforms, wallID, modeLabel, jobName, challengeTextLabel, challengePartsText, targetTypeTextLabel, targetValue, delay, targetValuePrefix)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_INTRO_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(modeLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(jobName)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengeTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengePartsText)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(targetTypeTextLabel)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterInt(targetValue)
		PushScaleformMovieFunctionParameterFloat(delay)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(targetValuePrefix)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function AddReadyToWall(scaleforms, wallID, readyLabel)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_READY_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(readyLabel)
		EndTextCommandScaleformString()
		
		PopScaleformMovieFunctionVoid()
	end
end

function AddChallengePartToWall(scaleforms, wallID, winLoseTextLabel, challengePartsText)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_CHALLENGE_PART_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(winLoseTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(challengePartsText)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
	end
end

function CreateStatTable(scaleforms, wallID, tableID)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "CREATE_STAT_TABLE")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(tableID)
		EndTextCommandScaleformString()
		
		PopScaleformMovieFunctionVoid()
	end
end

function AddStatToTable(scaleforms, wallID, tableID, statText, statValue, isStatTextRawText, isStatValueRawText, isTotalRow, isStatValueTime, colour)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_STAT_TO_TABLE")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(tableID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(statText)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(statValue)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterBool(isStatTextRawText)
		PushScaleformMovieFunctionParameterBool(true)
		PushScaleformMovieFunctionParameterBool(isTotalRow)
		PushScaleformMovieFunctionParameterBool(isStatValueTime)
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(colour)
		EndTextCommandScaleformString()
		
		PopScaleformMovieFunctionVoid()
	end
end

function AddStatTableToWall(scaleforms, wallID, tableID)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_STAT_TABLE_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(tableID)
		EndTextCommandScaleformString()
		
		PopScaleformMovieFunctionVoid()
	end
end


function AddMissionResultToWall(scaleforms, wallID, missionTextLabel, passFailTextLabel, missionReasonString, isReasonRawText, isPassFailRawText)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_MISSION_RESULT_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(missionTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(passFailTextLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(missionReasonString)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterBool(isReasonRawText)
		PushScaleformMovieFunctionParameterBool(isPassFailRawText)
		PopScaleformMovieFunctionVoid()
	end
end



function AddObjectiveToWall(scaleforms, wallID, objectiveTitleLabel, objectiveText)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "ADD_OBJECTIVE_TO_WALL")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(objectiveTitleLabel)
		EndTextCommandScaleformString()
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(objectiveText)
		EndTextCommandScaleformString()
		PushScaleformMovieFunctionParameterBool(true)
		PopScaleformMovieFunctionVoid()
	end
end


function CleanUp(scaleforms, wallID)
	for _, scaleform in pairs(scaleforms) do
		PushScaleformMovieFunction(scaleform, "CLEANUP")
		BeginTextCommandScaleformString("STRING")
		AddTextComponentSubstringPlayerName(wallID)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
		SetScaleformMovieAsNoLongerNeeded(scaleform)
	end

	canceled = false
end

-- Natives
function BeginTextCommandScaleformString(componentType)
	Citizen.InvokeNative(0x80338406F3475E55, componentType)
end

function EndTextCommandScaleformString()
	Citizen.InvokeNative(0x362E2D3FE93A9959)
end

function AddTextComponentSubstringPlayerName(s)
	Citizen.InvokeNative(0x6C188BE134E074AA, s)
end