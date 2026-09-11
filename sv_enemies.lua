function nzEnemies:TotalAlive()
	local c = 0
	local tbl = {}

	-- Count
	for k,v in nzLevel.GetZombieArray() do -- FUCK YOU, ARRAYS ARE AWESOME!!!
		if IsValid(v) and !v.IsENVZombie and v:IsAlive() and !v.Dying and !v.NZBossType and !v.IsMooBossZombie then
			--print(k)
			c = 0
			c = c + k
		end
	end

	return c
end

function nzEnemies:OnZombieSpawned(zombie, spawnpoint)

end

-- It might save SOME resources if this is run by itself here, instead of having each Zombie run the function in the zombiebase on their own.
function nzEnemies:UpdateZombieRepathMod()
	-- If we reach the Game Over state, just remove the timer and back out. A new one will be made next game.
	if nzRound:InState( ROUND_GO ) and timer.Exists("nZR.Timer.Zombie_RepathMod_Update") then
		timer.Remove("nZR.Timer.Zombie_RepathMod_Update")
		return
	end

	local RepathTimeMod = 0
	for k,v in nzLevel.GetZombieArray() do
		RepathTimeMod = RepathTimeMod + 0.05
	end
	self.ZombieRepathTime = RepathTimeMod

	return self.ZombieRepathTime
end

function nzEnemies:GetZombieRepathMod()
	-- Use this to obtain the newly updated value.
	return self.ZombieRepathTime or 1
end

-- At the start of a game, we create this timer. The function will continue to run until game over.
hook.Add("OnRoundInit", "CreateZombieRepathModTimer", function()
	timer.Create("nZR.Timer.Zombie_RepathMod_Update", 2, 0, function() 
		nzEnemies:UpdateZombieRepathMod()
	end)
end)

hook.Add("PlayerSpawn", "nzPlayerMakeTargetTable", function(ply, trans)
	-- Used for zombies when deciding who to target.
	ply.TargetTable = {}
end)
