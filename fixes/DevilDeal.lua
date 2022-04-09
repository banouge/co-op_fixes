-- main object

local fix = {}

-- add callbacks

function fix:getPrice(player, price)
	if player:HasTrinket(TrinketType.TRINKET_YOUR_SOUL) then
		return PickupPrice.PRICE_SOUL
	end
	
	if player:HasTrinket(TrinketType.TRINKET_JUDAS_TONGUE) then
		price = 1
	end
	
	if price == 1 then
		if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY then
			return -7
		end
		
		if player:GetMaxHearts() < 2 then
			return PickupPrice.PRICE_THREE_SOULHEARTS
		end
		
		return PickupPrice.PRICE_ONE_HEART
	else
		if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY then
			return -8
		end
		
		if player:GetMaxHearts() < 2 then
			return PickupPrice.PRICE_THREE_SOULHEARTS
		end
		
		if player:GetMaxHearts() < 4 then
			return PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS
		end
		
		return PickupPrice.PRICE_TWO_HEARTS
	end
	
	return PickupPrice.PRICE_ONE_HEART
end

function fix:onPostPickupUpdate(pickup)
	if fix.cf.saveData.devilDeal and pickup.Price >= -9 and pickup.Price <= PickupPrice.PRICE_ONE_HEART then
		local price = Isaac.GetItemConfig():GetCollectible(pickup.SubType).DevilPrice or 1
		local player = Isaac.GetPlayer(0)
		local distance = player.Position:Distance(pickup.Position)
		
		for playerIndex = 1, Game():GetNumPlayers() - 1 do
			local newPlayer = Isaac.GetPlayer(playerIndex)
			local newDistance = newPlayer.Position:Distance(pickup.Position)
			
			if newDistance < distance then
				player = newPlayer
				distance = newDistance
			end
		end
		
		pickup.Price = fix:getPrice(player, price)
	end
end

function fix:addCallbacks()
	fix.cf.mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, fix.onPostPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE)
end

-- return object

return fix
