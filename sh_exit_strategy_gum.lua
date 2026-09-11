if SERVER then
    AddCSLuaFile()
end

local GUM_ID = "exit_strategy"
local REDUCTION_MULTIPLIER = 0.8

local gumRegistered = false
local exitStrategyPending = false
local exitStrategyActive = false

local function tryRegisterGum()
    if gumRegistered then return true end
    if not nzGum or not nzGum.RegisterGum or not nzGum.Types or not nzGum.RareTypes then return false end
    if nzGum.GetData and nzGum:GetData(GUM_ID) then
        gumRegistered = true
        return true
    end

    nzGum:RegisterGum(GUM_ID, {
        name = "Exit Strategy",
        desc = "Activate exfil vote immediately and reduce zombie spawns during exfil.",
        icon = Material("gums/exit_strategy.png", "smooth unlitgeneric"),
        type = nzGum.Types.USABLE,
        rare = nzGum.RareTypes.MEGA,
        uses = 1,
        canuse = function(ply)
            if exitStrategyPending or exitStrategyActive then return false end

            if SERVER then
                if not nzVotes or not nzVotes.StartVote then return false end
                if timer.Exists("VoteTimeout") then return false end
                if not nzSettings:GetSimpleSetting("ExfilEnabled", true) then return false end
                if isvector(nZr_Exfil_Position) then return false end
                if nZr_Exfil_RadioActive == false then return false end
                if nzRound:GetState() ~= ROUND_PROG then return false end

                local first = nzSettings:GetSimpleSetting("ExfilFirstRound", 11)
                local every = math.max(1, nzSettings:GetSimpleSetting("ExfilEveryRound", 5))
                local roundNumber = nzRound:GetNumber()
                if roundNumber < first then return false end
                if ((roundNumber - first) % every) ~= 0 then return false end

                if istable(nZr_Exfil_Map_Positions) and #nZr_Exfil_Map_Positions <= 0 then return false end
            end

            return true
        end,
        onuse = function(ply)
            if CLIENT then return end
            if not IsValid(ply) then return end
            if not nzVotes or not nzVotes.StartVote then return end
            if timer.Exists("VoteTimeout") then return end
            if not nzSettings:GetSimpleSetting("ExfilEnabled", true) then return end

            exitStrategyPending = true
            exitStrategyActive = false

            nzVotes:StartVote("Call an immediate exfil for your squad.", 0.75, function()
                exitStrategyPending = false
                exitStrategyActive = true
                if not nZr_Exfil_StartRandom then
                    exitStrategyActive = false
                    return
                end
                nZr_Exfil_StartRandom()
            end)

            timer.Simple(0, function()
                if exitStrategyPending and not timer.Exists("VoteTimeout") and not exitStrategyActive then
                    exitStrategyPending = false
                end
            end)
        end,
    })

    gumRegistered = true
    return true
end

if not tryRegisterGum() then
    hook.Add("Think", "ExitStrategyRegisterGum", function()
        if tryRegisterGum() then
            hook.Remove("Think", "ExitStrategyRegisterGum")
        end
    end)
end

if SERVER then
    hook.Add("Think", "ExitStrategyPendingMonitor", function()
        if exitStrategyPending and not timer.Exists("VoteTimeout") and not exitStrategyActive then
            exitStrategyPending = false
        end
    end)

    hook.Add("OnExfilStart", "ExitStrategyScaleZombies", function()
        if not exitStrategyActive then return end
        timer.Simple(0, function()
            if not exitStrategyActive then return end
            if nzSettings:GetSimpleSetting("ExfilWithoutEnemies", false) then
                exitStrategyActive = false
                return
            end

            local currentMax = nzRound and nzRound:GetZombiesMax() or 0
            if currentMax <= 0 then
                exitStrategyActive = false
                return
            end

            local desired = math.max(1, math.ceil(currentMax * REDUCTION_MULTIPLIER))
            if desired >= currentMax then
                exitStrategyActive = false
                return
            end

            nzRound:SetZombiesMax(desired)
            if nzRound.SetZombiesToSpawn then
                local toSpawn = math.min(nzRound:GetZombiesToSpawn(), desired)
                nzRound:SetZombiesToSpawn(toSpawn)
            end
            if nzRound.SetZombiesKilled then
                local killed = math.min(nzRound:GetZombiesKilled(), desired)
                nzRound:SetZombiesKilled(killed)
            end
            nzRound.NumberZombies = desired

            if nZr_Exfil_Enemies then
                nZr_Exfil_Enemies = math.min(nZr_Exfil_Enemies, desired)
            end

            if timer.Exists("BO6_Exfil_Timer") and nZr_Exfil_ShowTimer then
                nZr_Exfil_ShowTimer(math.ceil(timer.TimeLeft("BO6_Exfil_Timer")), 1, nZr_Exfil_Enemies or desired)
            end

            exitStrategyActive = false
        end)
    end)

    local function ExitStrategyCleanup()
        exitStrategyPending = false
        exitStrategyActive = false
    end

    hook.Add("OnExfilScene", "ExitStrategyCleanup", ExitStrategyCleanup)
    hook.Add("OnRoundEnd", "ExitStrategyCleanup", ExitStrategyCleanup)
end
