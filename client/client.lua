-- Varaibles

local Frisbee, FrisbeeBlip, FrisbeeDude, RestrictedPos, Camera
local FrisbeeType = "frisbee"
local Message = ""
local HelpMessage = ""


-- Tables

local HoleZones = {}
local FrisbeeTees = {}
local TeeBlips = {}
local SpectatorTees = {}
local FrisbeeTargets = {}
local HoleBlips = {}
local SpectatorHoles = {}
local DisplayFrisbees = {}
local PracticeHoles = {}
local Scorecard = {}
local SavedScorecard = {}
local FrisbeeTypes = {
	["frisbee"] = "gg_prop_frisbee",
	["frisbee_r"] = "gg_prop_frisbee_r",
	["frisbee_g"] = "gg_prop_frisbee_g",
	["frisbee_b"] = "gg_prop_frisbee_b",
	["frisbee_y"] = "gg_prop_frisbee_y",
}


-- Flags

local FrisbeeGolfAllowed = true
local StatusLoaded = false
local FrisbeeCreated = false
local FrisbeeOut = false
local FrisbeeStopped = false
local PlayingFrisbeeGolf = false
local AnyonePlaying = false
local FrisbeeDudeSpawned = false
local CourseSpawned = false
local PracticeHolesSpawned = false
local HoleZoneCreated = false
local InDropRange = false
local Aiming = false
local RunMessage = false
local RunHelpMessage = false
local MessageRunning = false
local CamCreated = false
local InInventory = false -- for Standalone


-- Initialize

if not Config.Standalone then
	QBCore = exports['qb-core']:GetCoreObject()
end
local Pitch = Config.Pitch
local Velocity = Config.Velocity
local Roll = Config.Roll
local Gravity = Config.Gravity
local CurrentHole = 0
local CurrentThrow = 0

Citizen.CreateThread(function()
	while not StatusLoaded do
		TriggerServerEvent ('gg-frisbee:server:isanyoneplaying')
		Wait(5000)
	end
	if Config.Standalone then
		local FDBlip = AddBlipForCoord(Config.FrisbeeDude.Location.x, Config.FrisbeeDude.Location.y, Config.FrisbeeDude.Location.z)
		SetBlipSprite(FDBlip, 540)
		SetBlipColour(FDBlip, 0)
		SetBlipScale(FDBlip, 0.6)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentSubstringPlayerName("Frisbee Stand")
		EndTextCommandSetBlipName(FDBlip)
	end
end)


-- Events

RegisterNetEvent('gg-frisbee:client:createfrisbee')
AddEventHandler('gg-frisbee:client:createfrisbee', function(ftype)
	if not DoesEntityExist(Frisbee) then
		FrisbeeType = ftype
		EquipFrisbee()
	else
		DrawNativeTextMessage("You already have a frisbee in use", 3000)
	end
end)

RegisterNetEvent('gg-frisbee:client:playerplaying')
AddEventHandler('gg-frisbee:client:playerplaying', function(isplaying)
	AnyonePlaying = isplaying
	StatusLoaded = true
	if not AnyonePlaying then
		for i, _ in ipairs(SpectatorHoles) do
			if DoesEntityExist(SpectatorHoles[i]) then DeleteObject(SpectatorHoles[i]) end
			if DoesEntityExist(SpectatorTees[i]) then DeleteObject(SpectatorTees[i]) end
		end
		CourseSpawned = false
	end
end)

RegisterNetEvent('gg-frisbee:client:savedscore')
AddEventHandler('gg-frisbee:client:savedscore', function(savedscore)
	SavedScorecard = savedscore -- can be nil
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	ClearPedTasks(PlayerPedId())
	FreezeEntityPosition(PlayerPedId(), false)
end)


-- NUI

function OpenScorecard()
	SendNUIMessage({
		action = "open",
		holes = Config.FrisbeeGolfCourse,
		scores = Scorecard,
		savedscores = SavedScorecard
	})
	SetNuiFocus(true, true)
end

RegisterNUICallback("close", function()
	SetNuiFocus(false, false)
end)

RegisterNUICallback("save", function()
	SetNuiFocus(false, false)
	SaveScorecard(Scorecard)
end)


-- Functions

function CreateFrisbee(x, y, z, rx, ry, rz, ftype, frominv) -- rot 5
	if not DoesEntityExist(Frisbee) then
		Frisbee = CreateObject(GetHashKey(FrisbeeTypes[ftype]), x, y, z, true, true, false)
		SetEntityRotation(Frisbee, rx, ry, rz, 5, true)
		while not DoesEntityExist(Frisbee) do Wait(5) end
		Wait(100)
		TriggerServerEvent('gg-frisbee:server:frisbeecreated', NetworkGetNetworkIdFromEntity(Frisbee), ftype, frominv)
		FrisbeeCreated = true
		InInventory = false
	end
end

function DeleteFrisbee(frominv)
	TriggerServerEvent('gg-frisbee:server:frisbeedeleted', NetworkGetNetworkIdFromEntity(Frisbee), FrisbeeType, frominv)
	DeleteObject(Frisbee)
	FrisbeeOut = false
	local PlayerPed = PlayerPedId()
	RemoveBlip(FrisbeeBlip)
	ClearPedTasks(PlayerPed)
	FreezeEntityPosition(PlayerPed, false)
end

function EquipFrisbee()
	local PlayerPed = PlayerPedId()
	if not DoesEntityExist(Frisbee) then
		local FrisbeeSpawnPos = GetOffsetFromEntityInWorldCoords(PlayerPed, 0.15, 0.15, -0.1)
		CreateFrisbee(FrisbeeSpawnPos.x, FrisbeeSpawnPos.y, FrisbeeSpawnPos.z, 0.0, 0.0, 0.0, FrisbeeType, true)
		while not FrisbeeCreated do Wait(5) end
	end
	FrisbeeOut = false
	AttachEntityToEntity(Frisbee, PlayerPed, GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.1700, 0.0200, -0.1300, 0.0000, -28.0000, 52.0000, true, true, false, true, 1, true)
	RequestAnimDict("amb@world_human_tourist_map@female@idle_a")
	while not HasAnimDictLoaded("amb@world_human_tourist_map@female@idle_a") do Citizen.Wait(5) end
	local RandomAnim = {"idle_a", "idle_b", "idle_c"}
	TaskPlayAnim(PlayerPed, "amb@world_human_tourist_map@female@idle_a", RandomAnim[math.random(1, #RandomAnim)], 4.0, 4.0, -1, 49, 0.0, 0, 0, 0)
	Aiming = false
	Citizen.CreateThread(
		function()
			if PlayingFrisbeeGolf then
				HelpMessage = "Press ~INPUT_PICKUP~ to aim frisbee~n~Press ~INPUT_FRONTEND_RRIGHT~ to put frisbee away~n~Press ~INPUT_DETONATE~ to view scorecard"
			else
				HelpMessage = "Press ~INPUT_PICKUP~ to aim frisbee~n~Press ~INPUT_FRONTEND_RRIGHT~ to put frisbee away"
			end
			RunHelpMessage = true
			DrawNativeTextHelpMessage()
			while DoesEntityExist(Frisbee) and not Aiming do
				if IsControlJustReleased(0, 38) then -- E key
					RunHelpMessage = false
					Aiming = true
					AimFrisbee()
				end
				if IsControlJustReleased(0, 194) then -- BACKSPACE key
					RunHelpMessage = false
					DeleteFrisbee(true)
					InInventory = true
					local TextMessage = "You put your frisbee away"
					if Config.Standalone then
						TextMessage = TextMessage .. "~n~/frisbee to retrieve"
					end
					DrawNativeTextMessage(TextMessage, 3000)
				end
				if IsControlJustReleased(0, 47) and PlayingFrisbeeGolf then -- G key
					OpenScorecard()
				end
				Citizen.Wait(5)
			end
		end
	)
end

function FrisbeeMonitor()
	local PlayerPed = PlayerPedId()
	local Instructed = false
	local WaitTime = 500
	Citizen.CreateThread(
		function()
			while FrisbeeOut do
				local PlayerPos = GetEntityCoords(PlayerPed)
				local FrisbeePos = GetEntityCoords(Frisbee)
				local FrisbeeRot = GetEntityRotation(Frisbee, 5)
				local DistToFrisbee = #(PlayerPos - FrisbeePos)
				if DistToFrisbee < 1.5 then
					if not Instructed then
						HelpMessage = "Press ~INPUT_PICKUP~ to pick up Frisbee"
						RunHelpMessage = true
						DrawNativeTextHelpMessage()
						Instructed = true
					end
					if IsControlJustReleased(0, 38) then -- E key
						FreezeEntityPosition(PlayerPed, true)
						local PlayerToHead = GetHeadingFromVector_2d(FrisbeePos.x - PlayerPos.x, FrisbeePos.y - PlayerPos.y)
						SetEntityHeading(PlayerPed, PlayerToHead)
						if (PlayerPos.z - FrisbeePos.z) > 0.5 then
							RequestAnimDict("pickup_object")
							while not HasAnimDictLoaded("pickup_object") do Wait(5) end
							TaskPlayAnim(PlayerPed, "pickup_object" , "pickup_low", 5.0, 4.0, -1, 0, 0, false, false, false)
							Citizen.Wait(800)
						else
							RequestAnimDict("creatures@rottweiler@tricks@")
							while not HasAnimDictLoaded("creatures@rottweiler@tricks@") do Citizen.Wait(5) end
							TaskPlayAnim(PlayerPed, "creatures@rottweiler@tricks@", "petting_franklin", 8.0, 4.0, -1, 0, 0, false, false, false)
							Citizen.Wait(1500)
						end
						FreezeEntityPosition(PlayerPed, false)
						DeleteFrisbee(false)
						FrisbeeCreated = false
						while DoesEntityExist(Frisbee) do Wait(5) end
						CreateFrisbee(FrisbeePos.x, FrisbeePos.y, FrisbeePos.z, FrisbeeRot.x, FrisbeeRot.y, FrisbeeRot.z, FrisbeeType, false)
						while not FrisbeeCreated do Wait(5) end
						EquipFrisbee()
						RemoveBlip(FrisbeeBlip)
					end
					WaitTime = 5
				end
				if DistToFrisbee > 3.0 then
					Instructed = false
					RunHelpMessage = false
					WaitTime = 100
				end
				Citizen.Wait(WaitTime)
			end
		end
	)
end

function AimFrisbee()
	if Config.AimReset then AimReset() end
	local PlayerPed = PlayerPedId()
	HelpMessage = "~INPUT_CELLPHONE_LEFT~~INPUT_CELLPHONE_RIGHT~ Heading~n~~INPUT_CELLPHONE_UP~~INPUT_CELLPHONE_DOWN~ Velocity~n~~INPUT_VEH_FLY_PITCH_UP_ONLY~~INPUT_VEH_FLY_PITCH_DOWN_ONLY~ Pitch~n~~INPUT_VEH_FLY_ROLL_LEFT_ONLY~~INPUT_VEH_FLY_ROLL_RIGHT_ONLY~ Curve~n~~INPUT_FRONTEND_ACCEPT~ Throw ~INPUT_FRONTEND_RRIGHT~ Cancel~n~~INPUT_DETONATE~ Reset"
	if InDropRange then
		HelpMessage = HelpMessage .. "~n~Press ~INPUT_VEH_HEADLIGHT~ for drop-in"
	end
	RunHelpMessage = true
	DrawNativeTextHelpMessage()
	Message = ""
	RunMessage = true
	DrawNativeTextRunningMessage()
	if PlayingFrisbeeGolf then
		DrawRestrictedZone()
	end
	local LastPress = 0
	local IncrementTime = 100
	local IndicatorScale = Config.IndicatorScale
	local PointerLength = Config.IndicatorPointerLength
	local DrawIndicator = Config.UseIndicator
	Citizen.CreateThread(
		function()
			while Aiming do
				FreezeEntityPosition(PlayerPed, true)
				local PlayerPos = GetEntityCoords(PlayerPed)
				local PlayerHead = GetEntityHeading(PlayerPed)
				local StartPos = GetOffsetFromEntityInWorldCoords(PlayerPed, -0.3, 0.5, 0.0)
				local StartHead = PlayerHead - 90.0
				if IsControlPressed(0, 174) then -- Arrow Left key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						SetEntityHeading(PlayerPed, PlayerHead + 0.5)
					end
				end
				if IsControlPressed(0, 175) then -- Arrow Right key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						SetEntityHeading(PlayerPed, PlayerHead - 0.5)
					end
				end
				if IsControlPressed(0, 111) then -- NUMPAD8 key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) >  IncrementTime then
						LastPress = CurTime
						Pitch = Pitch + 1.0
						if Pitch > 90.0 then Pitch = 90.0 end
					end
				end
				if IsControlPressed(0, 112) then -- NUMPAD5 key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						Pitch = Pitch - 1.0
						if Pitch < 0.0 then Pitch = 0.0 end
					end
				end
				if IsControlPressed(0, 172) then -- Arrow Up key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						Velocity = Velocity + 0.5
						if Velocity > 30.0 then Velocity = 30.0 end
					end
				end
				if IsControlPressed(0, 173) then -- Arrow Down key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						Velocity = Velocity - 0.5
						if Velocity < 1.0 then Velocity = 1.0 end
					end
				end
				if IsControlPressed(0, 108) then -- NUMPAD4 key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						Roll = RoundOff(Roll - 0.1, 1)
						if Roll < -1.0 then Roll = -1.0 end
					end
				end
				if IsControlPressed(0, 109) then -- NUMPAD6 key
					local CurTime = GetGameTimer()
					if (CurTime - LastPress) > IncrementTime then
						LastPress = CurTime
						Roll = RoundOff(Roll + 0.1, 1)
						if Roll > 1.0 then Roll = 1.0 end
					end
				end
				if IsControlJustReleased(0, 47) then -- G key
					AimReset()
				end
				if IsControlJustReleased(0, 74) then -- H key
					if PlayingFrisbeeGolf and Config.Strict then
						local DistCheck = #(vector2(PlayerPos.x, PlayerPos.y) - vector2(RestrictedPos.x, RestrictedPos.y)) -- exclude z
						if DistCheck < Config.StrictDist then
							if InDropRange then
								DrawIndicator = false
								RunHelpMessage = false
								ThrowFrisbee(true)
								Aiming = false
							end
						else
							DrawNativeTextMessage("Outside of legal position", 3000)
						end
					else
						if InDropRange then
							DrawIndicator = false
							RunHelpMessage = false
							ThrowFrisbee(true)
							Aiming = false
						end
					end
				end
				if IsControlJustReleased(0, 201) then -- ENTER key
					if PlayingFrisbeeGolf and Config.Strict then
						local DistCheck = #(vector2(PlayerPos.x, PlayerPos.y) - vector2(RestrictedPos.x, RestrictedPos.y)) -- exclude z
						if DistCheck < Config.StrictDist then
							DrawIndicator = false
							RunHelpMessage = false
							ThrowFrisbee()
							Aiming = false
						else
							DrawNativeTextMessage("Outside of legal position", 3000)
						end
					else
						DrawIndicator = false
						RunHelpMessage = false
						ThrowFrisbee()
						Aiming = false
					end
				end
				if IsControlJustReleased(0, 194) then -- BACKSPACE key
					DrawIndicator = false
					RunHelpMessage = false
					Aiming = false
					EquipFrisbee()
				end
				Message = "H: " .. RoundOff(PlayerHead, 1) .. "°~n~V: " .. RoundOff(Velocity, 1) .. "m/s~n~P: " .. math.floor(Pitch) .. "°~n~C: " .. Roll
				if PlayingFrisbeeGolf and CurrentHole > 0 then
					local DistToHole = RoundOff(#(PlayerPos - Config.FrisbeeGolfCourse[CurrentHole].Hole), 1)
					Message = Message .. "~n~🚩~y~" .. DistToHole .. "m~w~~s~"
				end
				if 	DrawIndicator then
					local VelRef = GetObjectOffsetFromCoords(StartPos, StartHead, -1.0 * IndicatorScale * (Velocity/30), 0.0, 0.0)
					local PitchRef = GetObjectOffsetFromCoords(StartPos, StartHead, -1.0 * IndicatorScale * math.cos(math.rad(Pitch)) * (Velocity / 30), 0.0, IndicatorScale * math.sin(math.rad(Pitch)) * (Velocity / 30))
					local RollRef = GetObjectOffsetFromCoords(StartPos, StartHead, 0.0, IndicatorScale * Roll * (Velocity / 30), 0.0)
					local AimRefX = GetObjectOffsetFromCoords(StartPos, StartHead, -1 * PointerLength * IndicatorScale, 0.0, 0.0)
					local AimRefYp = GetObjectOffsetFromCoords(StartPos, StartHead, 0.0, 1.0 * IndicatorScale, 0.0)
					local AimRefYn = GetObjectOffsetFromCoords(StartPos, StartHead, 0.0, -1.0 * IndicatorScale, 0.0)
					local AimRefZ = GetObjectOffsetFromCoords(StartPos, StartHead,  -1.0 * IndicatorScale * math.cos(math.rad(Pitch)), 0.0, IndicatorScale * math.sin(math.rad(Pitch)))
					DrawLine(StartPos, AimRefX, 255, 255, 255, 200)
					DrawLine(StartPos, AimRefYp, 255, 255, 255, 200)
					DrawLine(StartPos, AimRefYn, 255, 255, 255, 200)
					DrawLine(StartPos, AimRefZ, 255, 255, 255, 200)
					DrawPoly(StartPos, VelRef, PitchRef, 255, 255, 255, 51) -- right side
					DrawPoly(StartPos, PitchRef, VelRef, 255, 255, 255, 51) -- left side
					DrawPoly(StartPos, VelRef, RollRef, 255, 255, 255, 51) -- top neg / bottom pos
					DrawPoly(StartPos, RollRef, VelRef, 255, 255, 255, 51) -- top pos / bottom neg
				end
				if not DoesEntityExist(Frisbee) then
					Aiming = false
				end
				Citizen.Wait(0)
			end
			FreezeEntityPosition(PlayerPed, false)
			RunMessage = false
		end
	)
end

function ThrowFrisbee(drop)
	local PlayerPed = PlayerPedId()
	local PlayerPos = GetEntityCoords(PlayerPedId())
	local PlayerHead = GetEntityHeading(PlayerPed)
	local StartPos = GetOffsetFromEntityInWorldCoords(PlayerPed,  -0.3, 0.5, 0.0)
	local StartHead = PlayerHead + 90.0
	local AimRef = GetObjectOffsetFromCoords(StartPos, StartHead, 10.0, 0.0, 0.0)
	local VelocityInitialX = Velocity * math.cos(math.rad(Pitch))
	local VelocityInitialY = Velocity * math.sin(math.rad(Pitch))
	local DoOneTime = true
	if not drop then
		ClearPedTasks(PlayerPed)
		RequestAnimDict("mini@tennis")
		while not HasAnimDictLoaded("mini@tennis") do Citizen.Wait(5) end
		TaskPlayAnim(PlayerPedId(), "mini@tennis", "backhand", 4.0, 1.0, 1, 2, 0.0, 0, 0, 0)
		Wait(100)
		DetachEntity(Frisbee, true, true)
		SetEntityCoords(Frisbee, StartPos.x, StartPos.y, StartPos.z)
		SetEntityRotation(Frisbee, 90.0 + 30 * Roll, 0.0, StartHead, 2, true)
		FreezeEntityPosition(Frisbee, true)
		Wait(1)
		SetObjectPhysicsParams(Frisbee, 0.19, Gravity / 9.81, 0.0, 0.0, 0.01, -1.0, -1.0, -1.0, -1.0, 50.0, -1.0)
		ActivatePhysics(Frisbee)
		while not DoesEntityHavePhysics(Frisbee) do Wait(1) end
		FreezeEntityPosition(Frisbee, false)
		while IsEntityPositionFrozen(Frisbee) do Wait(1) end
		local VelocityComposite = vector3(VelocityInitialX * math.cos(math.rad(StartHead)), VelocityInitialX * math.sin(math.rad(StartHead)), VelocityInitialY)
		SetEntityVelocity(Frisbee, VelocityComposite)
		SetEntityRotation(Frisbee, 90.0 + (30 * Roll), 0.0, StartHead, 2, true)
		if VelocityInitialY > 10.0 then -- use cam for long distance throws to fix physics bugs in multiplayer
			SetupFrisbeeCam()
		end
	else
		FreezeEntityPosition(PlayerPed, true)
		local HolePos = Config.FrisbeeGolfCourse[CurrentHole].Hole
		local PlayerToHead = GetHeadingFromVector_2d(HolePos.x - PlayerPos.x, HolePos.y - PlayerPos.y)
		SetEntityHeading(PlayerPed, PlayerToHead)
		Citizen.Wait(1000)
		ClearPedTasksImmediately(PlayerPed)
		RequestAnimDict("anim@heists@narcotics@trash")
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do Citizen.Wait(5) end
		TaskPlayAnim(PlayerPed, "anim@heists@narcotics@trash", "throw", 4.0, 4.0, -1, 0, 0.0, 0, 0, 0)
		Citizen.Wait(500)
		DetachEntity(Frisbee, true, true)
		while IsEntityAttached(Frisbee) do Wait(5) end
		local DropPos = GetObjectOffsetFromCoords(Config.FrisbeeGolfCourse[CurrentHole].Hole, PlayerToHead - 180.0, -0.2, 0.0, 1.2)
		SetEntityCoords(Frisbee, DropPos)
		FreezeEntityPosition(Frisbee, false)
		FreezeEntityPosition(PlayerPed, false)
	end
	FrisbeeOut = false
	FrisbeeStopped = false
	if PlayingFrisbeeGolf then
		CurrentThrow = CurrentThrow + 1
	end
	Citizen.CreateThread(
		function()
			local BaselineColl = GetCollisionNormalOfLastHitForEntity(Frisbee)
			local BaselineVel = GetEntityVelocity(Frisbee)
			FrisbeeBlip = AddBlipForEntity(Frisbee)
			SetBlipColour(FrisbeeBlip, 0)
			SetBlipScale(FrisbeeBlip, 0.7)
			RequestScriptAudioBank('Tennis', 0)
			while DoesEntityExist(Frisbee) and not FrisbeeOut do
				local CurrentVel = GetEntityVelocity(Frisbee)
				local CurrentAVel = GetEntityRotationVelocity(Frisbee)
				if Roll ~= 0 then
					ApplyForceToEntity(Frisbee, 1, (Velocity/10) * math.cos(math.rad(PlayerHead)) * Roll / 50, (Velocity/10) * math.sin(math.rad(PlayerHead)) * Roll / 50, 0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
				else
					SetEntityAngularVelocity(Frisbee, 0.0, 0.0, -30.0)
				end
				local FrisbeePos = GetEntityCoords(Frisbee)
				if PlayingFrisbeeGolf then
					if (DoOneTime and HoleZones[CurrentHole] ~= nil) then
						if HoleZones[CurrentHole]:isPointInside(FrisbeePos) then
							PlaySoundFromCoord(-1, Config.FrisbeeGolfTargets[Config.FrisbeeGolfCourse[CurrentHole].HoleProp].Sound[1], GetEntityCoords(Frisbee), Config.FrisbeeGolfTargets[Config.FrisbeeGolfCourse[CurrentHole].HoleProp].Sound[2], 0, 0, 0)
							SetEntityVelocity(Frisbee, 0.0, 0.0, -1.0)
							SetEntityAngularVelocity(Frisbee, 0.0, 0.0, 0.0)
							DoOneTime = false
						end
					end
				else
					if (DoOneTime and PracticeHolesSpawned) then
						for k,v in pairs(Config.Practice) do
							if HoleZones[k]:isPointInside(FrisbeePos) then
								PlaySoundFromCoord(-1, Config.FrisbeeGolfTargets[v.HoleProp].Sound[1], GetEntityCoords(Frisbee), Config.FrisbeeGolfTargets[v.HoleProp].Sound[2], 0, 0, 0)
								SetEntityVelocity(Frisbee, 0.0, 0.0, -1.0)
								SetEntityAngularVelocity(Frisbee, 0.0, 0.0, 0.0)
								DoOneTime = false
							end
						end
					end
				end
				if GetCollisionNormalOfLastHitForEntity(Frisbee) ~= BaselineColl then
					PlaySoundFromCoord(-1, 'TENNIS_CLS_BALL_MASTER', GetEntityCoords(Frisbee), 0, false, 150.0, 0)
					PlaySoundFromEntity(-1, 'TENNIS_CLS_BALL_MASTER', Frisbee, 0, true, 0)
					local CurrentVelMag = math.sqrt((CurrentVel.x ^ 2) + (CurrentVel.y ^ 2) + (CurrentVel.z ^ 2))
					--Slow Frisbee, but allow falling
					while CurrentVelMag > 0.5 do
						SetObjectPhysicsParams(Frisbee, 0.19, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01, 0.0, -1.0)
						SetEntityVelocity(Frisbee, 0.5 * CurrentVel.x, 0.5 * CurrentVel.y, CurrentVel.z)
						SetEntityAngularVelocity(Frisbee, 0.75 * CurrentAVel.x, 0.75 * CurrentAVel.y, CurrentAVel.z)
						Citizen.Wait(200)
						CurrentVel = GetEntityVelocity(Frisbee)
						CurrentVelMag = math.sqrt((CurrentVel.x ^ 2) + (CurrentVel.y ^ 2) + (CurrentVel.z ^ 2))
						CurrentAVel = GetEntityRotationVelocity(Frisbee)
					end
					--Stop Frisbee, but allow some sliding
					local CheckStopped = true
					local BaselinePos = GetEntityCoords(Frisbee)
					local PositionCheck1 = BaselinePos
					while CheckStopped do
						Citizen.Wait(1000)
						local PositionCheck2 = GetEntityCoords(Frisbee)
						local VelocityCheck = GetEntityVelocity(Frisbee)
						if #(PositionCheck2 - PositionCheck1) > 0.005 then
							local retval, GroundZ, Normal = GetGroundZAndNormalFor_3dCoord(PositionCheck2.x, PositionCheck2.y, PositionCheck2.z)
							local GroundSlope = 90.0 - math.deg(math.asin(Normal.z))
							local GroundDist = PositionCheck2.z - GroundZ
							if (GroundSlope < Config.StopSlope and GroundDist < 0.05) then
								Citizen.Wait(100)
								FrisbeeStopped = true
								CheckStopped = false
							end
							SetEntityAngularVelocity(Frisbee, 0.0, 0.0, 0.0)
							SetEntityVelocity(Frisbee, 0.5 * VelocityCheck.x, 0.5 * VelocityCheck.y, 0.5 * VelocityCheck.z)
							PositionCheck1 = GetEntityCoords(Frisbee)
						else
							Citizen.Wait(1000)
							FrisbeeStopped = true
							CheckStopped = false
						end
					end
					FreezeEntityPosition(Frisbee, true)
					FrisbeePos = GetEntityCoords(Frisbee)
					if not PlayingFrisbeeGolf then
						for k, _ in pairs(Config.Practice) do
							if HoleZones[k] then
								if HoleZones[k]:isPointInside(FrisbeePos) then
									DrawScaleformMessage("In the Hole!", "", 3000, false)
									PlaySoundFrontend(-1, "Goal", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
								end
							end
						end
					end
					RestrictedPos = vector3(FrisbeePos.x, FrisbeePos.y, FrisbeePos.z + 0.3)
					DrawNativeTextMessage(RoundOff(#(StartPos - GetEntityCoords(Frisbee)), 2) .. " m", 5000)
					FrisbeeOut = true
					FrisbeeMonitor()
					RemoveFrisbeeCam()
				end
			Citizen.Wait(10)
			end
		end
	)
end

function AimReset()
	Pitch = Config.Pitch
	Velocity = Config.Velocity
	Roll = Config.Roll
end

function PlayFrisbeeGolf()
	PlayingFrisbeeGolf = true
	if CourseSpawned then
		for i, _ in ipairs(SpectatorHoles) do
			DeleteObject(SpectatorHoles[i])
			DeleteObject(SpectatorTees[i])
		end
		CourseSpawned = false
	end
	CurrentHole = 1
	CurrentThrow = 0
	Scorecard = {}
	TriggerServerEvent('gg-frisbee:server:playingfrisbeegolf')
	TriggerServerEvent('gg-frisbee:server:getscore')
	local DropInformed = false
	for k, v in ipairs(Config.FrisbeeGolfCourse) do
		FrisbeeTees[k] = CreateObject(GetHashKey('gg_fg_teepad'), v.Tee.x, v.Tee.y, v.Tee.z - 0.4, false, true, false)
		local HoleDirection = GetHeadingFromVector_2d(v.Hole.x - v.Tee.x, v.Hole.y - v.Tee.y) + 90.0
		SetEntityRotation(FrisbeeTees[k], 0.0, 0.0, HoleDirection, 5, false)
		TeeBlips[k] = AddBlipForCoord(v.Tee)
		SetBlipSprite(TeeBlips[k], v.TeeBlip)
		SetBlipHiddenOnLegend(TeeBlips[k], true)
		SetBlipColour(TeeBlips[k], 2)
		SetBlipScale(TeeBlips[k], 0.6)
		FrisbeeTargets[k] = CreateObject(GetHashKey(Config.FrisbeeGolfTargets[v.HoleProp].Prop), v.Hole + Config.FrisbeeGolfTargets[v.HoleProp].Offset, false, true, false)
		SetEntityRotation(FrisbeeTargets[k], Config.FrisbeeGolfTargets[v.HoleProp].Rotation.x, Config.FrisbeeGolfTargets[v.HoleProp].Rotation.y, v.HoleHead, 2, false)
		FreezeEntityPosition(FrisbeeTargets[k], true) -- for props that are not static
		HoleBlips[k] = AddBlipForCoord(v.Hole)
		SetBlipSprite(HoleBlips[k], v.HoleBlip)
		SetBlipHiddenOnLegend(HoleBlips[k], true)
		SetBlipColour(HoleBlips[k], 1)
		SetBlipScale(HoleBlips[k], 0.6)
	end
	Citizen.CreateThread(
		function()
			local Instructed = false
			local WaitTime = 5 -- if not yet thrown, make longer?
			local TeePos = Config.FrisbeeGolfCourse[CurrentHole].Tee
			RestrictedPos = vector3(TeePos.x, TeePos.y, TeePos.z + 0.9)
			local HolePos = Config.FrisbeeGolfCourse[CurrentHole].Hole
			local HoleDist = RoundOff(Config.FrisbeeGolfCourse[CurrentHole].Distance, 1) 
			local HoleZoneCreated = false
			RequestScriptAudioBank("CROWD_CHEER", 0)
			while PlayingFrisbeeGolf do
				local PlayerPed = PlayerPedId()
				local PlayerPos = GetEntityCoords(PlayerPed)
				if not HoleZoneCreated then
					HoleZoneCreated = true
					CreateHoleZone(CurrentHole)
					Citizen.Wait(50)
				end
				if CurrentThrow == 0 then
					local DistToTee = #(PlayerPos - TeePos)
					if CurrentThrow == 0 and DistToTee < 4.0 then
						if not Instructed then
							DrawNativeTextMessage("Hole " .. CurrentHole .. " (Par " .. Config.FrisbeeGolfCourse[CurrentHole].Par ..")~n~" .. HoleDist .. "m", 3000)
							Instructed = true
						end
						WaitTime = 5
					end
					if DistToTee > 5.0 and CurrentThrow == 0 then
						Instructed = false
						WaitTime = 5
					end
				end
				if CurrentThrow > 0 then
					WaitTime = 5
				end
				local PlayerDist = #(PlayerPos - HolePos)
				if PlayerDist < 1.8 then
					if not DropInformed then
						DropInformed = true
						InDropRange = true
					end
				end
				if (PlayerDist > 1.8 and DropInformed) then
					DropInformed = false
					InDropRange = false
				end
				local FrisbeePos = GetEntityCoords(Frisbee)
				if HoleZones[CurrentHole] then
					if HoleZones[CurrentHole]:isPointInside(FrisbeePos) then
						if not IsEntityAttachedToAnyPed(Frisbee) then
							if FrisbeeStopped and FrisbeeOut then
								if CurrentThrow == 1 then
									local SoundId = GetSoundId()
									DrawScaleformMessage("Hole in One!", "Hole: " .. CurrentHole, 6000, true)
									PlaySoundFromCoord(SoundId, "CROWD_CHEER_MASTER", PlayerPos, 0, false, 50.0, true)
									Wait(5000)
									StopSound(SoundId)
								else
									DrawScaleformMessage("Hole " .. CurrentHole .. " Complete!", "Score: " .. CurrentThrow, 6000, false)
									PlaySoundFrontend(-1, "Goal", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
								end
								Scorecard[CurrentHole] = CurrentThrow
								SetBlipColour(TeeBlips[CurrentHole], 40)
								SetBlipColour(HoleBlips[CurrentHole], 40)
								HoleZones[CurrentHole].destroyed = true
								HoleZones[CurrentHole] = nil
								HoleZoneCreated = false
								CurrentHole = CurrentHole + 1
								if CurrentHole > #Config.FrisbeeGolfCourse then
									OpenScorecard()
									EndFrisbeeGolf()
								else
									CurrentThrow = 0
									TeePos = Config.FrisbeeGolfCourse[CurrentHole].Tee
									RestrictedPos = vector3(TeePos.x, TeePos.y, TeePos.z + 0.9)
									HolePos = Config.FrisbeeGolfCourse[CurrentHole].Hole
									HoleDist = RoundOff(#(HolePos - TeePos), 1)
								end
							end
						end
					end
				else
					HoleZoneCreated = true
					CreateHoleZone(CurrentHole)
					Citizen.Wait(50)
				end
				Citizen.Wait(WaitTime)
			end
		end
	)
end

function EndFrisbeeGolf()
	PlayingFrisbeeGolf = false
	for k, _ in ipairs(Config.FrisbeeGolfCourse) do
		SetEntityAsMissionEntity(FrisbeeTees[k], false, false)
		SetEntityAsNoLongerNeeded(FrisbeeTees[k])
		RemoveBlip(TeeBlips[k])
		SetEntityAsMissionEntity(FrisbeeTargets[k], false, false)
		SetEntityAsNoLongerNeeded(FrisbeeTargets[k])
		RemoveBlip(HoleBlips[k])
	end
	CurrentHole = 0
	CurrentThrow = 0
	TriggerServerEvent('gg-frisbee:server:leftfrisbeegolf')
end

function CreateHoleZone(holezone)
	local HoleNumber = tonumber(holezone)
	local Target, HolePos, ZoneOffset, ZoneRadius
	if HoleNumber > #Config.FrisbeeGolfCourse then
		Target = PracticeHoles[HoleNumber]
		HolePos = Config.Practice[HoleNumber].Hole
		ZoneOffset = Config.FrisbeeGolfTargets[Config.Practice[HoleNumber].HoleProp].ZoneOffset
		ZoneRadius = Config.FrisbeeGolfTargets[Config.Practice[HoleNumber].HoleProp].ZoneRadius
	else
		Target = FrisbeeTargets[HoleNumber]
		HolePos = Config.FrisbeeGolfCourse[HoleNumber].Hole
		ZoneOffset = Config.FrisbeeGolfTargets[Config.FrisbeeGolfCourse[HoleNumber].HoleProp].ZoneOffset
		ZoneRadius = Config.FrisbeeGolfTargets[Config.FrisbeeGolfCourse[HoleNumber].HoleProp].ZoneRadius
	end
	local HoleZonePoints = {}
	local HoleZoneRes = 12
	local HoleZoneZ = HolePos.z + ZoneOffset.z
	for i = 1, HoleZoneRes do
		local PointAngle = i * (360.0 / HoleZoneRes)
		local PointOffset = GetOffsetFromEntityInWorldCoords(Target, ZoneOffset)
		local PointPos = vector3(PointOffset.x + ZoneRadius * math.cos(math.rad(PointAngle)), PointOffset.y + ZoneRadius * math.sin(math.rad(PointAngle)), 0.0)
		HoleZonePoints[i] = vector2(PointPos.x, PointPos.y)
	end
	HoleZones[HoleNumber] = PolyZone:Create(HoleZonePoints, {
		name = HoleNumber,
		minZ = HoleZoneZ - ZoneRadius,
		maxZ = HoleZoneZ + ZoneRadius,
		debugGrid = false,
		gridDivisions = HoleZoneRes
	})
end

function DrawRestrictedZone()
	if Config.Strict then
		Citizen.CreateThread(
			function()
				while (PlayingFrisbeeGolf and Aiming) do
					DrawMarker(25, RestrictedPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.StrictDist * 2, Config.StrictDist * 2, Config.StrictDist * 2, 255, 255, 255, 51, false, false, 2, nil, nil, true)
					Citizen.Wait(0)
				end
			end
		)
	end
end

function SpawnDisplayFrisbees()
	if Config.UsingMap then
		for k, v in pairs(Config.DisplayFrisbees) do
			local Hash = GetHashKey(v.Prop)
			RequestModel(Hash)
			while not HasModelLoaded(Hash) do Wait(5) end
			DisplayFrisbees[k] = CreateObject(Hash, v.Pos, false, false, false)
			SetEntityRotation(DisplayFrisbees[k], v.Rot, 5 --[[XYZ]], false)
			FreezeEntityPosition(DisplayFrisbees[k], true)
		end
	end
end

function SpawnFrisbeeDude()
	FrisbeeDudeSpawned = true
	local Hash = GetHashKey(Config.FrisbeeDude.Ped)
	RequestModel(Hash)
	while not HasModelLoaded(Hash) do Wait(5) end
	FrisbeeDude = CreatePed(0, Hash, Config.FrisbeeDude.Location, false, true)
	for comp, var in pairs(Config.FrisbeeDude.PedVariation) do
		SetPedComponentVariation(FrisbeeDude, comp, var[1], var[2], var[3])
	end
	for prop, var in pairs(Config.FrisbeeDude.PedProp) do
		SetPedPropIndex(FrisbeeDude, prop, var[1], var[2], var[3])
	end
	Wait(1000)
	TaskStartScenarioInPlace(FrisbeeDude, Config.FrisbeeDude.Scenario, 0, true)
	FreezeEntityPosition(FrisbeeDude, true)
	SetEntityInvincible(FrisbeeDude, true)
	SetBlockingOfNonTemporaryEvents(FrisbeeDude, true)
end

function SaveScorecard(scores)
	TriggerServerEvent('gg-frisbee:server:savescore', scores)
end

function SetupFrisbeeCam()
	local PlayerPed = PlayerPedId()
	local PlayerPos = GetEntityCoords(PlayerPed)
	local PlayerHead = GetEntityHeading(PlayerPed)
	Camera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", PlayerPos, -22.5, 0.0, PlayerHead, 75.0, true, 2)
	SetCamActive(Camera, true)
	RenderScriptCams(true, true, 1500, false, false)
	local CamPos = GetOffsetFromEntityInWorldCoords(Frisbee, -3.0, 1.0 , 0.0) -- note Frisbee models were created 90deg rotated
	local FrisbeePos = GetEntityCoords(Frisbee)
	local CamOffset = CamPos - FrisbeePos
	AttachCamToEntity(Camera, Frisbee, CamOffset, false)
	CamCreated = true
	FreezeEntityPosition(PlayerPed, true)
end

function RemoveFrisbeeCam()
	if CamCreated then
	SetGameplayCamRelativeHeading(0)
		RenderScriptCams(false, false, 0, true, true)
		DetachEntity(Frisbee, true, true)
		SetCamActive(Camera, false)
		DestroyCam(Camera, true)
	end
	CamCreated = false
	FreezeEntityPosition(PlayerPedId(), false)
end


-- Utility Functions

function DrawNativeTextMessage(str, timeout)
	BeginTextCommandPrint("STRING")
	AddTextComponentString(str)
	EndTextCommandPrint(timeout, true)
end

function DrawNativeTextRunningMessage()
	local Scale = 0.35
	if not MessageRunning then
		Citizen.CreateThread(
			function()
				while RunMessage do
					MessageRunning = true
					local MessageWidth = 0
					local MessageLines = 1
					local LastFound = 0
					local Next = 1
					while true do
						local Start, End = string.find(Message, "~n~", Next, true)
						if Start == nil then break end
						if MessageWidth == 0 then
							LastFound = Start
							MessageWidth = Start
						else
							if Start - LastFound > MessageWidth then
								MessageWidth = Start - LastFound
							end
							LastFound = Start
						end
						MessageLines = MessageLines + 1
						Next = End + 1
					end
					local width = (MessageWidth * Scale * 0.013) + 0.01 -- with border
					local height = (MessageLines * Scale * 0.07) + 0.01 -- with border
					local x = 0.95 - width
					local y = 0.85
					BeginTextCommandDisplayText('STRING')
					AddTextComponentSubstringPlayerName(Message)
					SetTextScale(1.0, Scale)
					EndTextCommandDisplayText(x, y)
					DrawRect(x + (0.5 * width) - 0.005, y + (0.5 * height) - 0.005, width, height, 0, 0, 0, 180)
					Citizen.Wait(0)
				end
				MessageRunning = false
			end
		)
	end
end

function DrawNativeTextHelpMessage()
	Citizen.CreateThread(
		function()
			while RunHelpMessage do
				AddTextEntry('HelpMsg', HelpMessage)
				BeginTextCommandDisplayHelp('HelpMsg')
				EndTextCommandDisplayHelp(0, false, true, -1)
				Citizen.Wait(0)
			end
		end
	)
end

function DrawScaleformMessage(title, message, timeout, fullscreen)
	local ScaleformMessage = RequestScaleformMovie('mp_big_message_freemode')
	while not HasScaleformMovieLoaded(ScaleformMessage) do Wait(5) end
	BeginScaleformMovieMethod(ScaleformMessage, 'SHOW_SHARD_CENTERED_MP_MESSAGE')
	PushScaleformMovieMethodParameterString(title)
	PushScaleformMovieMethodParameterString(message)
	PushScaleformMovieMethodParameterInt(5)
	EndScaleformMovieMethod()
	local CurTime = GetGameTimer()
	local EndTime = CurTime + timeout
	Citizen.CreateThread(
		function()
			while CurTime < EndTime do
				if fullscreen then
					DrawScaleformMovieFullscreen(ScaleformMessage, 255, 255, 255, 255, 0)
				else
					DrawScaleformMovie(ScaleformMessage, 0.5, 0.9, 0.5, 0.5, 255, 255, 255, 255, 0)
				end
				Citizen.Wait(0)
				CurTime = GetGameTimer()
			end
		end
	)
end

function RoundOff(number, digits)
	local magnitude = 10 ^ digits
	return math.floor((number * magnitude) + 0.5) / (magnitude)
end


-- Threads

Citizen.CreateThread(
	function()
		local WaitTime = 2000
		local FDMessageText
		if Config.Standalone then
			FDMessageText = "Press ~INPUT_ENTER~ to get a Frisbee~n~Press ~INPUT_DETONATE~ to toggle Frisbee Golf play"
		else
			FDMessageText = "Press ~INPUT_DETONATE~ to toggle Frisbee Golf play"
		end
		local MessageUpdated = false
		local DisplayFrisbeesSpawned = false
		local SelectingFrisbee = false
		while FrisbeeGolfAllowed do
			local PlayerPed = PlayerPedId()
			local PlayerPos = GetEntityCoords(PlayerPed)
			local FrisbeeDudePos = vector3(Config.FrisbeeDude.Location.x, Config.FrisbeeDude.Location.y, Config.FrisbeeDude.Location.z)
			local Dist = #(PlayerPos - FrisbeeDudePos)
			local DistC = #(PlayerPos - Config.FrisbeeGolfCourseCenter)
			if DistC < 200.0 then
				if AnyonePlaying and not CourseSpawned and not PlayingFrisbeeGolf then
					for k, v in pairs(Config.FrisbeeGolfCourse) do
						SpectatorHoles[k] = CreateObject(GetHashKey(Config.FrisbeeGolfTargets[v.HoleProp].Prop), v.Hole + Config.FrisbeeGolfTargets[v.HoleProp].Offset, false, true, false)
						SetEntityRotation(SpectatorHoles[k], Config.FrisbeeGolfTargets[v.HoleProp].Rotation, 5, false)
						FreezeEntityPosition(SpectatorHoles[k], true)
						SpectatorTees[k] = CreateObject(GetHashKey('gg_fg_teepad'), v.Tee.x, v.Tee.y, v.Tee.z - 0.4, false, true, false)
						local HoleDirection = GetHeadingFromVector_2d(v.Hole.x - v.Tee.x, v.Hole.y - v.Tee.y) + 90.0
						SetEntityRotation(SpectatorTees[k], 0.0, 0.0, HoleDirection, 5, false)
						
					end
					CourseSpawned = true
				end
			end
			if Dist < 150.0 then
				if not PracticeHolesSpawned then
					for k, v in pairs(Config.Practice) do
						PracticeHoles[k] = CreateObject(GetHashKey(Config.FrisbeeGolfTargets[v.HoleProp].Prop), v.Hole + Config.FrisbeeGolfTargets[v.HoleProp].Offset, false, true, false)
						SetEntityRotation(PracticeHoles[k], Config.FrisbeeGolfTargets[v.HoleProp].Rotation, 5, false)
						FreezeEntityPosition(PracticeHoles[k], true)
						if HoleZones[k] == nil then
							CreateHoleZone(k)
						end
					end
					PracticeHolesSpawned = true
				end
			end
			if Dist < 35.0 then
				if not FrisbeeDudeSpawned then
					if Config.Standalone then
						SpawnFrisbeeDude()
					end
					FrisbeeDudeSpawned = true
				end
				if not DisplayFrisbeesSpawned then
					SpawnDisplayFrisbees()
					DisplayFrisbeesSpawned = true
				end
				WaitTime = 5
			end
			if Dist < 3.5 then
				DisableControlAction(0, 140, true) -- R Key
				if not MessageUpdated then
					HelpMessage = FDMessageText
					if not RunHelpMessage then
						RunHelpMessage = true
						DrawNativeTextHelpMessage()
					end
					MessageUpdated = true
				end
				if (IsControlJustReleased(0, 23) and Config.Standalone and not SelectingFrisbee) then -- F key
					SelectingFrisbee = true
					HelpMessage = "~INPUT_ENTER~ White Frisbee~n~~INPUT_MELEE_ATTACK_LIGHT~ Red Frisbee~n~~INPUT_DETONATE~ Green Frisbee~n~~INPUT_SPECIAL_ABILITY_SECONDARY~ Blue Frisbee~n~~INPUT_MP_TEXT_CHAT_TEAM~ Yellow Frisbee"
					Citizen.Wait(500) -- prevent double register
				end
				if (IsControlJustReleased(0, 23) and Config.Standalone and SelectingFrisbee) then -- F Key
					--create white frisbee
					if not DoesEntityExist(Frisbee) then
						FrisbeeType = "frisbee"
						EquipFrisbee()
						SelectingFrisbee = false
						HelpMessage = FDMessageText
						MessageUpdated = false
					end
				end
				if (IsDisabledControlJustReleased(0, 140) and Config.Standalone and SelectingFrisbee) then -- R Key
					--create red frisbee
					if not DoesEntityExist(Frisbee) then
						FrisbeeType = "frisbee_r"
						EquipFrisbee()
						SelectingFrisbee = false
						HelpMessage = FDMessageText
						MessageUpdated = false
					end
				end
				if (IsControlJustReleased(0, 47) and Config.Standalone and SelectingFrisbee) then -- G Key
					--create green frisbee
					if not DoesEntityExist(Frisbee) then
						FrisbeeType = "frisbee_g"
						EquipFrisbee()
						SelectingFrisbee = false
						HelpMessage = FDMessageText
						MessageUpdated = false
					end
				end
				if (IsControlJustReleased(0, 29) and Config.Standalone and SelectingFrisbee) then -- B Key
					--create green frisbee
					ClearPedTasks(PlayerPed) -- for key mapped to point action
					if not DoesEntityExist(Frisbee) then
						FrisbeeType = "frisbee_b"
						EquipFrisbee()
						SelectingFrisbee = false
						HelpMessage = FDMessageText
						MessageUpdated = false
					end
				end
				if (IsControlJustReleased(0, 246) and Config.Standalone and SelectingFrisbee) then -- Y Key
					--create yellow frisbee
					if not DoesEntityExist(Frisbee) then
						FrisbeeType = "frisbee_y"
						EquipFrisbee()
						SelectingFrisbee = false
						HelpMessage = FDMessageText
						MessageUpdated = false
					end
				end
				if (IsControlJustReleased(0, 47) and not SelectingFrisbee) then -- G key
					if not PlayingFrisbeeGolf then
						Message = ""
						RunMessage = false
						PlayFrisbeeGolf()
						PlaySoundFrontend(-1, "Start", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
					else
						EndFrisbeeGolf()
						PlaySoundFrontend(-1, "LOOSE_MATCH", "HUD_MINI_GAME_SOUNDSET", true)
					end
				end
			end
			if Dist > 4.0 then
				if MessageUpdated then
					RunHelpMessage = false
					MessageUpdated = false
					SelectingFrisbee = false
					if DoesEntityExist(Frisbee) and not FrisbeeOut then
						EquipFrisbee()
					end
				end
			end
			if Dist > 40.0 then
				if FrisbeeDudeSpawned then
					DeletePed(FrisbeeDude)
					FrisbeeDudeSpawned = false
				end
				if DisplayFrisbeesSpawned then
					if Config.UsingMap then
						for i = 1, #DisplayFrisbees do
							DeleteObject(DisplayFrisbees[i])
						end
					end
					DisplayFrisbeesSpawned = false
				end
				WaitTime = 2000
			end
			if Dist > 155.0 then
				if PracticeHolesSpawned then
					for i, _ in ipairs(PracticeHoles) do
						DeleteObject(PracticeHoles[i])
					end
					PracticeHolesSpawned = false
				end
			end
			if DistC > 205.0 then
				if CourseSpawned then
					for i, _ in ipairs(SpectatorHoles) do
						DeleteObject(SpectatorHoles[i])
						DeleteObject(SpectatorTees[i])
					end
					CourseSpawned = false
				end
			end
			Citizen.Wait(WaitTime)
		end
	end
)


-- Commands

RegisterCommand('frisbee', -- for Standalone
	function()
		if Config.Standalone and InInventory then
			EquipFrisbee()
		else
			if DoesEntityExist(Frisbee) then
				DrawNativeTextMessage("You already have a frisbee in use", 3000)
			else
				DrawNativeTextMessage("You don't have a frisbee", 3000)
			end
		end
	end
)

RegisterCommand('frisbeestuck',
	function()
		if DoesEntityExist(Frisbee) then
			if FrisbeeOut and FrisbeeStopped then
				local PlayerPed = PlayerPedId()
				local PlayerPos = GetEntityCoords(PlayerPed)
				local FrisbeePos = GetEntityCoords(Frisbee)
				local DistXY = #(vector2(PlayerPos.x, PlayerPos.y) - vector2(FrisbeePos.x, FrisbeePos.y)) -- ignores z
				if DistXY < Config.StuckDist then
					RestrictedPos = vector3(PlayerPos.x, PlayerPos.y, PlayerPos.z - 0.9)
					EquipFrisbee()
				else
					DrawNativeTextMessage("You need to move closer", 3000)
				end
			end
		else
			DrawNativeTextMessage("You don't have a frisbee", 3000)
		end
	end
)

RegisterCommand('nofg', -- turns off main thread disabling Frisbee Golf until next login
	function()
		if PlayingFrisbeeGolf then
			EndFrisbeeGolf()
		end
		FrisbeeGolfAllowed = false
		Wait(2000)
		if CourseSpawned then
			for i, _ in ipairs(SpectatorHoles) do
				DeleteObject(SpectatorHoles[i])
				DeleteObject(SpectatorTees[i])
			end
			CourseSpawned = false
		end
	end
)