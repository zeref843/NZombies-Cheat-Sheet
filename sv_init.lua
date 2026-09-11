if CLIENT then
    return
end

util.AddNetworkString("nz_coldwar_next_step")
util.AddNetworkString("nz_coldwar_next_zone")

local function sendStep(target, value)
    net.Start("nz_coldwar_next_step")
    net.WriteString(value or "")
    if IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

local function sendZone(target, value)
    net.Start("nz_coldwar_next_zone")
    net.WriteString(value or "")
    if IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

hook.Add("nz_coldwar_set_step", "nz_cw_hud_sync_step_single", function(ply)
    if not IsValid(ply) then
        return
    end
    sendStep(ply, nz_cw_hud.step)
end)

hook.Add("nz_coldwar_next_step", "nz_cw_hud_update_step", function(value)
    nz_cw_hud.step = value or ""
    sendStep(nil, nz_cw_hud.step)
end)

hook.Add("nz_coldwar_next_zone", "nz_cw_hud_sync_zone", function(ply, zone)
    sendZone(ply, zone)
end)

local function resetPlayer(ply)
    if not IsValid(ply) then
        return
    end
    hook.Call("nz_coldwar_set_step", nil, ply, "")
    hook.Call("nz_coldwar_next_zone", nil, ply, "")
end

local function resetAll()
    hook.Call("nz_coldwar_next_step", nil, "")
    for _, ply in ipairs(player.GetAll()) do
        hook.Call("nz_coldwar_next_zone", nil, ply, "")
    end
end

hook.Add("PlayerInitialSpawn", "nz_cw_hud_initial_spawn", resetPlayer)

hook.Add("OnPlayerReady", "nz_cw_hud_player_ready", resetPlayer)

hook.Add("OnRoundPreparation", "nz_cw_hud_round_reset", function()
    if not nzRound then
        return
    end
    if nzRound:GetNumber() == 1 or nzRound:InState(5) then
        resetAll()
    end
end)
