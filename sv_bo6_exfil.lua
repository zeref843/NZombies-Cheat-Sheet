-- Made by Hari exclusive for nZombies Rezzurection. Copying this code is prohibited!

util.AddNetworkString("nZr.ExfilTimer")
util.AddNetworkString("nZr.ExfilCutscene")
util.AddNetworkString("nZr.ExfilPosition")
util.AddNetworkString("nZr.ExfilMessage")
util.AddNetworkString("nzPreviewExfilAnim")
util.AddNetworkString("nzPreviewVOXDialog")

nZr_Exfil_Map_Positions = nZr_Exfil_Map_Positions or {}
nZr_Exfil_Map_Angles = nZr_Exfil_Map_Angles or {}

local function nZr_UpdatePositions()
    local datab = ents.FindByClass("bo6_exfil_point")
    local pos_tab = {}
    local ang_tab = {}
    for _, ent in pairs(datab) do
        table.insert(pos_tab, ent:GetPos())
        table.insert(ang_tab, ent:GetAngles())
    end
    nZr_Exfil_Map_Positions = pos_tab
    nZr_Exfil_Map_Angles = ang_tab
end

-- Helper function to check if radio has power (when required)
local function nZr_Exfil_RadioHasPower()
    local rad = ents.FindByClass("bo6_exfil_radio")[1]
    if not IsValid(rad) then return false end
    
    -- If power is not required, always return true
    if not nzSettings:GetSimpleSetting("ExfilRadioRequirePower", false) then
        return true
    end
    
    -- If power is required, check the electricity state
    return rad:GetElecState()
end

-- Helper function to check if exfil is available this round
local function nZr_Exfil_IsAvailableThisRound()
    local rad = ents.FindByClass("bo6_exfil_radio")[1]
    if not IsValid(rad) then return false end
    
    return nzSettings:GetSimpleSetting("ExfilEnabled", true) and 
           (nzRound:GetNumber() >= nzSettings:GetSimpleSetting("ExfilFirstRound", 11) and 
           (nzRound:GetNumber()-nzSettings:GetSimpleSetting("ExfilFirstRound", 11)) % nzSettings:GetSimpleSetting("ExfilEveryRound", 5) == 0)
end

nZr_Exfil_Heli = nil
nZr_Exfil_Position = nil
nZr_Exfil_Angles = nil
nZr_Exfil_Enemies = 1
nZr_Exfil_Landing = false
nZr_Exfil_RadioActive = true

local function nZr_CalculateZombies()
    if nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false) then
        return 999
    end
    
    local MIN_ZOMBIES = 1
    local MAX_ZOMBIES = math.max(1, nzSettings:GetSimpleSetting("ExfilMaxZombies", 84))
    local BASE_MULTIPLIER = 1 
    local WAVE_SCALING = 1.1
    local PLAYER_SCALING_BASE = 4
    local PLAYER_SCALING_EXTRA = 0.2

    local wave = nzRound:GetNumber()
    local playerCount = #player.GetAllPlayingAndAlive()
    local baseZombies = wave * BASE_MULTIPLIER
    local waveFactor = math.pow(wave, WAVE_SCALING)
    local playerFactor = playerCount * (PLAYER_SCALING_BASE + (wave * PLAYER_SCALING_EXTRA))
    local zombieCount = math.floor(baseZombies + waveFactor + playerFactor)
    
    zombieCount = math.max(zombieCount, MIN_ZOMBIES)
    zombieCount = math.min(zombieCount, MAX_ZOMBIES)
    
    return zombieCount
end

local function nZr_ChangeGameOverDelay()
    local def = nzMapping.Settings.gocamerawait
    nzMapping.Settings.gocamerawait = 5
    BroadcastLua([[nzMapping.Settings.gocamerawait = ]]..5)
    timer.Simple(1, function()
        nzMapping.Settings.gocamerawait = def
        BroadcastLua([[nzMapping.Settings.gocamerawait = ]]..def)
    end)
end

local ktab = {"bo6_choppergunner", "bo6_rcxd", "bo6_hellstorm", "bo6_sentry"}
function nZr_Exfil_RemoveKillstreaks()
    for _, ent in pairs(ents.FindByClass("bo6_*")) do
        if table.HasValue(ktab, ent:GetClass()) then
            ent:Remove()
        end
    end
end

function nZr_Exfil_Message(type)
    net.Start("nZr.ExfilMessage")
    net.WriteInt(type, 32)
    net.Broadcast()
end

function nZr_Exfil_PreviewCutscene(is_success, ply)
    local npos, nang, ndist = nil, nil, math.huge
    for _, ent in pairs(ents.FindByClass("bo6_exfil_point")) do
        if ply:GetPos():DistToSqr(ent:GetPos()) < ndist then
            ndist = ply:GetPos():DistToSqr(ent:GetPos())
            nang = ent:GetAngles()
            npos = ent:GetPos()
        end
    end
    local cutent = ents.FindByClass("bo6_exfil_cutscene")[1]
    if IsValid(cutent) then
        nang = cutent:GetAngles()
        npos = cutent:GetPos()
    end
    if !isvector(npos) then return end

    net.Start("nZr.ExfilCutscene")
    net.WriteBool(is_success)
    net.WriteVector(npos)
    net.WriteAngle(nang)
    net.WriteTable(nzFuncs:GetZombieMapModel(true))
    net.Send(ply)
end

net.Receive("nzPreviewExfilAnim", function(len, ply)
    if not nzRound:InState( ROUND_CREATE ) then return end
    local bool = net.ReadBool()
    nZr_Exfil_PreviewCutscene(bool, ply)
end)

net.Receive("nzPreviewVOXDialog", function(len, ply)
    if not nzRound:InState( ROUND_CREATE ) then return end
    local str = net.ReadString()
    nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor")..str)
end)

function nZr_Exfil_Cutscene(is_success, pos, ang)
    net.Start("nZr.ExfilCutscene")
    net.WriteBool(is_success)
    net.WriteVector(pos)
    net.WriteAngle(ang)
    net.WriteTable(nzFuncs:GetZombieMapModel(true))
    net.Broadcast()
end

function nZr_Exfil_CreateCountdown(time)
    time = time or nzSettings:GetSimpleSetting("ExfilTime", 90)
    timer.Create("BO6_Exfil_Timer", time, 1, function()
        local pos = nZr_Exfil_Position
        local ang = nZr_Exfil_Angles
        local cutent = ents.FindByClass("bo6_exfil_cutscene")[1]
        if IsValid(cutent) then
            ang = cutent:GetAngles()
            pos = cutent:GetPos()
        end

        if nZr_Exfil_Enemies == 0 and !nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false) then
            nZr_Exfil_Stop(true)
        else
            if !nzSettings:GetSimpleSetting("ExfilGround", false) then nZr_Exfil_Cutscene(false, pos, ang) end
            nZr_Exfil_Stop()
        end
    end)
end

function nZr_Exfil_StartRandom()
    if #nZr_Exfil_Map_Positions == 0 then 
        print("[ERROR] No Exfil positions on map!") 
        return 
    end

    local id = math.random(1,#nZr_Exfil_Map_Positions)
    local pos = nZr_Exfil_Map_Positions[id]
    local ang = nZr_Exfil_Map_Angles[id]
    nZr_Exfil_RadioActive = false
    nzPowerUps:Nuke(nil, nil, nil, true)
    nzFuncs:PlayClientSound("bo6/exfil/nuke_sound.mp3")
    nzRound:Freeze(true)
    nzRound:SetZombiesMax(0)
    timer.Simple(4, function()
        if #player.GetAllPlayingAndAlive() == 0 then return end
        for k,v in pairs(ents.GetAll()) do
            if v:IsNextBot() and isfunction(v.TakeDamage) then
                v:TakeDamage(math.huge)
            end
        end
        local zmax = nZr_CalculateZombies()
        nzRound:SetZombiesMax(zmax)
        nzRound:SetZombiesToSpawn(nzRound:GetZombiesMax())
        nzRound:SetZombiesKilled(0)
        nzRound.NumberZombies = nzRound:GetZombiesMax()
        nZr_Exfil_Start(pos, ang)
    end)
end

function nZr_Exfil_Start(pos, ang)
    if !isvector(pos) and !isangle(ang) then return end
    nZr_Exfil_Landing = false
    nZr_Exfil_Position = pos
    nZr_Exfil_Angles = ang
    nZr_Exfil_Enemies = nzRound:GetZombiesMax()
    if nzSettings:GetSimpleSetting("ExfilBossEnabled", true) and nzRound:GetNumber() >= nzSettings:GetSimpleSetting("ExfilBossRound", 21) then
        timer.Simple(nzSettings:GetSimpleSetting("ExfilBossDelay", 10), function()
            if nzRound:GetState() != ROUND_PROG then return end
            local boss = nzRound:SpawnBoss()
            if IsValid(boss) then
                nZr_Exfil_Enemies = nZr_Exfil_Enemies + 1
            end
        end)
    end

    hook.Call("OnExfilStart", nil)
    nZr_Exfil_ShowPosition(true, pos, 2)
    nZr_Exfil_ShowTimer(nzSettings:GetSimpleSetting("ExfilTime", 90), 1, nZr_Exfil_Enemies)
    nZr_Exfil_CreateCountdown()

    local lp = pos+Vector(0,0,128)
    BroadcastLua([[
        local ef = EffectData()
        ef:SetOrigin(Vector(]]..lp.x..","..lp.y..","..lp.z..[[))
        ef:SetNormal(Vector(0, 0, 1))
        util.Effect("bo6_exfil_flare", ef)
    ]])

    local time = nzSettings:GetSimpleSetting("ExfilArriveTime", 20)
    timer.Create("BO6_Exfil_HeliSpawn", time, 1, function()
        local heli = ents.Create("bo6_animated")
        local pos1 = pos
        local ang1 = ang
        local cutent = ents.FindByClass("bo6_exfil_cutscene")[1]
        if IsValid(cutent) then
            ang1 = cutent:GetAngles()
            pos1 = cutent:GetPos()
        end

        heli:SetPos(pos1+Vector(0,0,400))
        heli:SetAngles(ang1)
        heli:Spawn()
        heli:SetBodygroup(3,1)
        heli:ResetSequence("spawn")
        if nzSettings:GetSimpleSetting("ExfilGround", false) then
            heli:SetNoDraw(true)
        end
        nZr_Exfil_Heli = heli
        nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_Arrive")
        timer.Simple(7, function()
            if IsValid(nZr_Exfil_Heli) and nZr_Exfil_Enemies > 0 then
                nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_Clear")
            end
        end)
    end)
    timer.Create("BO6_Exfil_Faster", nzSettings:GetSimpleSetting("ExfilTime", 90)-30, 1, function()
        nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_30sec")
        timer.Create("BO6_Exfil_Faster", 15, 1, function()
            nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_15sec")
            timer.Simple(5, function()
                if IsValid(nZr_Exfil_Heli) and (nZr_Exfil_Enemies < 5 and nZr_Exfil_Enemies > 0) and !IsValid(ents.FindByClass("*_boss_*")[1]) then
                    nZr_Exfil_Enemies = 0
                    nzPowerUps:Nuke(nil, nil, nil, true)
                end
            end)
        end)
    end)
    timer.Simple(4, function()
        nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_Start")
    end)
end

function nZr_Exfil_Stop(is_success)
    local damageplayers = false
    hook.Call("OnExfilScene", nil, is_success)
    if is_success then
        local pos1 = nZr_Exfil_Position
        local ang1 = nZr_Exfil_Angles
        local cutent = ents.FindByClass("bo6_exfil_cutscene")[1]
        if IsValid(cutent) then
            ang1 = cutent:GetAngles()
            pos1 = cutent:GetPos()
        end
        local time = 13
        if !nzSettings:GetSimpleSetting("ExfilGround", false) then 
            nZr_Exfil_Cutscene(true, pos1, ang1) 
        else
            time = 0
        end
        if nzSettings:GetSimpleSetting("ExfilLibertySuccess", false) then
            time = 16.43
        end
        timer.Simple(time, function()
            nZr_Exfil_RadioActive = true
            nZr_ChangeGameOverDelay()
            nzRound:Win(nil, nil, nzMapping.Settings.gameovertime+5)
            timer.Remove("NZRoundThink")
            nzRound:Freeze(false)
        end)
    else
        if nzSettings:GetSimpleSetting("ExfilGround", false) then
            nZr_Exfil_RadioActive = true
            nzRound:Freeze(false)
            damageplayers = true
        else
            timer.Simple(13, function()
                nZr_Exfil_RadioActive = true
                nZr_ChangeGameOverDelay()
                nzRound:Lose(nil, nzMapping.Settings.gameovertime+5)
                timer.Remove("NZRoundThink")
                nzRound:Freeze(false)
            end)
        end
    end
    timer.Remove("BO6_Exfil_Timer")
    timer.Remove("BO6_Exfil_HeliSpawn")
    timer.Remove("BO6_Exfil_Faster")
    nZr_Exfil_ShowPosition(false)
    nZr_Exfil_ShowTimer(0, 1, 0, nil, true)
    nZr_Exfil_Position = nil
    nZr_Exfil_Angles = nil
    nZr_Exfil_Landing = false
    nZr_Exfil_Enemies = 1
    if IsValid(nZr_Exfil_Heli) then
        nZr_Exfil_Heli:Remove()
        nZr_Exfil_Heli = nil
    end
    for _, ply in pairs(player.GetAll()) do
        if damageplayers then
            ply:RemovePerks()
            ply:DownPlayer()
        else
            if ply:GetNotDowned() then
                ply:KillSilent()
            else
                ply:KillDownedPlayer(true)
            end
        end
    end
    nzRound:SetZombiesMax(0)
    nzRound:SetZombiesToSpawn(0)
    nzRound:SetZombiesKilled(0)
    for k,v in pairs(ents.GetAll()) do
        if v:IsNextBot() and !damageplayers then
            v:Remove()
        end
    end
end

function nZr_Exfil_ShowPosition(state, pos, type)
    type = type or 0
    pos = pos or Vector(0,0,0)
    net.Start("nZr.ExfilPosition")
    net.WriteBool(state)
    net.WriteVector(pos+Vector(0,0,64))
    net.WriteInt(type, 32)
    net.Broadcast()
end

function nZr_Exfil_ShowTimer(time, state, enemies, ply, disable)
    time = time or 0
    if nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false) then
        state = 3
    end
    disable = disable or false
    net.Start("nZr.ExfilTimer")
    net.WriteInt(time, 32)
    net.WriteInt(state, 32)
    net.WriteInt(enemies, 32)
    net.WriteBool(disable)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

hook.Add("OnZombieKilled", "nZr_Exfil_Think", function(ent)
    if nZr_Exfil_Position != nil then
        nZr_Exfil_Enemies = math.max(nZr_Exfil_Enemies - 1, 0)
    end
end)

hook.Add("OnBossKilled", "nZr_Exfil_Think", function()
    if nZr_Exfil_Position != nil then
        nZr_Exfil_Enemies = math.max(nZr_Exfil_Enemies - 1, 0)
    end
end)

local alive_count_delay = 0
hook.Add("Think", "nZr_Exfil_Think", function()
    if !timer.Exists("BO6_Exfil_Timer") or nZr_Exfil_Position == nil then return end
    
    local alivecount = 0
    local tab = player.GetAll()
    for i=1,#tab do
        ply = tab[i]
        if nZr_Exfil_Landing then
            if IsValid(nZr_Exfil_Heli) and nZr_Exfil_Heli.loading and ply:Alive() and ply:GetPos():DistToSqr(nZr_Exfil_Position) < nzSettings:GetSimpleSetting("ExfilLoadDis", 200)^2 then
                nZr_Exfil_Stop(true)
            else
                nZr_Exfil_ShowTimer(timer.TimeLeft("BO6_Exfil_Timer"), 3, nZr_Exfil_Enemies, ply)
            end
        else
            if ply:Alive() and ply:GetPos():DistToSqr(nZr_Exfil_Position) < (nzSettings:GetSimpleSetting("ExfilLoadDis", 200)*4)^2 then
                nZr_Exfil_ShowTimer(timer.TimeLeft("BO6_Exfil_Timer"), 2, nZr_Exfil_Enemies, ply)
            else
                nZr_Exfil_ShowTimer(timer.TimeLeft("BO6_Exfil_Timer"), 1, nZr_Exfil_Enemies, ply)
            end
        end
        if ply:Alive() then
            alivecount = alivecount + 1
        end
    end
    alivecount = #player.GetAllPlayingAndAlive()
    if alivecount > 0 then
        alive_count_delay = CurTime() + 2
    end

    if alivecount == 0 and alive_count_delay < CurTime() then
        alive_count_delay = CurTime() + 2
        nZr_Exfil_CreateCountdown(0)
    end

    if IsValid(nZr_Exfil_Heli) then
        if nZr_Exfil_Heli:GetCycle() > 0.2 and not nZr_Exfil_Heli.downing then
            nZr_Exfil_Heli:SetCycle(0.2)
        end
        if nZr_Exfil_Landing and nZr_Exfil_Heli:GetCycle() >= 0.2 and not nZr_Exfil_Heli.downing then
            nZr_Exfil_Heli.downing = true
            nZr_Exfil_Heli:ResetSequence("landing")
            nZr_Exfil_Heli:SetCycle(0)
            nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_GetIn")
            if !nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false) then
                timer.Remove("BO6_Exfil_Faster")
            end
            for i=1,150 do
                timer.Simple(0.05*i, function()
                    if !IsValid(nZr_Exfil_Heli) then return end

                    nZr_Exfil_Heli:SetPos(nZr_Exfil_Heli:GetPos()-Vector(0,0,2.6))
                    if i == 120 then
                        nZr_Exfil_Heli.loading = true
                    end
                end)
            end
        end
    end

    if IsValid(nZr_Exfil_Heli) and not nZr_Exfil_Landing and (nZr_Exfil_Enemies <= 0 or nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false)) then
        nZr_Exfil_Landing = true
    end
end)

hook.Add("OnGameBegin", "nZr_Exfil_LoadPos", nZr_UpdatePositions)

hook.Add("OnRoundStart", "nZr_ExfilRadio", function(rnd)
    local rad = ents.FindByClass("bo6_exfil_radio")[1]
    -- Check if exfil is available AND radio has power (if required)
    if nZr_Exfil_IsAvailableThisRound() and nZr_Exfil_RadioHasPower() and IsValid(rad) then
        nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_Available")
    end
end)

hook.Add("OnRoundPreparation", "nZr_ExfilRadio", function(rnd)
    local rad = ents.FindByClass("bo6_exfil_radio")[1]
    -- Only play unavailable message if radio exists and has power (or doesn't require it)
    -- This prevents the message from playing when power is off
    if nzSettings:GetSimpleSetting("ExfilEnabled", true) and 
       (nzRound:GetNumber() >= nzSettings:GetSimpleSetting("ExfilFirstRound", 11) and 
       (nzRound:GetNumber()-nzSettings:GetSimpleSetting("ExfilFirstRound", 11)) % nzSettings:GetSimpleSetting("ExfilEveryRound", 5) == 1) and 
       IsValid(rad) and nZr_Exfil_RadioHasPower() then
        nzDialog:PlayCustomDialog(nzSettings:GetSimpleSetting("ExfilPilotType", "raptor").."Exfil_Unavailable")
    end
end)