function nzDoors:OpenDoor( ent, ply )
	if !IsValid(ent) then return end
	
	local data = ent:GetDoorData()
	local link = data.link
	local rebuyable = data.rebuyable
	
	-- Open the door and any other door with the same link
	if ent:IsScriptBuyable() then
		ent.BuyFunction(ply)
		if !tobool(rebuyable) then
			ent:SetLocked(false)
		end
	elseif ent:IsButton() then
		ent:UnlockButton(tobool(ent.rebuyable))
	else
		ent:UnlockDoor()
	end

	-- Merge Nav Groups
	if ent.navgroup1 and ent.navgroup2 then
		nzNav.Functions.MergeNavGroups(ent.navgroup1, ent.navgroup2)
	end
	if ent.linkedmeshes then
		nzNav.Functions.OnNavMeshUnlocked(ent.linkedmeshes)
	end
	
	
	-- Sync
	if link != nil then
		self.OpenedLinks[link] = true
	end
	hook.Call("OnDoorUnlocked", self, ent, link, rebuyable, ply)
end

function nzDoors:OpenLinkedDoors( link, ply )
	-- Go through all the doors
	for k,v in pairs(self.MapDoors) do
		if v.flags then
			local doorlink = v.flags.link
			if doorlink and doorlink == link then
				self:OpenDoor( self:DoorIndexToEnt(k), ply )
			end
		end
	end
	
	for k,v in pairs(self.PropDoors) do
		if v.flags then
			local doorlink = v.flags.link
			if doorlink and doorlink == link then
				self:OpenDoor( Entity(k), ply )
			end
		end
	end
	
	self.OpenedLinks[link] = true
end

function nzDoors:CloseLinkedDoors( link )
    -- Go through all the doors
    for k,v in pairs(self.MapDoors) do
        if v.flags then
            local doorlink = v.flags.link
            if doorlink and doorlink == link then
            	-- Huge thankie mcspankie to Hidden for the fix
                local doorent = self:DoorIndexToEnt(k)
                if doorent:IsButton() then
                    doorent:LockButton()
                    doorent:SetUseType( SIMPLE_USE )
                else
                    doorent:SetUseType( SIMPLE_USE )
                    doorent:LockDoor()
                    doorent:SetKeyValue("wait",-1)
                    --print("Locked door ", v)
                end
            end
        end
    end
    
    for k,v in pairs(self.PropDoors) do
        if v.flags then
            local doorlink = v.flags.link
            if doorlink and doorlink == link then
                local doorent = Entity(k)
                doorent:SetUseType( SIMPLE_USE )
                doorent:LockDoor()
            end
        end
    end
    
    self.OpenedLinks[link] = nil
end

function nzDoors:LockAllDoors()
	-- Force all doors to lock and stay open when opened
	for k,v in ents.Iterator() do
		if ( v:IsDoor() or v:IsBuyableProp() ) then
			-- Only lock doors that have been assigned a price - Prop Dynamics may be tied to invisible func_doors
			if self.MapDoors[v:DoorIndex()] or self.PropDoors[v:EntIndex()] then
				v:SetUseType( SIMPLE_USE )
				v:LockDoor()
				v:SetKeyValue("wait",-1)
                if GetConVar("developer"):GetInt() == 1 then
                    print("Locked door ", v)
                end
				-- Also reset their NW2 price if it has been modified by anybody
				if v:GetNW2Bool("PriceAdjusted") then
					local doorData = v:GetDoorData()
					v:SetNW2Int("Price", doorData.price)
					v:SetNW2Bool("PriceAdjusted", false)
				end
			else
				-- Unlocked doors get an output which forces it to stay open once you open it
				v:Fire("addoutput", "onclose !self:open::0:-1,0,-1")
				v:Fire("addoutput", "onclose !self:unlock::0:-1,0,-1")
                if GetConVar("developer"):GetInt() == 1 then
					print("Added lock output to", v)
                end
				-- They now get that output through OpenDoor too, but for safety
			end
		-- Allow locking buttons
		elseif v:IsButton() and self.MapDoors[v:DoorIndex()] and v.ButtonLock then
			v:ButtonLock()
			v:SetUseType( SIMPLE_USE )
		end
	end
    for _, pfxEnt in pairs(ents.FindByClass("prop_buys_pfx")) do
        if IsValid(pfxEnt) then
            pfxEnt:OnDoorsLocked()
        end
    end
	self.OpenedLinks = {}
	for k, v in pairs(self.PropDoors) do
		local ent = Entity(k)
		if IsValid(ent) then
			ent.PayHalfPlayers = {}
		end
	end
	hook.Call("OnAllDoorsLocked", self)
end

function nzDoors:BuyDoor( ply, ent )
	if ent.lasttime and ent.lasttime + 2 > CurTime() then return end
	
	local flags = ent:GetDoorData()
	if !flags then return end
	
	local price = tonumber(ent:GetNW2Int("Price", flags.price)) or tonumber(flags.price) or 0
	local req_elec = tonumber(flags.elec) or 0
	local link = flags.link
	local buyable = tonumber(flags.buyable) or 1

	-- If we're in ROUND_CREATE, force door open for free
	if nzRound:InState(ROUND_CREATE) then
		if ent:IsLocked() then
			if link == nil then
				self:OpenDoor(ent, ply)
			else
				self:OpenLinkedDoors(link, ply)
			end
		end
		ent.lasttime = CurTime()
		return
	end

	-- Normal buying behavior
	if buyable == 1 then
		ply:Buy(price, ent, function()
			if ent:IsLocked() and ( req_elec == 0 or ( req_elec == 1 and IsElec() ) ) then

				if link == nil then
					self:OpenDoor( ent, ply )
				else
					self:OpenLinkedDoors( link, ply )
				end

				return true
			end
		end)
	elseif price == 0 and buyable == 0 and !ent:IsBuyableProp() then
		ent:UnlockDoor()
	end
	
	ent.lasttime = CurTime()
end

-- Update linked doors with same flag to have adjusted price
function nzDoors:UpdateLinkedDoorPrices( link, new_price, mark_players )
	if !link then return end
	
	-- Update all map doors with same link
	for k,v in pairs(self.MapDoors) do
		if v.flags and v.flags.link == link then
			local doorent = self:DoorIndexToEnt(k)
			if IsValid(doorent) and doorent:IsLocked() then
				doorent:SetNW2Int("Price", new_price)
				doorent:SetNW2Bool("PriceAdjusted", true)
				
				-- Sync PayHalfPlayers table
				if mark_players and !doorent.PayHalfPlayers then
					doorent.PayHalfPlayers = {}
				end
				if mark_players then
					for plyID, _ in pairs(mark_players) do
						doorent.PayHalfPlayers[plyID] = true
					end
				end
			end
		end
	end
	
	-- Update all prop doors with same link
	for k,v in pairs(self.PropDoors) do
		if v.flags and v.flags.link == link then
			local doorent = Entity(k)
			if IsValid(doorent) and doorent:IsLocked() then
				doorent:SetNW2Int("Price", new_price)
				doorent:SetNW2Bool("PriceAdjusted", true)
				
				-- Sync PayHalfPlayers table
				if mark_players and !doorent.PayHalfPlayers then
					doorent.PayHalfPlayers = {}
				end
				if mark_players then
					for plyID, _ in pairs(mark_players) do
						doorent.PayHalfPlayers[plyID] = true
					end
				end
			end
		end
	end
end

-- yuri, my lovely girfriend, wife, partner, and horsething, im gonna staple you to a wall. - latte  
function nzDoors:PayHalf( ply, ent )
	if ent.lasttime and ent.lasttime + 2 > CurTime() then return end
	
	-- Check if pay half feature is enabled
	local payHalfEnabled = nzMapping.Settings.payhalfenabled == nil and true or tobool(nzMapping.Settings.payhalfenabled)
	if !payHalfEnabled then return end
	
	local flags = ent:GetDoorData()
	if !flags then return end
	
	-- Check if price is already adjusted (already half bought)
	if ent:GetNW2Bool("PriceAdjusted", false) then
		return
	end
	
	-- Check if this player has already paid half for this door
	if !ent.PayHalfPlayers then
		ent.PayHalfPlayers = {}
	end
	
	local plyID = ply:SteamID()
	if ent.PayHalfPlayers[plyID] then
		-- Player has already paid half for this door
		return
	end
	
	local price = tonumber(ent:GetNW2Int("Price", flags.price)) or tonumber(flags.price) or 0
	local price_half = math.Round( price / 2 )
	local req_elec = tonumber(flags.elec) or 0
	local buyable = tonumber(flags.buyable) or 1
	local link = flags.link

	-- Normal buying behavior
	if price > 0 and buyable == 1 then
		ply:Buy(price_half, ent, function()
			if ent:IsLocked() and ( req_elec == 0 or ( req_elec == 1 and IsElec() ) ) then

				ent:SetNW2Int("Price", price_half)
				ent:SetNW2Bool("PriceAdjusted", true)
				
				-- Mark this player as having paid half
				ent.PayHalfPlayers[plyID] = true
				
				-- Update all linked doors with same flag
				if link then
					self:UpdateLinkedDoorPrices(link, price_half, {[plyID] = true})
				end

				return true
			end
		end)
	end
	
	ent.lasttime = CurTime() - 1
end

-- Hooks

function nzDoors.OnUseDoor( ply, ent )
	-- Downed players can't use anything!
	if !ply:GetNotDowned() then return false end

	-- Players can't use stuff while using special weapons! (Perk bottles, knives, etc)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:IsSpecial() then
		local papapunch = (IsValid(ent) and ent:GetClass() == "perk_machine" and ent:GetPerkID() == "pap")
		if papapunch then
			if (wep.AllowInteraction and !wep.NZSpecialPAP) or !wep.NZSpecialPAP then
				return false
			end
		else
			if !wep.AllowInteraction then
				return false
			end
		end
	end

	if ent:IsBuyableEntity() and ( ent.buyable == nil or tobool(ent.buyable) ) then
		
		-- Check if pay half feature is enabled
		local payHalfEnabled = nzMapping.Settings.payhalfenabled == nil and true or tobool(nzMapping.Settings.payhalfenabled)
		
		-- Check if door is already half bought
		local priceAdjusted = ent:GetNW2Bool("PriceAdjusted", false)
		
		-- Only allow pay half if feature is enabled, door isn't already half bought, and sprint is held
		if ply:KeyDown(IN_SPEED) and !nzRound:InState(ROUND_CREATE) and payHalfEnabled and !priceAdjusted then
			nzDoors:PayHalf( ply, ent )
		else
			nzDoors:BuyDoor( ply, ent )
		end

	end
end
hook.Add("PlayerUse", "nzPlayerBuyDoor", nzDoors.OnUseDoor)

function nzDoors.CheckUseDoor(ply, ent)
	--print(ply, ent)

	local tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector()*100, ply)
	local door = tr.Entity
	--print(door)
	
	if IsValid(door) and door:IsDoor() then
		return door
	else
		for k,v in pairs(ents.FindInSphere(ply:EyePos(), 1)) do
			if v:GetClass() == "nz_triggerzone" then
				return v
			end
		end
	end
	
end

hook.Add("FindUseEntity", "nzCheckDoor", nzDoors.CheckUseDoor)