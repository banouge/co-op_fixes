-- main object

local cf = {}

-- register mod

cf.mod = RegisterMod("Co-op Fixes", 1)

-- require json for save data

local json = require("json")

-- define import function to use include (require without caching) when possible to let luamod command work properly

local function import(moduleName)
	local wasSuccess, moduleScript = pcall(include, moduleName)
	
	if not wasSuccess then
		moduleScript = require(moduleName)
	end
	
	return moduleScript
end

-- define saveData reset function

local function resetSaveData()
	local oldData = cf.saveData or {}
	
	if cf.mod:HasData() and not cf.saveData then
		oldData = json.decode(cf.mod:LoadData())
	end
	
	cf.saveData = {
		playerIds = {},
		playerData = {},
		
		taintedBlueUi = oldData.taintedBlueUi or 1,
		esauUi = oldData.esauUi or 1,
		jacobUi = oldData.jacobUi or false,
		devilDeal = oldData.devilDeal or oldData.devilDeal == nil
	}
end

-- load scripts

cf.fixes = {
	taintedBlue = import("fixes.TaintedBlue"),
	esau = import("fixes.Esau"),
	devilDeal = import("fixes.DevilDeal")
}

for _, fix in pairs(cf.fixes) do
	fix.cf = cf
	fix:addCallbacks()
end

-- add callbacks for save data

function cf:onPostGameStarted(didContinue)
	if didContinue then
		if cf.mod:HasData() then
			cf.saveData = json.decode(cf.mod:LoadData())
		end
	end
	
	cf:onPostPlayerInit()
end

function cf:onPreGameExit(shouldSave)
	if shouldSave then
		cf.mod:SaveData(json.encode(cf.saveData))
	end
	
	resetSaveData()
end

function cf:onPostPlayerInit(player)
	for playerIndex = 0, Game():GetNumPlayers() - 1 do
		cf.saveData.playerIds["i" .. GetPtrHash(Isaac.GetPlayer(playerIndex))] = playerIndex
	end
end

cf.mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, cf.onPostGameStarted)
cf.mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, cf.onPreGameExit)
cf.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, cf.onPostPlayerInit)

-- add save data manipulation functions

function cf:getPlayerId(player)
	return cf.saveData.playerIds["i" .. GetPtrHash(player)]
end

function cf:getData(playerIndex, key, defaultValue)
	if not cf.saveData.playerData["p" .. playerIndex] then
		cf.saveData.playerData["p" .. playerIndex] = {}
	end
	
	if not cf.saveData.playerData["p" .. playerIndex][key] then
		cf.saveData.playerData["p" .. playerIndex][key] = defaultValue
	end
	
	return cf.saveData.playerData["p" .. playerIndex][key]
end

function cf:setData(playerIndex, key, value)
	if not cf.saveData.playerData["p" .. playerIndex] then
		cf.saveData.playerData["p" .. playerIndex] = {}
	end
	
	cf.saveData.playerData["p" .. playerIndex][key] = value
end

-- add rendering stuff

function cf:worldToScreen(position)
	local pos = Isaac.WorldToScreen(position)
	
	if Game():GetRoom():IsMirrorWorld() then
		return Vector(Isaac.GetScreenWidth() - pos.X, pos.Y)
	end
	
	return pos
end

-- add mod config stuff

resetSaveData()
cf:onPostPlayerInit()

if ModConfigMenu then
	local category = "Co-op Fixes"
	
	local uiOptions = {
		[0] = "On for everyone",
		[1] = "On",
		[2] = "Off"
	}
	
	local taintedBlueUiSetting = {
		Type = ModConfigMenu.OptionType.NUMBER,
		Default = cf.saveData.taintedBlueUi,
		Minimum = 0,
		Maximum = 2,
		
		CurrentSetting = function()
			return cf.saveData.taintedBlueUi
		end,
		
		Display = function()
			return "Tainted ??? UI fix: " .. uiOptions[cf.saveData.taintedBlueUi]
		end,
		
		OnChange = function(value)
			cf.saveData.taintedBlueUi = value
		end
	}
	
	local esauUiSetting = {
		Type = ModConfigMenu.OptionType.NUMBER,
		Default = cf.saveData.esauUi,
		Minimum = 0,
		Maximum = 2,
		
		CurrentSetting = function()
			return cf.saveData.esauUi
		end,
		
		Display = function()
			return "Esau UI fix: " .. uiOptions[cf.saveData.esauUi]
		end,
		
		OnChange = function(value)
			cf.saveData.esauUi = value
		end
	}
	
	local jacobUiSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Default = cf.saveData.jacobUi,
		
		CurrentSetting = function()
			return cf.saveData.jacobUi
		end,
		
		Display = function()
			if cf.saveData.jacobUi then
				return "Should show Esau UI for Jacob too: Yes"
			end
			
			return "Should show Esau UI for Jacob too: No"
		end,
		
		OnChange = function(value)
			cf.saveData.jacobUi = value
		end
	}
	
	local devilDealSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Default = cf.saveData.devilDeal,
		
		CurrentSetting = function()
			return cf.saveData.devilDeal
		end,
		
		Display = function()
			if cf.saveData.devilDeal then
				return "Co-op friendly devil deals: On"
			end
			
			return "Co-op friendly devil deals: Off"
		end,
		
		OnChange = function(value)
			cf.saveData.devilDeal = value
		end
	}
	
	ModConfigMenu.RemoveCategory(category)
	ModConfigMenu.SetCategoryInfo(category, "")
	
	ModConfigMenu.AddSetting(category, nil, taintedBlueUiSetting)
	ModConfigMenu.AddSetting(category, nil, esauUiSetting)
	ModConfigMenu.AddSetting(category, nil, jacobUiSetting)
	ModConfigMenu.AddSetting(category, nil, devilDealSetting)
end
