nz_cw_hud = nz_cw_hud or {}
nz_cw_hud.loaded = nz_cw_hud.loaded or false

if SERVER then
    nz_cw_hud.step = nz_cw_hud.step or ""
end

function nz_cw_hud:IsActive()
    local settings = nzMapping and nzMapping.Settings
    if not settings then
        return false
    end
    return settings.hudtype == "Black Ops Cold War"
end

local function registerHud()
    timer.Simple(0, function()
        nz_cw_hud.loaded = true
        if not nzRound or not nzDisplay then
            return
        end
        nzRound:AddHUDType("Black Ops Cold War", "bo6/hud/empty.png", {})
        nzDisplay.reworkedHUDs = nzDisplay.reworkedHUDs or {}
        nzDisplay.reworkedHUDs["Black Ops Cold War"] = true
        nzDisplay.modernHUDs = nzDisplay.modernHUDs or {}
        nzDisplay.modernHUDs["Black Ops Cold War"] = true
        nzDisplay.fonttypebyHUDs = nzDisplay.fonttypebyHUDs or {}
        nzDisplay.fonttypebyHUDs["Black Ops Cold War"] = nzDisplay.fonttypebyHUDs["Black Ops 3"] or "blackops2"
        nzDisplay.HUDnetstrings = nzDisplay.HUDnetstrings or {}
        if not nzDisplay.HUDnetstrings["Black Ops Cold War"] then
            nzDisplay.HUDnetstrings["Black Ops Cold War"] = nzDisplay.HUDnetstrings["Black Ops 3"] or "nz_points_notification_bo3"
        end
        nzDisplay.GumPosition = nzDisplay.GumPosition or {}
        if nzDisplay.GumPosition["Black Ops Cold War"] == nil then
            local template = nzDisplay.GumPosition["Black Ops 3"] or {x = 162, y = 340, icon_size = 76, ring_size = 39, width = 6}
            nzDisplay.GumPosition["Black Ops Cold War"] = {
                x = template.x,
                y = template.y,
                icon_size = template.icon_size,
                ring_size = template.ring_size,
                width = template.width,
                zcounter_x = template.zcounter_x,
                armor_x = template.armor_x,
                custom = template.custom
            }
        end
    end)
end

timer.Create("nz_cw_hud_register", 5, 0, function()
    if !istable(nzDisplay.reworkedHUDs) or istable(nzDisplay.reworkedHUDs) and nzDisplay.reworkedHUDs["Black Ops Cold War"] then return end
    registerHud()
end)