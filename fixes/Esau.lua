-- main object

local fix = {}

-- add callbacks

fix.sprites = {}

function fix:onDropTriggered(player, playerIndex)
	if player:GetActiveItem() == Isaac.GetItemIdByName("D infinity") then
		fix.cf:setData(playerIndex, "dInfinityForm", (fix.cf:getData(playerIndex, "dInfinityForm", 0) + 1) % 10)
	end
end

function fix:getX(spriteIndex)
	return 6 * (spriteIndex % 4 - 1.5)
end

function fix:getY(spriteIndex)
	return 6 * math.floor(spriteIndex / 4) + 6
end

function fix:getNumHearts(player)
	if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
		return 1
	end
	
	return math.ceil(player:GetMaxHearts() / 2) + math.ceil(player:GetSoulHearts() / 2) + player:GetBoneHearts() + player:GetBrokenHearts()
end

function fix:getContainers(player)
	return math.ceil(player:GetMaxHearts() / 2)
end

function fix:getRedHearts(player)
	return player:GetHearts() / 2 - player:GetRottenHearts()
end

function fix:getHeartType(player, spriteIndex, boneIndex)
	if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
		return "CurseHeart"
	end
	
	if spriteIndex < fix:getContainers(player) then
		if spriteIndex < math.floor(fix:getRedHearts(player)) then
			return "RedHeartFull"
		end
		
		if spriteIndex < fix:getRedHearts(player) then
			return "RedHeartHalf"
		end
		
		if spriteIndex < math.ceil(player:GetHearts() / 2) then
			return "RottenHeartFull"
		end
		
		return "EmptyHeart"
	end
	
	local spriteIndexNoContainers = spriteIndex - fix:getContainers(player)
	local spriteIndexNoContainersOrBones = spriteIndexNoContainers - boneIndex
	
	if player:IsBoneHeart(spriteIndexNoContainers) then
		if boneIndex < math.floor(fix:getRedHearts(player) - fix:getContainers(player)) then
			return "BoneHeartFull"
		end
		
		if boneIndex < fix:getRedHearts(player) - fix:getContainers(player) then
			return "BoneHeartHalf"
		end
		
		if boneIndex < math.ceil(player:GetHearts() / 2 - fix:getContainers(player)) then
			return "RottenBoneHeartFull"
		end
		
		return "BoneHeartEmpty"
	end
	
	if spriteIndexNoContainersOrBones < math.floor(player:GetSoulHearts() / 2) then
		if (player:GetBlackHearts() >> spriteIndexNoContainersOrBones) & 1 == 1 then
			return "BlackHeartFull"
		end
		
		return "BlueHeartFull"
	end
	
	if spriteIndexNoContainersOrBones < player:GetSoulHearts() / 2 then
		if (player:GetBlackHearts() >> spriteIndexNoContainersOrBones) & 1 == 1 then
			return "BlackHeartHalf"
		end
		
		return "BlueHeartHalf"
	end
	
	return "BrokenHeart"
end

function fix:renderHealth(player, playerIndex, playerPos)
	local numHearts = fix:getNumHearts(player)
	local lastRedHeartIndex = 0
	local boneIndex = 0
	
	if not fix.sprites[playerIndex].health then
		fix.sprites[playerIndex].health = {
			main = {},
			white = {},
			gold = {}
		}
		
		for heartType, spriteTable in pairs(fix.sprites[playerIndex].health) do
			for spriteIndex = 0, 11 do
				spriteTable[spriteIndex] = Sprite()
				spriteTable[spriteIndex]:Load("gfx/sprites/ui_hearts.anm2", true)
				spriteTable[spriteIndex].Scale = Vector(0.5, 0.5)
			end
		end
	end
	
	for spriteIndex = 0, numHearts - 1 do
		local heartType = fix:getHeartType(player, spriteIndex, boneIndex)
		
		fix.sprites[playerIndex].health.main[spriteIndex]:SetFrame(heartType, 0)
		fix.sprites[playerIndex].health.main[spriteIndex]:Render(playerPos + Vector(fix:getX(spriteIndex), fix:getY(spriteIndex)))
		
		if heartType == "RedHeartFull" or heartType == "RedHeartHalf" or heartType == "BoneHeartFull" or heartType == "BoneHeartHalf" or heartType == "RottenBoneHeartFull" or heartType == "RottenHeartFull" then
			lastRedHeartIndex = spriteIndex
		end
		
		if heartType == "BoneHeartFull" or heartType == "BoneHeartHalf" or heartType == "BoneHeartEmpty" or heartType == "RottenBoneHeartFull" then
			boneIndex = boneIndex + 1
		end
	end
	
	if player:GetEternalHearts() > 0 then
		fix.sprites[playerIndex].health.white[lastRedHeartIndex]:SetFrame("WhiteHeartOverlay", 0)
		fix.sprites[playerIndex].health.white[lastRedHeartIndex]:Render(playerPos + Vector(fix:getX(lastRedHeartIndex), fix:getY(lastRedHeartIndex)))
	end
	
	for spriteIndex = numHearts - player:GetGoldenHearts(), numHearts - 1 do
		fix.sprites[playerIndex].health.gold[spriteIndex]:SetFrame("GoldHeartOverlay", 0)
		fix.sprites[playerIndex].health.gold[spriteIndex]:Render(playerPos + Vector(fix:getX(spriteIndex), fix:getY(spriteIndex)))
	end
end

--[[

WEIRD ACTIVES

blank card		variable max charge
the jar			forms originally in gfx/characters/costumes/costume_rebirth_90_thejar.png, form changes with GetJarHearts
jar of flies	forms originally in gfx/characters/costumes/costume_434_jarofflies.png, form changes with GetJarFlies
placebo			variable max charge
d infinity		forms originally in gfx/characters/costumes/costume_489_dinfinity.png, form changes with button press, variable max charge
clear rune		variable max charge
everything jar	forms originally in gfx/ui/hud_everythingjar.png, form changes with charge
jar of wisps	forms originally in gfx/ui/hud_jarofwisps.png, form changes on use
urn of souls	forms originally in gfx/ui/hud_urnofsouls.png, hard to detect form changes, it might be "easier" to just make a custom urn of souls, will stay unsupported until VarData is exposed

]]--

fix.isMaxChargeStandard = {
	[0] = true,
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	[6] = true,
	[8] = true,
	[12] = true
}

fix.barBounds = {
	top = 3,
	bottom = 26
}

fix.barOffset = Vector(-15, 10)

fix.getForm = {
	[Isaac.GetItemIdByName("Jar of Flies")] = function(player, playerIndex)
		return player:GetJarFlies()
	end,
	
	[Isaac.GetItemIdByName("Everything Jar")] = function(player, playerIndex)
		return player:GetActiveCharge() + 1
	end,
	
	[Isaac.GetItemIdByName("Jar of Wisps")] = function(player, playerIndex)
		return fix.cf:getData(playerIndex, "jarOfWisps", 1)
	end,
	
	[Isaac.GetItemIdByName("The Jar")] = function(player, playerIndex)
		return math.ceil(player:GetJarHearts() / 2)
	end,
	
	[Isaac.GetItemIdByName("D infinity")] = function(player, playerIndex)
		return fix.cf:getData(playerIndex, "dInfinityForm", 0)
	end
}

fix.getMaxCharge = {
	[Isaac.GetItemIdByName("Placebo")] = function(playerIndex)
		return fix.cf:getData(playerIndex, "placebo", 4)
	end,
	
	[Isaac.GetItemIdByName("Blank Card")] = function(playerIndex)
		return fix.cf:getData(playerIndex, "blankCard", 4)
	end,
	
	[Isaac.GetItemIdByName("Clear Rune")] = function(playerIndex)
		return fix.cf:getData(playerIndex, "clearRune", 4)
	end,
	
	[Isaac.GetItemIdByName("D infinity")] = function(playerIndex)
		return fix.cf:getData(playerIndex, "dInfinityMaxCharge", 2)
	end
}

fix.spritesheets = {
	[Isaac.GetItemIdByName("Jar of Flies")] = "gfx/sprites/costume_434_jarofflies.png",
	[Isaac.GetItemIdByName("Everything Jar")] = "gfx/sprites/hud_everythingjar.png",
	[Isaac.GetItemIdByName("Jar of Wisps")] = "gfx/sprites/hud_jarofwisps.png",
	[Isaac.GetItemIdByName("The Jar")] = "gfx/sprites/costume_rebirth_90_thejar.png",
	[Isaac.GetItemIdByName("D infinity")] = "gfx/sprites/costume_489_dinfinity.png"
}

fix.pillCharge = {
	[PillEffect.PILLEFFECT_BAD_GAS] = 1,
	[PillEffect.PILLEFFECT_BAD_TRIP] = 2,
	[PillEffect.PILLEFFECT_BALLS_OF_STEEL] = 12,
	[PillEffect.PILLEFFECT_BOMBS_ARE_KEYS] = 1,
	[PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA] = 3,
	[PillEffect.PILLEFFECT_FULL_HEALTH] = 12,
	[PillEffect.PILLEFFECT_HEALTH_DOWN] = 4,
	[PillEffect.PILLEFFECT_HEALTH_UP] = 12,
	[PillEffect.PILLEFFECT_I_FOUND_PILLS] = 1,
	[PillEffect.PILLEFFECT_PUBERTY] = 1,
	[PillEffect.PILLEFFECT_PRETTY_FLY] = 6,
	[PillEffect.PILLEFFECT_RANGE_DOWN] = 4,
	[PillEffect.PILLEFFECT_RANGE_UP] = 6,
	[PillEffect.PILLEFFECT_SPEED_DOWN] = 4,
	[PillEffect.PILLEFFECT_SPEED_UP] = 6,
	[PillEffect.PILLEFFECT_TEARS_DOWN] = 4,
	[PillEffect.PILLEFFECT_TEARS_UP] = 6,
	[PillEffect.PILLEFFECT_LUCK_DOWN] = 4,
	[PillEffect.PILLEFFECT_LUCK_UP] = 6,
	[PillEffect.PILLEFFECT_TELEPILLS] = 1,
	[PillEffect.PILLEFFECT_48HOUR_ENERGY] = 12,
	[PillEffect.PILLEFFECT_HEMATEMESIS] = 6,
	[PillEffect.PILLEFFECT_PARALYSIS] = 6,
	[PillEffect.PILLEFFECT_SEE_FOREVER] = 4,
	[PillEffect.PILLEFFECT_PHEROMONES] = 2,
	[PillEffect.PILLEFFECT_AMNESIA] = 6,
	[PillEffect.PILLEFFECT_LEMON_PARTY] = 3,
	[PillEffect.PILLEFFECT_WIZARD] = 6,
	[PillEffect.PILLEFFECT_PERCS] = 2,
	[PillEffect.PILLEFFECT_ADDICTED] = 6,
	[PillEffect.PILLEFFECT_RELAX] = 2,
	[PillEffect.PILLEFFECT_QUESTIONMARK] = 6,
	[PillEffect.PILLEFFECT_LARGER] = 6,
	[PillEffect.PILLEFFECT_SMALLER] = 6,
	[PillEffect.PILLEFFECT_INFESTED_EXCLAMATION] = 2,
	[PillEffect.PILLEFFECT_INFESTED_QUESTION] = 2,
	[PillEffect.PILLEFFECT_POWER] = 3,
	[PillEffect.PILLEFFECT_RETRO_VISION] = 6,
	[PillEffect.PILLEFFECT_FRIENDS_TILL_THE_END] = 1,
	[PillEffect.PILLEFFECT_X_LAX] = 1,
	[PillEffect.PILLEFFECT_SOMETHINGS_WRONG] = 1,
	[PillEffect.PILLEFFECT_IM_DROWSY] = 3,
	[PillEffect.PILLEFFECT_IM_EXCITED] = 6,
	[PillEffect.PILLEFFECT_GULP] = 4,
	[PillEffect.PILLEFFECT_HORF] = 1,
	[PillEffect.PILLEFFECT_SUNSHINE] = 1,
	[PillEffect.PILLEFFECT_VURP] = 6,
	[PillEffect.PILLEFFECT_SHOT_SPEED_DOWN] = 4,
	[PillEffect.PILLEFFECT_SHOT_SPEED_UP] = 6,
	[PillEffect.PILLEFFECT_EXPERIMENTAL] = 3
}

fix.cardCharge = {
	[Card.CARD_FOOL] = 2,
	[Card.CARD_MAGICIAN] = 2,
	[Card.CARD_HIGH_PRIESTESS] = 2,
	[Card.CARD_EMPRESS] = 3,
	[Card.CARD_EMPEROR] = 4,
	[Card.CARD_HIEROPHANT] = 12,
	[Card.CARD_LOVERS] = 6,
	[Card.CARD_CHARIOT] = 3,
	[Card.CARD_JUSTICE] = 6,
	[Card.CARD_HERMIT] = 2,
	[Card.CARD_WHEEL_OF_FORTUNE] = 6,
	[Card.CARD_STRENGTH] = 3,
	[Card.CARD_HANGED_MAN] = 4,
	[Card.CARD_DEATH] = 3,
	[Card.CARD_TEMPERANCE] = 6,
	[Card.CARD_DEVIL] = 3,
	[Card.CARD_TOWER] = 3,
	[Card.CARD_STARS] = 2,
	[Card.CARD_MOON] = 2,
	[Card.CARD_SUN] = 12,
	[Card.CARD_JUDGEMENT] = 6,
	[Card.CARD_WORLD] = 3,
	[Card.CARD_CLUBS_2] = 12,
	[Card.CARD_DIAMONDS_2] = 12,
	[Card.CARD_SPADES_2] = 12,
	[Card.CARD_HEARTS_2] = 12,
	[Card.CARD_ACE_OF_CLUBS] = 6,
	[Card.CARD_ACE_OF_DIAMONDS] = 6,
	[Card.CARD_ACE_OF_SPADES] = 6,
	[Card.CARD_ACE_OF_HEARTS] = 6,
	[Card.CARD_JOKER] = 2,
	[Card.CARD_CHAOS] = 6,
	[Card.CARD_CREDIT] = 6,
	[Card.CARD_RULES] = 1,
	[Card.CARD_HUMANITY] = 6,
	[Card.CARD_SUICIDE_KING] = 1,
	[Card.CARD_GET_OUT_OF_JAIL] = 2,
	[Card.CARD_QUESTIONMARK] = 4,
	[Card.CARD_HOLY] = 4,
	[Card.CARD_HUGE_GROWTH] = 3,
	[Card.CARD_ANCIENT_RECALL] = 12,
	[Card.CARD_ERA_WALK] = 3,
	[Card.CARD_REVERSE_FOOL] = 12,
	[Card.CARD_REVERSE_MAGICIAN] = 4,
	[Card.CARD_REVERSE_HIGH_PRIESTESS] = 4,
	[Card.CARD_REVERSE_EMPRESS] = 4,
	[Card.CARD_REVERSE_EMPEROR] = 2,
	[Card.CARD_REVERSE_HIEROPHANT] = 12,
	[Card.CARD_REVERSE_LOVERS] = 4,
	[Card.CARD_REVERSE_CHARIOT] = 2,
	[Card.CARD_REVERSE_JUSTICE] = 12,
	[Card.CARD_REVERSE_HERMIT] = 1,
	[Card.CARD_REVERSE_WHEEL_OF_FORTUNE] = 4,
	[Card.CARD_REVERSE_STRENGTH] = 3,
	[Card.CARD_REVERSE_HANGED_MAN] = 6,
	[Card.CARD_REVERSE_DEATH] = 4,
	[Card.CARD_REVERSE_TEMPERANCE] = 6,
	[Card.CARD_REVERSE_DEVIL] = 4,
	[Card.CARD_REVERSE_TOWER] = 3,
	[Card.CARD_REVERSE_STARS] = 12,
	[Card.CARD_REVERSE_MOON] = 2,
	[Card.CARD_REVERSE_SUN] = 6,
	[Card.CARD_REVERSE_JUDGEMENT] = 12,
	[Card.CARD_REVERSE_WORLD] = 2,
	[Card.CARD_QUEEN_OF_HEARTS] = 12,
	[Card.CARD_WILD] = 6
}

fix.runeCharge = {
	[Card.RUNE_HAGALAZ] = 2,
	[Card.RUNE_JERA] = 12,
	[Card.RUNE_EHWAZ] = 4,
	[Card.RUNE_DAGAZ] = 6,
	[Card.RUNE_ANSUZ] = 2,
	[Card.RUNE_PERTHRO] = 4,
	[Card.RUNE_BERKANO] = 2,
	[Card.RUNE_ALGIZ] = 4,
	[Card.RUNE_BLANK] = 3,
	[Card.RUNE_BLACK] = 4,
	[Card.RUNE_SHARD] = 1,
	[Card.CARD_SOUL_ISAAC] = 4,
	[Card.CARD_SOUL_MAGDALENE] = 3,
	[Card.CARD_SOUL_CAIN] = 6,
	[Card.CARD_SOUL_JUDAS] = 3,
	[Card.CARD_SOUL_BLUEBABY] = 3,
	[Card.CARD_SOUL_EVE] = 4,
	[Card.CARD_SOUL_SAMSON] = 6,
	[Card.CARD_SOUL_AZAZEL] = 6,
	[Card.CARD_SOUL_LAZARUS] = 1,
	[Card.CARD_SOUL_EDEN] = 4,
	[Card.CARD_SOUL_LOST] = 3,
	[Card.CARD_SOUL_LILITH] = 12,
	[Card.CARD_SOUL_KEEPER] = 12,
	[Card.CARD_SOUL_APOLLYON] = 6,
	[Card.CARD_SOUL_FORGOTTEN] = 4,
	[Card.CARD_SOUL_BETHANY] = 6,
	[Card.CARD_SOUL_JACOB] = 4
}

fix.diceCharge = {
	[0] = 4,
	[1] = 6,
	[2] = 6,
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 1,
	[7] = 3,
	[8] = 6,
	[9] = 6,
}

function fix:renderActive(player, playerIndex, playerPos)
	local activeId = player:GetActiveItem()
	
	if activeId ~= 0 then
		local active = Isaac.GetItemConfig():GetCollectible(activeId)
		local charge = player:GetActiveCharge()
		local overCharge = player:GetBatteryCharge()
		local maxCharge = active.MaxCharges
		local form = 0
		
		if fix.getMaxCharge[activeId] then
			maxCharge = fix.getMaxCharge[activeId](playerIndex)
		end
		
		if fix.getForm[activeId] then
			form = fix.getForm[activeId](player, playerIndex)
		end
		
		if not fix.sprites[playerIndex].active then
			fix.sprites[playerIndex].active = {
				id = 0,
				picture = Sprite(),
				
				bar = {
					background = Sprite(),
					greenFill = Sprite(),
					goldFill = Sprite(),
					marks = Sprite()
				}
			}
			
			fix.sprites[playerIndex].active.picture:Load("gfx/sprites/active.anm2", true)
			fix.sprites[playerIndex].active.picture:SetAnimation("Default")
			fix.sprites[playerIndex].active.picture:SetFrame(form)
			fix.sprites[playerIndex].active.picture.Scale = Vector(0.5, 0.5)
			
			for barPiece, sprite in pairs(fix.sprites[playerIndex].active.bar) do
				sprite:Load("gfx/sprites/ui_chargebar.anm2", true)
			end
			
			fix.sprites[playerIndex].active.bar.background:SetAnimation("BarEmpty")
			fix.sprites[playerIndex].active.bar.greenFill:SetAnimation("BarFull")
			fix.sprites[playerIndex].active.bar.goldFill:SetAnimation("BarFull")
			fix.sprites[playerIndex].active.bar.marks:SetAnimation("BarOverlay1")
			
			fix.sprites[playerIndex].active.bar.goldFill.Color = Color(1, 1, 1, 1, 1)
			
			for barPiece, sprite in pairs(fix.sprites[playerIndex].active.bar) do
				sprite:SetFrame(0)
				sprite.Scale = Vector(0.5, 0.5)
			end
		end
		
		if fix.sprites[playerIndex].active.id ~= activeId then
			fix.sprites[playerIndex].active.id = activeId
			
			fix.sprites[playerIndex].active.picture:ReplaceSpritesheet(0, fix.spritesheets[activeId] or active.GfxFileName)
			fix.sprites[playerIndex].active.picture:LoadGraphics()
		end
		
		fix.sprites[playerIndex].active.picture:SetFrame(form)
		fix.sprites[playerIndex].active.picture:Render(playerPos + Vector(-25, 10))
		
		if maxCharge > 0 then
			local numBars = maxCharge
			local cropGreen = (charge / maxCharge) * (fix.barBounds.top - fix.barBounds.bottom) + fix.barBounds.bottom
			local cropGold = (overCharge / maxCharge) * (fix.barBounds.top - fix.barBounds.bottom) + fix.barBounds.bottom
			
			if active.ChargeType == 1 or (active.ChargeType == 2 and not fix.isMaxChargeStandard[maxCharge]) then
				numBars = 1
			end
			
			fix.sprites[playerIndex].active.bar.marks:SetAnimation("BarOverlay" .. numBars, false)
			
			fix.sprites[playerIndex].active.bar.background:Render(playerPos + fix.barOffset)
			fix.sprites[playerIndex].active.bar.greenFill:Render(playerPos + fix.barOffset, Vector(0, cropGreen))
			fix.sprites[playerIndex].active.bar.goldFill:Render(playerPos + fix.barOffset, Vector(0, cropGold))
			fix.sprites[playerIndex].active.bar.marks:Render(playerPos + fix.barOffset)
		end
	end
end

function fix:renderTrinket(player, playerIndex, playerPos)
	if not fix.sprites[playerIndex].trinket then
		fix.sprites[playerIndex].trinket = {}
		
		for trinketIndex = 0, 1 do
			fix.sprites[playerIndex].trinket[trinketIndex] = {
				id = 0,
				sprite = Sprite()
			}
			
			fix.sprites[playerIndex].trinket[trinketIndex].sprite:Load("gfx/sprites/active.anm2", true)
			fix.sprites[playerIndex].trinket[trinketIndex].sprite:SetAnimation("Default")
			fix.sprites[playerIndex].trinket[trinketIndex].sprite:SetFrame(0)
			fix.sprites[playerIndex].trinket[trinketIndex].sprite.Scale = Vector(0.5, 0.5)
		end
	end
	
	for trinketIndex = 0, 1 do
		local trinketId = player:GetTrinket(trinketIndex)
		local isGold = trinketId > 32768
		
		if trinketId ~= 0 then
			local trinket = Isaac.GetItemConfig():GetTrinket(trinketId)
			
			if fix.sprites[playerIndex].trinket[trinketIndex].id ~= trinketId then
				fix.sprites[playerIndex].trinket[trinketIndex].id = trinketId
				
				fix.sprites[playerIndex].trinket[trinketIndex].sprite:ReplaceSpritesheet(0, trinket.GfxFileName)
				fix.sprites[playerIndex].trinket[trinketIndex].sprite:LoadGraphics()
				
				if isGold then
					fix.sprites[playerIndex].trinket[trinketIndex].sprite.Color = Color(1, 0.75, 0, 1, 0.25, 0.125)
				else
					fix.sprites[playerIndex].trinket[trinketIndex].sprite.Color = Color(1, 1, 1)
				end
			end
			
			fix.sprites[playerIndex].trinket[trinketIndex].sprite:Render(playerPos + Vector(20, 7 + trinketIndex * 8))
		end
	end
end

fix.font = Font()
fix.font:Load("font/pftempestasevencondensed.fnt")

function fix:renderPocket(player, playerIndex, playerPos)
	local isPill = false
	local pocketId = player:GetCard(0)
	local name = "???"
	local y = 27
	
	if pocketId == 0 then
		isPill = true
		pocketId = Game():GetItemPool():GetPillEffect(player:GetPill(0), player)
	end
	
	if not fix.sprites[playerIndex].pocket then
		fix.sprites[playerIndex].pocket = {
			isPill = false,
			sprite = Sprite()
		}
		
		fix.sprites[playerIndex].pocket.sprite:Load("gfx/sprites/ui_cardspills.anm2", true)
		fix.sprites[playerIndex].pocket.sprite:SetAnimation("CardFronts")
		fix.sprites[playerIndex].pocket.sprite:SetFrame(0)
		fix.sprites[playerIndex].pocket.sprite.Scale = Vector(0.5, 0.5)
	end
	
	if pocketId > 0 then
		if isPill then
			local pill = Isaac.GetItemConfig():GetPillEffect(pocketId)
			local color = player:GetPill(0)
			local isKnown = Game():GetItemPool():IsPillIdentified(color)
			
			y = 25
			
			if isKnown then
				name = pill.Name
			end
			
			if color > 2048 then
				fix.sprites[playerIndex].pocket.sprite:SetAnimation("HorsePills")
				fix.sprites[playerIndex].pocket.sprite:SetFrame(color - 2048)
			else
				fix.sprites[playerIndex].pocket.sprite:SetAnimation("Pills")
				fix.sprites[playerIndex].pocket.sprite:SetFrame(color)
			end
		else
			local card = Isaac.GetItemConfig():GetCard(pocketId)
			
			name = card.Name
			
			fix.sprites[playerIndex].pocket.sprite:SetAnimation("CardFronts")
			fix.sprites[playerIndex].pocket.sprite:SetFrame(pocketId)
		end
		
		name = name:gsub("#", ""):gsub("_NAME", ""):gsub("_", " ")
		
		local offset = fix.font:GetStringWidth(name) / 4 + 5
		
		fix.sprites[playerIndex].pocket.sprite:Render(playerPos + Vector(offset, y))
		fix.sprites[playerIndex].pocket.sprite:Render(playerPos + Vector(-offset, y))
		
		fix.font:DrawStringScaled(name, playerPos.X - 1, playerPos.Y + 20, 0.5, 0.5, KColor(1, 1, 1, 1), 2, true)
	end
end

function fix:onPostRender()
	if fix.cf.saveData.esauUi < 2 then
		for playerIndex = fix.cf.saveData.esauUi * 2, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(playerIndex)
			
			if player:GetPlayerType() == PlayerType.PLAYER_ESAU or (player:GetPlayerType() == PlayerType.PLAYER_JACOB and fix.cf.saveData.jacobUi) then
				local playerPos = fix.cf:worldToScreen(player.Position)
				
				if not fix.sprites[playerIndex] then
					fix.sprites[playerIndex] = {}
				end
				
				if not Game():IsPaused() and Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
					fix:onDropTriggered(player, playerIndex)
				end
				
				if Game():GetHUD():IsVisible() then
					fix:renderHealth(player, playerIndex, playerPos)
					fix:renderActive(player, playerIndex, playerPos)
					fix:renderTrinket(player, playerIndex, playerPos)
					fix:renderPocket(player, playerIndex, playerPos)
				end
			end
		end
	end
end

function fix:onUseItemJarOfWisps(id, rng, player, flags, slot, data)
	local playerId = fix.cf:getPlayerId(player)
	local numWisps = fix.cf:getData(playerId, "jarOfWisps", 1)
	
	if numWisps < 12 then
		fix.cf:setData(playerId, "jarOfWisps", numWisps + 1)
	end
end

function fix:onUsePill(pill, player, flags)
	local playerId = fix.cf:getPlayerId(player)
	
	if flags & UseFlag.USE_MIMIC ~= 0 and fix.pillCharge[pill] then
		fix.cf:setData(playerId, "placebo", fix.pillCharge[pill])
	end
end

function fix:onUseCard(card, player, flags)
	local playerId = fix.cf:getPlayerId(player)
	
	if flags & UseFlag.USE_MIMIC ~= 0 then
		if fix.runeCharge[card] then
			fix.cf:setData(playerId, "clearRune", fix.runeCharge[card])
		elseif fix.cardCharge[card] then
			fix.cf:setData(playerId, "blankCard", fix.cardCharge[card])
		end
	end
end

function fix:onUseItemDInfinity(id, rng, player, flags, slot, data)
	local playerId = fix.cf:getPlayerId(player)
	
	fix.cf:setData(playerId, "dInfinityMaxCharge", fix.diceCharge[fix.cf:getData(playerId, "dInfinityForm", 0)])
end

function fix:addCallbacks()
	fix.cf.mod:AddCallback(ModCallbacks.MC_POST_RENDER, fix.onPostRender)
	fix.cf.mod:AddCallback(ModCallbacks.MC_USE_ITEM, fix.onUseItemJarOfWisps, Isaac.GetItemIdByName("Jar of Wisps"))
	fix.cf.mod:AddCallback(ModCallbacks.MC_USE_PILL, fix.onUsePill)
	fix.cf.mod:AddCallback(ModCallbacks.MC_USE_CARD, fix.onUseCard)
	fix.cf.mod:AddCallback(ModCallbacks.MC_USE_ITEM, fix.onUseItemDInfinity, Isaac.GetItemIdByName("D infinity"))
end

-- return object

return fix
