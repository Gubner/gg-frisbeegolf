local ResourceFile = LoadResourceFile(GetCurrentResourceName(), "./server/scores.json")
local Frisbees = {}
local PlayersPlaying = {}
local Scores = {}


-- Initialize

if not Config.Standalone then
	QBCore = exports['qb-core']:GetCoreObject()
	QBCore.Functions.CreateUseableItem("frisbee", function(source, item) if QBCore.Functions.HasItem(source, item.name, 1) then TriggerClientEvent('gg-frisbee:client:createfrisbee', source, "frisbee") end end)
	QBCore.Functions.CreateUseableItem("frisbee_r", function(source, item) if QBCore.Functions.HasItem(source, item.name, 1) then TriggerClientEvent('gg-frisbee:client:createfrisbee', source, "frisbee_r") end end)
	QBCore.Functions.CreateUseableItem("frisbee_g", function(source, item) if QBCore.Functions.HasItem(source, item.name, 1) then TriggerClientEvent('gg-frisbee:client:createfrisbee', source, "frisbee_g") end end)
	QBCore.Functions.CreateUseableItem("frisbee_b", function(source, item) if QBCore.Functions.HasItem(source, item.name, 1) then TriggerClientEvent('gg-frisbee:client:createfrisbee', source, "frisbee_b") end end)
	QBCore.Functions.CreateUseableItem("frisbee_y", function(source, item) if QBCore.Functions.HasItem(source, item.name, 1) then TriggerClientEvent('gg-frisbee:client:createfrisbee', source, "frisbee_y") end end)
end


-- Events

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		Scores = json.decode(ResourceFile) or {}
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	for _, v in ipairs(Frisbees) do
		if DoesEntityExist(v[2]) then
			DeleteEntity(v[2])
		end
	end
	Frisbees = {}
end)

AddEventHandler('playerDropped', function()
	local Source = source
	for i, v in ipairs(Frisbees) do
		if v[1] == Source then
			if DoesEntityExist(v[2]) then
				DeleteEntity(v[2])
			end
			table.remove (Frisbees, i)
		end
	end
	TriggerEvent('gg-frisbee:server:leftfrisbeegolf', Source)
end)

RegisterNetEvent('gg-frisbee:server:frisbeecreated', function(netid, ftype, frominv)
	local Source = source
	local Frisbee = NetworkGetEntityFromNetworkId(netid)
	local FrisbeeType = ftype
	if not Config.Standalone and frominv then
		local Player = QBCore.Functions.GetPlayer(Source)
		Player.Functions.RemoveItem(FrisbeeType, 1)
	end
	SetEntityDistanceCullingRadius(Frisbee, 500.0)
	table.insert(Frisbees, {Source, Frisbee})
end)

RegisterNetEvent('gg-frisbee:server:frisbeedeleted', function(netid, ftype, frominv)
	local Source = source
	local Frisbee = NetworkGetEntityFromNetworkId(netid)
	local FrisbeeType = ftype
	if not Config.Standalone and frominv then
		local Player = QBCore.Functions.GetPlayer(Source)
		Player.Functions.AddItem(FrisbeeType, 1)
	end
	for i, v in ipairs(Frisbees) do
		if v[2] == Frisbee then
			DeleteEntity(Frisbee)
			table.remove (Frisbees, i)
		end
	end
end)

RegisterNetEvent('gg-frisbee:server:playingfrisbeegolf', function()
	local Source = source
	table.insert(PlayersPlaying, Source)
	if #PlayersPlaying == 1 then
		TriggerClientEvent('gg-frisbee:client:playerplaying', -1, true)
	end
end)

RegisterNetEvent('gg-frisbee:server:leftfrisbeegolf', function(src)
	local Source = src or source
	for i, v in ipairs(PlayersPlaying) do
		if v == Source then
			table.remove (PlayersPlaying, i)
		end
	end
	if #PlayersPlaying == 0 then
		TriggerClientEvent('gg-frisbee:client:playerplaying', -1, false)
	end
end)

RegisterNetEvent('gg-frisbee:server:isanyoneplaying', function()
	local Source = source
	if #PlayersPlaying == 0 then
		TriggerClientEvent('gg-frisbee:client:playerplaying', Source, false)
	else
		TriggerClientEvent('gg-frisbee:client:playerplaying', Source, true)
	end
end)

RegisterNetEvent('gg-frisbee:server:savescore', function(scorecard)
	local Source = source
	local PlayerName = GetPlayerName(Source)
	Scores[PlayerName] = scorecard
	SaveResourceFile(GetCurrentResourceName(), "./server/scores.json", json.encode(Scores), -1)
	TriggerClientEvent('gg-frisbee:client:savedscore', Source, Scores[PlayerName])
end)

RegisterNetEvent('gg-frisbee:server:getscore', function()
	local Source = source
	local PlayerName = GetPlayerName(Source)
	if type(Scores[PlayerName]) ~= nil then
		TriggerClientEvent('gg-frisbee:client:savedscore', Source, Scores[PlayerName])
	else
		TriggerClientEvent('gg-frisbee:client:savedscore', Source, nil)
	end
end)