-- main object

local fix = {}

-- add callbacks

fix.sprites = {}

function fix:onPostRender()
	if fix.cf.saveData.taintedBlueUi < 2 then
		for playerIndex = fix.cf.saveData.taintedBlueUi, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(playerIndex)
			
			if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY_B then
				local playerPos = fix.cf:worldToScreen(player.Position)
				
				if not fix.sprites[playerIndex] then
					fix.sprites[playerIndex] = {}
					
					for spriteIndex = 0, 5 do
						fix.sprites[playerIndex][spriteIndex] = Sprite()
						fix.sprites[playerIndex][spriteIndex]:Load("gfx/sprites/ui_poops.anm2", true)
						fix.sprites[playerIndex][spriteIndex]:SetAnimation("IdleSmall")
					end
				end
				
				for spriteIndex = 0, 5 do
					local x = 16 * (spriteIndex % 3 - 1)
					local y = 16 * math.floor(spriteIndex / 3) + 8
					
					if player:GetPoopMana() > spriteIndex then
						fix.sprites[playerIndex][spriteIndex].Color = Color(1, 1, 1, 1)
					else
						fix.sprites[playerIndex][spriteIndex].Color = Color(1, 1, 1, 0.125)
					end
					
					fix.sprites[playerIndex][spriteIndex]:SetFrame(player:GetPoopSpell(spriteIndex))
					fix.sprites[playerIndex][spriteIndex]:Render(playerPos + Vector(x, y))
					
					if Game():GetHUD():IsVisible() then
						fix.sprites[playerIndex][spriteIndex]:Render(playerPos + Vector(x, y))
					end
				end
			end
		end
	end
end

function fix:addCallbacks()
	fix.cf.mod:AddCallback(ModCallbacks.MC_POST_RENDER, fix.onPostRender)
end

-- return object

return fix
