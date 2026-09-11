local math = math
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local surface = surface
local draw = draw
local input = input
local file = file
local player = player
local team = team
local ScrW = ScrW
local ScrH = ScrH
local Color = Color
local color_white = color_white
local color_black = color_black
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local table_insert = table.insert
local table_remove = table.remove
local table_isempty = table.IsEmpty
local table_count = table.Count
local table_copy = table.Copy
local string_len = string.len
local string_sub = string.sub
local string_rep = string.rep

local color_white_100 = Color(255, 255, 255, 100)
local color_grey_100 = Color(100, 100, 100, 255)
local color_t7_sparks = Color(0, 180, 255, 255)
local color_t7_outline = Color(0, 220, 255, 10)
local color_gold = Color(255, 255, 100, 255)
local color_ammo_empty = Color(255, 80, 80, 255)

local roundCounterTravelTime = 0.8
local roundCounterReturnTime = 0.8
local roundCounterHoldTime = 4
local roundCounterCenterX = 0.5
local roundCounterCenterY = 0.2

local maxDisplayPlayers = 4
local screenWidth = ScrW()
local screenHeight = ScrH()

local materialsList = {
    "circle",
    "monkey",
    "grenade",
    "ammo",
    "deadicon",
    "deadicon2",
    "dhfill",
    "downicon",
    "hfill",
    "wrarity",
    "pap1",
    "pap2",
    "pap3"
}
local essenceMat = Material("bo6/other/essence.png", "unlitgeneric")

local hiddenHudElements = {
    CHudHealth = true,
    CHudBattery = true,
    CHudSecondaryAmmo = true,
    CHudAmmo = true,
    CHudVoiceStatus = true
}

local rarityColors = {
    Color(158, 33, 39, 220),
    Color(150, 182, 106, 220),
    Color(113, 186, 241, 220),
    Color(232, 110, 247, 220),
    Color(251, 167, 32, 220),
    Color(169, 150, 31, 200)
}

local illegalspecials = {
    specialgrenade = true,
    grenade = true,
    knife = true,
    display = true
}

local hudMaterials = {}
for _, id in ipairs(materialsList) do
    hudMaterials[id] = Material("nzcwhud/" .. id .. ".png", "unlitgeneric")
end

local stinkTexture = surface.GetTextureID("nz_moo/huds/t6/zm_hud_stink_ani_green")

local function resolveHudMaterial(icon, fallback)
    local materialValue

    if type(icon) == "IMaterial" then
        materialValue = icon
    elseif type(icon) == "string" then
        materialValue = hudMaterials[icon]
        if not materialValue then
            materialValue = Material(icon, "unlitgeneric smooth")
        end
    end

    if materialValue and materialValue.IsError and materialValue:IsError() then
        materialValue = nil
    end

    if not materialValue and fallback then
        if type(fallback) == "IMaterial" then
            materialValue = fallback
        elseif type(fallback) == "string" then
            materialValue = hudMaterials[fallback]
            if not materialValue then
                materialValue = Material(fallback, "unlitgeneric smooth")
            end
        end

        if materialValue and materialValue.IsError and materialValue:IsError() then
            materialValue = nil
        end
    end

    if not materialValue then
        materialValue = hudMaterials.deadicon2 or hudMaterials.circle
    end

    return materialValue
end

local function getPlayerColor(ply)
    if not IsValid(ply) then
        return color_white
    end

    if ply.GetPlayerColor then
        local vec = ply:GetPlayerColor()
        if vec then
            return Color(vec.x * 255, vec.y * 255, vec.z * 255)
        end
    end

    if ply.GetColor then
        local clr = ply:GetColor()
        if clr and (clr.r ~= 255 or clr.g ~= 255 or clr.b ~= 255) then
            return Color(clr.r, clr.g, clr.b, clr.a or 255)
        end
    end

    if team and team.GetColor then
        local teamColor = team.GetColor(ply:Team())
        if teamColor then
            return Color(teamColor.r, teamColor.g, teamColor.b, teamColor.a or 255)
        end
    end

    return color_white
end
local glowAlpha = 255
local glowDirection = -1

local legacyCleared = false

local function isActiveHud()
    return nz_cw_hud and nz_cw_hud.IsActive and nz_cw_hud:IsActive()
end

local function ratioX(value)
    return screenWidth * value
end

local function ratioY(value)
    return screenHeight * value
end

local function refreshResolution()
    screenWidth = ScrW()
    screenHeight = ScrH()

    if nzcwhud and nzcwhud.cFont then
        local scale = math.max(screenWidth, 1)
        nzcwhud.cFont(1920 / scale)
    end
end


local function perkIconPrefix()
    if not nzRound or not nzMapping then
        return "icon"
    end

    local iconType = nzRound:GetIconType(nzMapping.Settings and nzMapping.Settings.icontype)
    if iconType == "Rezzurrection" then return "icon" end
    if iconType == "Infinite Warfare" then return "icon_iw" end
    if iconType == "World at War/ Black Ops 1" then return "icon_waw" end
    if iconType == "Black Ops 2" then return "icon_bo2" end
    if iconType == "Black Ops 3" then return "icon_bo3" end
    if iconType == "Modern Warfare" then return "icon_mw" end
    if iconType == "Cold War" then return "icon_cw" end
    if iconType == "April Fools" then return "icon_dumb" end
    if iconType == "Laby's Secret Perk Icons" then return "icon_holo" end

    return "icon"
end

local function animateGlow()
    if glowAlpha >= 255 then
        glowDirection = -1
    elseif glowAlpha <= 20 then
        glowDirection = 1
    end

    glowAlpha = math.Clamp(glowAlpha + glowDirection, 20, 255)
end

local function shouldRenderHud()
    if not isActiveHud() then
        legacyCleared = false
        return nil
    end

    local owner = LocalPlayer()
    if not IsValid(owner) then
        return nil
    end

    if owner.ShouldDrawHUD and not owner:ShouldDrawHUD() then
        return nil
    end

    if owner.IsNZMenuOpen and owner:IsNZMenuOpen() then
        return nil
    end

    if nzRound:GetState() == ROUND_GO then
        return nil
    end

    return owner
end

local function getRenderPlayer(owner)
    if not IsValid(owner) then
        return nil
    end

    local target = owner:GetObserverTarget()
    if IsValid(target) and target:IsPlayer() then
        return target
    end

    return owner
end

local function resetLegacyHud()
    --hook.Remove("HUDPaint", "gunHUD")
    --hook.Remove("HUDPaint", "pointsNotifcationHUD")
    --hook.Remove("HUDPaint", "grenadeHUD")
    --hook.Remove("HUDPaint", "scoreHUD")
    --hook.Remove("HUDPaint", "roundHUD")
    --hook.Remove("OnRoundPreparation", "BeginRoundHUDChange")
    --hook.Remove("OnRoundStart", "EndRoundHUDChange")
    --hook.Remove("HUDPaint", "perksHUD")
end

local function ensureLegacyHudCleared()
    if legacyCleared then
        return
    end

    resetLegacyHud()
    legacyCleared = true
end

local function shouldHideHudElement(name)
    if not isActiveHud() then
        return
    end

    if hiddenHudElements[name] then
        return false
    end
end

local function drawArmorSegment(state)
    local segmentCount = math.max(state.segmentCount or 0, 0)
    local activeSegments = math.max(state.activeSegments or segmentCount, 0)
    local spacing = state.segmentSpacing or 0.0336

    if segmentCount <= 0 then
        return state
    end

    local offsetX = spacing * (state.segmentIndex - 1)
    local fill = 0

    if state.fillFractions then
        fill = math.Clamp(state.fillFractions[state.segmentIndex] or 0, 0, 1)
    elseif (state.maxArmor or 0) > 0 then
        local ratio = math.Clamp((state.armor or 0) / state.maxArmor, 0, 1)
        local left = (state.segmentIndex - 1) / segmentCount
        local right = state.segmentIndex / segmentCount
        if ratio >= right then
            fill = 1
        elseif ratio > left then
            fill = (ratio - left) / (right - left)
        end
    end

    if state.segmentIndex > activeSegments then
        fill = 0
    end

    fill = math.Clamp(fill, 0, 1)
    local width = state.originalWidth * fill

    surface.SetMaterial(hudMaterials.dhfill)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRect(ratioX(state.baseX + offsetX), ratioY(state.baseY), ratioX(state.originalWidth), state.height)

    if fill > 0 then
        surface.SetDrawColor(15, 114, 179)
        surface.DrawRect(ratioX(state.baseX + offsetX), ratioY(state.baseY), ratioX(width), state.height)
        surface.SetDrawColor(255, 255, 255)
    end

    state.segmentIndex = state.segmentIndex + 1
    return state
end

local function drawArmorBar(info)
    local totalSegments = math.max(info.segmentCount or 0, 0)
    if totalSegments <= 0 then
        return
    end

    info.segmentIndex = 1
    for _ = 1, totalSegments do
        info = drawArmorSegment(info)
    end
end

local function drawPlayerPanel(ply, colorValue, index, isLocal)
    local rowSpacing = 0.084
    local baseX = 0.025
    local baseY = 0.89 - rowSpacing * index
    local barWidth = 0.0021
    local barHeight = 0.075

    if not isLocal then
        barWidth = 0.0016
        baseX = 0.027
        barHeight = 0.065
    end

    local r = colorValue and colorValue.r or 255
    local g = colorValue and colorValue.g or 255
    local b = colorValue and colorValue.b or 255
    local a = colorValue and colorValue.a or 255
    surface.SetDrawColor(r, g, b, a)
    surface.DrawRect(ratioX(baseX), ratioY(baseY), ratioX(barWidth), ratioY(barHeight))

    local iconX = isLocal and 0.035 or 0.037
    local iconWidth = isLocal and 0.008 or 0.006
    local iconHeight = isLocal and 0.015 or 0.012
    local iconYOffset = isLocal and 0.055 or 0.053
    local iconY = baseY + iconYOffset

    surface.SetMaterial(hudMaterials.circle)
    surface.DrawTexturedRect(ratioX(iconX), ratioY(iconY), ratioX(iconWidth), ratioY(iconHeight))

    local textX = iconX + iconWidth + (isLocal and 0.002 or 0.001)
    local textY = iconY - iconHeight / 2 + (isLocal and 0.002 or 0.001)
    draw.DrawText(ply:Nick(), isLocal and "CWHUD_M" or "CWHUD_S", ratioX(textX), ratioY(textY), color_white, TEXT_ALIGN_LEFT)

    local healthBarX = iconX
    local healthBarY = iconY - iconHeight / 2 - 0.02
    local healthBarWidth = ratioX(0.1)
    local healthBarHeight = ratioY(iconHeight)

    surface.SetDrawColor(0, 0, 0)
    surface.SetMaterial(hudMaterials.hfill)
    surface.DrawTexturedRect(ratioX(healthBarX), ratioY(healthBarY), healthBarWidth, healthBarHeight)

    local maxHealth = ply.GetMaxHealth and ply:GetMaxHealth() or 100
    local health = math.max(math.min(ply:Health(), maxHealth), 0)

    local colorIntensity = 255
    if health < maxHealth / 2 then
        animateGlow()
        colorIntensity = glowAlpha
    else
        glowAlpha = 255
    end

    surface.SetDrawColor(255, colorIntensity, colorIntensity, glowAlpha)
    surface.SetMaterial(hudMaterials.hfill)
    local healthWidth = healthBarWidth * (maxHealth > 0 and health / maxHealth or 0)
    surface.DrawTexturedRect(ratioX(healthBarX), ratioY(healthBarY), healthWidth, healthBarHeight)

    local armor = ply.Armor and ply:Armor() or 0
    local maxArmor = ply.GetMaxArmor and ply:GetMaxArmor() or 0
    local armorType = ply.GetNWInt and ply:GetNWInt("ArmorType", 0) or 0
    local armorSystemEnabled = armorType > 0

    if not armorSystemEnabled and nzSettings and nzSettings.GetSimpleSetting then
        local armorSetting = nzSettings:GetSimpleSetting("BO6_Armor", false)
        if armorSetting ~= nil then
            armorSystemEnabled = armorSetting ~= false and armorSetting ~= 0
        end
    end

    local detectedArmorType = armorType
    if armorSystemEnabled then
        if detectedArmorType <= 0 then
            if nzSettings and nzSettings.GetSimpleSetting then
                local tier3 = nzSettings:GetSimpleSetting("BO6_Armor_Tier3HP", 450)
                local tier2 = nzSettings:GetSimpleSetting("BO6_Armor_Tier2HP", 300)
                local tier1 = nzSettings:GetSimpleSetting("BO6_Armor_Tier1HP", 150)
                if maxArmor >= tier3 then
                    detectedArmorType = 3
                elseif maxArmor >= tier2 then
                    detectedArmorType = 2
                elseif maxArmor >= tier1 then
                    detectedArmorType = 1
                end
            end

            if detectedArmorType <= 0 then
                if maxArmor > 300 then
                    detectedArmorType = 3
                elseif maxArmor > 150 then
                    detectedArmorType = 2
                elseif maxArmor > 0 then
                    detectedArmorType = 1
                end
            end
        end

        if detectedArmorType <= 0 then
            detectedArmorType = 1
        end
    end

    local armorSegments = armorSystemEnabled and math.Clamp(detectedArmorType, 1, 3) or 1
    if armorSegments < 1 then
        armorSegments = 1
    end

    local activeSegments = armorSystemEnabled and armorSegments or 1
    local displaySegments = math.max(activeSegments, 1)

    local totalArmorWidth = 0.1
    local gapSize = armorSystemEnabled and 0.0013 or 0
    local maxSegments = armorSystemEnabled and 3 or 1
    local segmentWidth = totalArmorWidth
    local segmentSpacing = totalArmorWidth

    if maxSegments > 0 then
        local maxGaps = math.max(maxSegments - 1, 0)
        local availableWidth = math.max(totalArmorWidth - gapSize * maxGaps, 0)
        local baseSegmentWidth = availableWidth / maxSegments

        if armorSystemEnabled then
            segmentWidth = baseSegmentWidth
            segmentSpacing = baseSegmentWidth + gapSize
        else
            segmentWidth = totalArmorWidth
            segmentSpacing = totalArmorWidth
        end
    end

    local tier1 = 150
    local tier2 = 300
    local tier3 = 450
    if nzSettings and nzSettings.GetSimpleSetting then
        tier1 = nzSettings:GetSimpleSetting("BO6_Armor_Tier1HP", tier1) or tier1
        tier2 = nzSettings:GetSimpleSetting("BO6_Armor_Tier2HP", tier2) or tier2
        tier3 = nzSettings:GetSimpleSetting("BO6_Armor_Tier3HP", tier3) or tier3
    end

    tier1 = math.max(tonumber(tier1) or 150, 1)
    tier2 = math.max(tonumber(tier2) or tier1, tier1)
    tier3 = math.max(tonumber(tier3) or tier2, tier2)

    local tiers = {tier1, tier2, tier3}
    local defaultSpan = tiers[1]
    local fillFractions = {}

    if armorSystemEnabled then
        local previousCap = 0
        for i = 1, displaySegments do
            local cap = tiers[i]
            if not cap then
                cap = previousCap + (defaultSpan or 150)
            end
            cap = math.max(cap, previousCap + 1)
            local span = cap - previousCap
            local segmentArmor = armor - previousCap
            local fill = 0
            if segmentArmor > 0 then
                fill = math.Clamp(segmentArmor / span, 0, 1)
            end
            if i > activeSegments then
                fill = 0
            end
            fillFractions[i] = fill
            previousCap = cap
        end
    else
        local fill = (maxArmor > 0) and math.Clamp(armor / maxArmor, 0, 1) or 0
        fillFractions[1] = fill
    end

    drawArmorBar({
        baseX = healthBarX,
        baseY = healthBarY - 0.007,
        originalWidth = segmentWidth,
        width = segmentWidth,
        height = ratioY(0.005),
        armor = armor,
        maxArmor = maxArmor,
        segmentCount = displaySegments,
        activeSegments = activeSegments,
        segmentSpacing = segmentSpacing,
        fillFractions = fillFractions
    })

    local cashY = healthBarY - (isLocal and 0.036 or 0.034)
    local cashPoints = nz and ply.GetPoints and ply:GetPoints() or 0
    local cashBaseX = ratioX(healthBarX)
    local cashBaseY = ratioY(cashY)
    local essenceSize = math.max(ratioY(0.03), 24)
    local essencePadding = math.max(ratioX(0.002), 1)

    surface.SetMaterial(essenceMat)
    surface.SetDrawColor(color_white)
    surface.DrawTexturedRect(cashBaseX, cashBaseY, essenceSize, essenceSize)

    draw.DrawText(tostring(cashPoints), isLocal and "CWHUD_L" or "CWHUD_M", cashBaseX + essenceSize + essencePadding, cashBaseY, color_white, TEXT_ALIGN_LEFT)

    if isLocal and ply:Alive() and ((nz and ply.GetNotDowned and ply:GetNotDowned()) or (not nz)) then
        local healthText = tostring(health)
        if health <= 99 then
            healthText = (health < 10 and "00" or "0") .. health
        end
        draw.DrawText(healthText, "CWHUD_XXL", ratioX(0.164), ratioY(0.907), Color(255, colorIntensity, colorIntensity, glowAlpha), TEXT_ALIGN_RIGHT)
    end

    if nz and ply.GetNotDowned and not ply:GetNotDowned() then
        surface.SetDrawColor(255, 0, 0)
        surface.SetMaterial(hudMaterials.downicon)
        surface.DrawTexturedRect(ratioX(0.135 - (isLocal and 0 or -0.0045)), ratioY(healthBarY - (0.026 - (isLocal and 0 or 0.005))), ratioX(0.04 - (isLocal and 0 or 0.008)), ratioY(0.07 - (isLocal and 0 or 0.015)))
    elseif not ply:Alive() then
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(hudMaterials.deadicon2)
        surface.DrawTexturedRect(ratioX(0.145), ratioY(healthBarY - (0.02 - (isLocal and 0 or 0.002))), ratioX(0.025 - (isLocal and 0 or 0.002)), ratioY(0.05 - (isLocal and 0 or 0.002)))
    end
end

local function drawPackIcon(baseX, baseY, shiftX, shiftY, weapon)
    if not nz or !weapon:HasNZModifier("pap") then
        return
    end

    local level = 1
    if level <= 0 then
        return
    end

    surface.SetDrawColor(255, 255, 255)
    local materialId = "pap" .. math.Clamp(level, 1, 3)
    surface.SetMaterial(hudMaterials[materialId])
    surface.DrawTexturedRect(ratioX(baseX + shiftX), ratioY(baseY + shiftY), ratioX(0.028), ratioY(0.05))
end

local function drawAmmoModIcon(baseX, baseY, shiftX, shiftY, weapon)
    local aat = weapon:GetNW2String("nzAATType", "")
    if not nz or aat == "" then
        return
    end

    surface.SetDrawColor(255, 255, 255)
    local materialId = nzAATs:Get(aat).icon
    surface.SetMaterial(materialId)
    surface.DrawTexturedRect(ratioX(baseX + shiftX), ratioY(baseY + shiftY), ratioX(0.022), ratioY(0.04))
end

local function getEquipmentIcon(ply, slot, fallback)
    if not nz then
        return fallback
    end

    if not IsValid(ply) then
        return fallback
    end

    local specialWeapons = ply.NZSpecialWeapons
    if specialWeapons then
        local weapon = specialWeapons[slot]
        if IsValid(weapon) then
            if slot == "grenade" and ply.HasPerk and ply:HasPerk("widowswine") and weapon.NZWidowIcon then
                return weapon.NZWidowIcon
            end

            if weapon.NZHudIcon then
                return weapon.NZHudIcon
            end
        end
    end

    return fallback
end

local function drawUtilitySlot(baseX, baseY, shiftX, shiftY, iconSource, iconOffsetX, iconOffsetY, iconWidth, iconHeight, ammo, key)
    local keyName = ""
    if key and key.GetInt then
        keyName = string.upper(input.GetKeyName(key:GetInt()))
    end

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(resolveHudMaterial(iconSource))
    surface.DrawTexturedRect(ratioX(baseX + shiftX + iconOffsetX), ratioY(baseY + shiftY + iconOffsetY), ratioX(iconWidth), ratioY(iconHeight))

    draw.DrawText(ammo, "CWHUD_L", ratioX(baseX - 0.0015 + shiftX), ratioY(baseY + 0.019 + shiftY), color_white, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawRect(ratioX(baseX - 0.002 + shiftX), ratioY(baseY + 0.047 + shiftY), ratioX(0.023), ratioY(0.002))

    draw.DrawText(keyName, "CWHUD_M", ratioX(baseX + 0.011 + shiftX), ratioY(baseY + 0.048 + shiftY), color_white, TEXT_ALIGN_CENTER)
end

local function drawWeaponInfo(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not weapon:IsWeapon() then
        return
    end

    local clipCount = weapon:Clip1() or 0
    local clipText = tostring(math.max(clipCount, 0))
    local clipInfinite = clipCount < 0
    if clipInfinite then
        clipText = "∞"
    end
    local maxClipCount = weapon:GetMaxClip1() or 0

    local reserveCount = 0
    local primaryType = weapon:GetPrimaryAmmoType()
    if primaryType and primaryType >= 0 then
        reserveCount = ply:GetAmmoCount(primaryType)
    end
    local reserveInfinite = reserveCount < 0
    local reserveText = reserveCount >= 0 and tostring(reserveCount) or "∞"

    local clipColor = (clipCount == 0 and not clipInfinite) and color_ammo_empty or color_white
    local reserveColor = (reserveCount == 0 and not reserveInfinite) and color_ammo_empty or color_white

    surface.SetDrawColor(rarityColors[1])
    if weapon:HasNZModifier("pap") and !weapon.NZWonderWeapon then
        surface.SetDrawColor(rarityColors[4])
    end

    if weapon.NZWonderWeapon then
        surface.SetDrawColor(rarityColors[6])
    end
    surface.SetMaterial(hudMaterials.wrarity)
    local barX = ratioX(0.73)
    local barY = ratioY(0.94)
    local barWidth = ratioX(0.17)
    local barHeight = ratioY(0.03)
    surface.DrawTexturedRect(barX, barY, barWidth, barHeight)

    draw.DrawText(string.upper(weapon:GetPrintName()), "CWHUD_M", barX + barWidth - ratioX(0.005), barY + barHeight * 0.1, color_white, TEXT_ALIGN_RIGHT)

    local clipFont = "CWHUD_XXXXL"
    surface.SetFont(clipFont)
    local clipWidth, clipHeight = surface.GetTextSize(clipText)

    local reserveFont = "CWHUD_XXL"
    surface.SetFont(reserveFont)
    local reserveWidth, reserveHeight = surface.GetTextSize(reserveText)

    local paddingX = math.max(ratioX(0.006), 6)
    local paddingY = math.max(ratioY(0.004), 4)
    local innerSpacing = math.max(ratioX(0.012), 12)

    local ammoBoxHeight = math.max(clipHeight, reserveHeight) + paddingY * 2
    local ammoBoxWidth = clipWidth + reserveWidth + paddingX * 2 + innerSpacing

    local ammoAnchorRight = ratioX(0.904)
    local ammoAnchorBottom = ratioY(0.946)
    local ammoBoxX = ammoAnchorRight - ammoBoxWidth
    local ammoBoxY = ammoAnchorBottom - ammoBoxHeight

    if maxClipCount > 0 and !ply:GetUsingSpecialWeapon() then
        surface.SetDrawColor(255, 255, 255, 225)
        surface.SetMaterial(hudMaterials.ammo)
        surface.DrawTexturedRect(ammoBoxX, ammoBoxY, ammoBoxWidth, ammoBoxHeight)

        local textCenterY = ammoBoxY + ammoBoxHeight * 0.5
        local clipDrawX = ammoBoxX + paddingX + clipWidth * 1.2
        surface.SetFont(clipFont)
        draw.SimpleText(clipText, clipFont, clipDrawX, textCenterY, clipColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        local reserveDrawX = clipDrawX + innerSpacing - clipWidth*0.4
        surface.SetFont(reserveFont)
        draw.SimpleText(reserveText, reserveFont, reserveDrawX, textCenterY - ammoBoxHeight * 0.025, reserveColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if nz then
        drawPackIcon(0.705, 0.89, 0.05, 0, weapon)
        drawAmmoModIcon(0.682, 0.895, 0.05, 0, weapon)

        local grenadeAmmo = 0
        local specialAmmo = 0
        local grenadeIcon = "grenade"
        local specialIcon = "monkey"

        if GetNZAmmoID then
            local grenadeId = GetNZAmmoID("grenade")
            if grenadeId then
                grenadeAmmo = ply:GetAmmoCount(grenadeId)
            end

            local specialId = GetNZAmmoID("specialgrenade")
            if specialId then
                specialAmmo = ply:GetAmmoCount(specialId)
            end
        end

        grenadeIcon = getEquipmentIcon(ply, "grenade", grenadeIcon)
        specialIcon = getEquipmentIcon(ply, "specialgrenade", specialIcon)

        drawUtilitySlot(0.86, 0.889, 0.05, 0, grenadeIcon, -0.002, 0, 0.025, 0.045, grenadeAmmo, GetConVar("nz_key_grenade"))
        drawUtilitySlot(0.9, 0.889, 0.05, 0, specialIcon, -0.002, 0, 0.025, 0.045, specialAmmo, GetConVar("nz_key_specialgrenade"))
    end
end

local function shouldDisplayPlayer(ply, reference)
    if not IsValid(ply) then
        return false
    end

    if ply == reference then
        return false
    end

    if not nz then
        return true
    end

    if not IsValid(reference) then
        return true
    end

    return ply:Team() == reference:Team()
end

local DrawColdWarRoundCounter

local function ColdWarScoreHud()
    local owner = shouldRenderHud()
    if not owner then
        return
    end

    ensureLegacyHudCleared()

    local renderPlayer = getRenderPlayer(owner)
    if not IsValid(renderPlayer) then
        return
    end

    drawPlayerPanel(renderPlayer, getPlayerColor(renderPlayer), 0, true)

    local slotsFilled = 1
    for _, ply in ipairs(player.GetAll()) do
        if shouldDisplayPlayer(ply, renderPlayer) then
            drawPlayerPanel(ply, getPlayerColor(ply), slotsFilled, false)
            slotsFilled = slotsFilled + 1

            if slotsFilled >= maxDisplayPlayers then
                break
            end
        end
    end
end

local function ColdWarGunHud()
    local owner = shouldRenderHud()
    if not owner then
        return
    end

    local ply = getRenderPlayer(owner)
    if not IsValid(ply) then
        return
    end

    drawWeaponInfo(ply)
end

local function ColdWarRoundHud()
    local owner = shouldRenderHud()
    if not owner then
        return
    end

    ensureLegacyHudCleared()

    local ply = getRenderPlayer(owner)
    if not IsValid(ply) then
        return
    end

    if DrawColdWarRoundCounter then
        DrawColdWarRoundCounter(ply)
    end
end

local hudmats = {}

local function Hudmat(mat)
    if hudmats[mat] then
        return hudmats[mat]
    end

    local asset = "materials/" .. mat
    if file.Exists(asset, "GAME") then
        hudmats[mat] = Material(asset, "unlitgeneric smooth")
        return hudmats[mat]
    end

    return hudMaterials.deadicon2 or hudMaterials.circle
end

local function cwimage(image, x, y, w, h, col, ang)
    surface.SetMaterial(Hudmat(image))
    surface.SetDrawColor(col or color_white)
    surface.DrawTexturedRectRotated(x, y, w, h, ang or 0)
end

local t7_hud_score = Material("nz_moo/huds/bo3/uie_score_feed_glow.png", "unlitgeneric smooth")
local zmhud_vulture_glow = Material("nz_moo/huds/t6/specialty_vulture_zombies_glow.png", "unlitgeneric smooth")
local zmhud_icon_missing = Material("nz_moo/icons/statmon_warning_scripterrors.png", "unlitgeneric smooth")

local roundcounters = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "i", "ii", "iii", "iiii", "iiiii"}
local roundassets = { ["burnt"] = {}, ["heat"] = {}, ["normal"] = {} }

for _, counter in ipairs(roundcounters) do
    for variant, store in pairs(roundassets) do
        store[tonumber(counter) or counter] = Material("round/_bo4/" .. variant .. "/" .. counter .. ".png", "unlitgeneric")
    end
end

roundassets["sparks"] = {}
for i = 0, 19 do
    roundassets["sparks"][i] = Material("round/sparks/" .. i .. ".png", "unlitgeneric")
end

local oldnum = 0
local usingtally = true
local tallysize = 150
local digitsize = {x = 84, y = 120}

local strokes = {
    [0] = {
        [1] = {
            {42, 10},
            {17, 28},
            {11, 65},
            {24, 96},
            {44, 108}
        },
        [2] = {
            {42, 10},
            {66, 29},
            {69, 64},
            {62, 93},
            {44, 108}
        }
    },
    [1] = {
        [1] = {
            {36, 9},
            {38, 51},
            {49, 107}
        }
    },
    [2] = {
        [1] = {
            {14, 45},
            {26, 24},
            {45, 11},
            {55, 27},
            {44, 57},
            {32, 100},
            {56, 89},
            {73, 70}
        }
    },
    [3] = {
        [1] = {
            {14, 36},
            {29, 17},
            {48, 10},
            {63, 22},
            {55, 44},
            {33, 62},
            {59, 67},
            {67, 84},
            {54, 99},
            {32, 106}
        }
    },
    [4] = {
        [1] = {
            {58, 18},
            {53, 49},
            {52, 113}
        },
        [2] = {
            {40, 8},
            {22, 63},
            {67, 40}
        }
    },
    [5] = {
        [1] = {
            {61, 7},
            {28, 18},
            {26, 55},
            {58, 41},
            {61, 76},
            {58, 102},
            {45, 112},
            {30, 102}
        }
    },
    [6] = {
        [1] = {
            {53, 9},
            {31, 35},
            {23, 65},
            {25, 97},
            {36, 109},
            {53, 92},
            {61, 51},
            {42, 61},
            {31, 74}
        }
    },
    [7] = {
        [1] = {
            {15, 37},
            {42, 24},
            {64, 8},
            {58, 56},
            {48, 111}
        }
    },
    [8] = {
        [1] = {
            {43, 7},
            {24, 29},
            {25, 55},
            {44, 58},
            {62, 70},
            {57, 95},
            {40, 114}
        },
        [2] = {
            {43, 7},
            {56, 23},
            {53, 45},
            {44, 58},
            {33, 77},
            {26, 102},
            {40, 114}
        }
    },
    [9] = {
        [1] = {
            {50, 44},
            {28, 63},
            {11, 56},
            {19, 34},
            {35, 18},
            {57, 18},
            {69, 18},
            {54, 62},
            {38, 114}
        }
    },
    ["i"] = {
        [1] = {
            {35, 44},
            {59, 210}
        }
    },
    ["ii"] = {
        [1] = {
            {83, 56},
            {104, 212}
        }
    },
    ["iii"] = {
        [1] = {
            {138, 62},
            {148, 205}
        }
    },
    ["iiii"] = {
        [1] = {
            {188, 62},
            {189, 195}
        }
    },
    ["iiiii"] = {
        [1] = {
            {24, 61},
            {210, 201}
        }
    },
    ["e"] = {
        [1] = {
            {62, 26},
            {43, 18},
            {22, 25},
            {17, 52},
            {34, 62},
            {48, 60},
            {28, 78},
            {30, 96},
            {49, 99},
            {64, 89}
        }
    },
    ["slash"] = {
        [1] = {
            {69, 25},
            {19, 90}
        }
    }
}

local tallycoordmult = tallysize / 256
local rounddata = {}
local sparkdata = {}
local roundbusy = false
local prev_round_special = false
local spacing = 70

local function AddStroke(number, entry, tally)
    local str = tally and string_rep("i", math.Clamp(tonumber(number), 1, 5)) or (isstring(number) and number or tonumber(number))
    table_insert(rounddata, entry, {
        image = str,
        state = CurTime() + 4,
        istally = tally,
        fade = false
    })
    table_insert(sparkdata, entry, {
        move = table_copy(strokes[str]),
        state = CurTime() + 1,
        istally = tally,
        offset = not tally and ((entry - 1) * spacing) or 0
    })
end

local wiping = false

local function WipeRound()
    if wiping then return end

    roundbusy = true
    wiping = true

    for _, v in pairs(rounddata) do
        v.state = CurTime() + 2
        v.fade = true
    end

    timer.Simple(1, function()
        table_insert(sparkdata, 999, {
            move = {[1] = {{12, 90}, {12 + (usingtally and tallysize or (spacing * table_count(rounddata))), 90}}},
            state = CurTime() + 1,
            overridesize = 2,
            istally = false,
            offset = 0
        })
    end)

    timer.Simple(2 - engine.TickInterval(), function()
        rounddata = {}
        sparkdata = {}
        wiping = false
        roundbusy = false
    end)
end

local function AddStrokeBulk(number)
    if not table_isempty(rounddata) then
        WipeRound()
        return
    end

    usingtally = false
    number = tostring(number)
    for i = 1, string_len(number) do
        local str = string_sub(number, i, i)
        if i == 1 then
            AddStroke(tonumber(str), i)
        else
            timer.Simple((i - 1) / 3, function()
                AddStroke(tonumber(str), i)
            end)
        end
    end
end

local function showRoundNumber(targetRound)
    targetRound = math.max(math.floor(targetRound or 0), 0)

    if targetRound < 6 then
        if not table_isempty(rounddata) and not usingtally then
            WipeRound()
            return false
        elseif table_count(rounddata) > targetRound then
            WipeRound()
            return false
        end

        roundbusy = true
        usingtally = true
        for i = 1, 5 do
            if targetRound >= i and not rounddata[i] then
                AddStroke(i, i, true)
            end
        end
        oldnum = targetRound
        return true
    else
        if not table_isempty(rounddata) then
            WipeRound()
            return false
        end

        roundbusy = true
        usingtally = false
        AddStrokeBulk(targetRound)
        oldnum = targetRound
        return true
    end
end

local round_posdata = {
    ["alpha"] = 255,
    ["white"] = 255,
    ["time"] = 0,
    ["kys_time"] = 0,
    ["intro"] = false,
}

local roundAnimation = {
    phase = "idle",
    startTime = 0,
    endTime = 0,
    fromX = 0,
    fromY = 0,
    toX = 0,
    toY = 0,
    pendingRound = nil,
    appliedPending = false,
    alignProgress = 0
}

local function getRoundTarget()
    local w = ScrW()
    local pscale = (w / 1920 + 1) / 2
    return w - (32 * pscale), 24 * pscale
end

local function getRoundCenterPosition()
    return ScrW() * roundCounterCenterX, ScrH() * roundCounterCenterY
end

local function ResetRoundPos()
    local targetX, targetY = getRoundTarget()
    round_posdata[1] = targetX
    round_posdata[2] = targetY
    roundAnimation.phase = "idle"
    roundAnimation.startTime = 0
    roundAnimation.endTime = 0
    roundAnimation.fromX = targetX
    roundAnimation.fromY = targetY
    roundAnimation.toX = targetX
    roundAnimation.toY = targetY
    roundAnimation.pendingRound = nil
    roundAnimation.appliedPending = false
    roundAnimation.alignProgress = 0
end

ResetRoundPos()

local function beginRoundEndAnimation(targetRound)
    targetRound = math.max(math.floor(targetRound or 0), oldnum + 1)

    local baseX, baseY = getRoundTarget()
    local centerX, centerY = getRoundCenterPosition()

    round_posdata[1] = baseX
    round_posdata[2] = baseY

    roundAnimation.phase = "moving"
    roundAnimation.startTime = CurTime()
    roundAnimation.endTime = roundAnimation.startTime + roundCounterTravelTime
    roundAnimation.fromX = baseX
    roundAnimation.fromY = baseY
    roundAnimation.toX = centerX
    roundAnimation.toY = centerY
    roundAnimation.pendingRound = targetRound
    roundAnimation.appliedPending = false
    roundAnimation.alignProgress = 0
end

local function updateRoundAnimation(baseX, baseY)
    local now = CurTime()
    local phase = roundAnimation.phase
    local centerX, centerY = getRoundCenterPosition()

    if phase == "idle" then
        round_posdata[1] = baseX
        round_posdata[2] = baseY
        roundAnimation.alignProgress = 0
        return baseX, baseY
    end

    if phase == "moving" then
        local duration = math.max(roundCounterTravelTime, 0.0001)
        local progress = math.Clamp((now - roundAnimation.startTime) / duration, 0, 1)
        local fromX = roundAnimation.fromX or baseX
        local fromY = roundAnimation.fromY or baseY
        local toX = centerX
        local toY = centerY
        roundAnimation.toX = toX
        roundAnimation.toY = toY
        local x = Lerp(progress, fromX, toX)
        local y = Lerp(progress, fromY, toY)
        round_posdata[1] = x
        round_posdata[2] = y
        roundAnimation.alignProgress = progress

        if progress >= 1 then
            roundAnimation.phase = "holding"
            roundAnimation.startTime = now
            roundAnimation.endTime = now + roundCounterHoldTime
            roundAnimation.fromX = x
            roundAnimation.fromY = y
            roundAnimation.alignProgress = 1
        end

        return x, y
    elseif phase == "holding" then
        round_posdata[1] = centerX
        round_posdata[2] = centerY
        roundAnimation.alignProgress = 1

        if not roundAnimation.appliedPending and roundAnimation.pendingRound then
            if showRoundNumber(roundAnimation.pendingRound) then
                roundAnimation.appliedPending = true
                roundAnimation.pendingRound = nil
                roundAnimation.endTime = now + roundCounterHoldTime
            end
        end

        if roundAnimation.appliedPending and now >= roundAnimation.endTime then
            roundAnimation.phase = "returning"
            roundAnimation.startTime = now
            roundAnimation.endTime = now + roundCounterReturnTime
            roundAnimation.fromX = centerX
            roundAnimation.fromY = centerY
        end

        return centerX, centerY
    elseif phase == "returning" then
        local duration = math.max(roundCounterReturnTime, 0.0001)
        local progress = math.Clamp((now - roundAnimation.startTime) / duration, 0, 1)
        local fromX = roundAnimation.fromX or centerX
        local fromY = roundAnimation.fromY or centerY
        local toX = baseX
        local toY = baseY
        roundAnimation.toX = toX
        roundAnimation.toY = toY
        local x = Lerp(progress, fromX, toX)
        local y = Lerp(progress, fromY, toY)
        round_posdata[1] = x
        round_posdata[2] = y
        roundAnimation.alignProgress = 1 - progress

        if progress >= 1 then
            roundAnimation.phase = "idle"
            roundAnimation.pendingRound = nil
            roundAnimation.appliedPending = false
            roundAnimation.fromX = toX
            roundAnimation.fromY = toY
            round_posdata[1] = toX
            round_posdata[2] = toY
            roundAnimation.alignProgress = 0
        end

        return x, y
    end

    roundAnimation.phase = "idle"
    roundAnimation.pendingRound = nil
    roundAnimation.appliedPending = false
    round_posdata[1] = baseX
    round_posdata[2] = baseY
    roundAnimation.alignProgress = 0
    return baseX, baseY
end

local function GameBeginRound()
    round_posdata["intro"] = false
    round_posdata["time"] = 0
    round_posdata["alpha"] = 255
    round_posdata["white"] = 255
    round_posdata["kys_time"] = 0
    nzDisplay.HUDIntroDuration = CurTime()

    hook.Remove("HUDPaint", "nz_cw_round_intro")
    ResetRoundPos()
end

DrawColdWarRoundCounter = function(ply)
    local w, h = ScrW(), ScrH()

    local targetX, targetY = getRoundTarget()
    updateRoundAnimation(targetX, targetY)

    local roundBlocked = nzRound:InState(ROUND_WAITING) or nzRound:InState(ROUND_PREP) or nzRound:InState(ROUND_CREATE)
    local roundShouldWipe = nzRound:InState(ROUND_WAITING) or nzRound:InState(ROUND_CREATE)

    if (not roundbusy or table_isempty(rounddata)) and not roundBlocked then
        local currentRound = nzRound and nzRound:GetNumber() or 0

        if roundAnimation.phase == "idle" then
            if roundAnimation.pendingRound ~= nil then
                if showRoundNumber(roundAnimation.pendingRound) then
                    roundAnimation.pendingRound = nil
                    roundAnimation.appliedPending = false
                end
            elseif currentRound > oldnum then
                beginRoundEndAnimation(currentRound)
            elseif currentRound ~= oldnum then
                showRoundNumber(currentRound)
            end
        elseif roundAnimation.pendingRound == nil and currentRound > oldnum then
            roundAnimation.pendingRound = currentRound
        end
    elseif not table_isempty(rounddata) and roundShouldWipe then
        WipeRound()
    end

    local compassCvar = GetConVar("nz_hud_show_compass")
    local showCompass = compassCvar and compassCvar:GetBool()
    local anchorX = round_posdata[1]
    local anchorY = round_posdata[2]
    if showCompass then
        anchorY = anchorY + 10
    end

    local digits = 0
    for _, entry in ipairs(rounddata) do
        if not entry.istally then
            digits = digits + 1
        end
    end

    local totalWidth = 0
    for index, data in ipairs(rounddata) do
        local width = data.istally and tallysize or digitsize.x
        local offset = data.istally and 0 or ((digits - index) * spacing)
        if offset < 0 then
            offset = 0
        end
        local extent = offset + width
        if extent > totalWidth then
            totalWidth = extent
        end
    end

    if totalWidth <= 0 then
        totalWidth = digitsize.x
    end

    local alignProgress = roundAnimation.alignProgress or 0
    local leftEdge = anchorX - totalWidth + totalWidth * 0.5 * alignProgress

    for index, data in ipairs(rounddata) do
        local timer = data.state - CurTime()
        if alignProgress > 0 then
            timer = 0
        elseif not data.fade then
            timer = 0
        end
        local tally = data.istally
        local width = tally and tallysize or digitsize.x
        local height = tally and tallysize or digitsize.y
        local drawOffset = tally and 0 or ((digits - index) * spacing)
        if drawOffset < 0 then
            drawOffset = 0
        end
        local offsetFromLeft = totalWidth - (drawOffset + width)
        if offsetFromLeft < 0 then
            offsetFromLeft = 0
        end
        local drawX = leftEdge + offsetFromLeft
        local drawY = anchorY + (tally and 5 or 0) + (data.offsetheight or 0)

        if timer > 3 then
            surface.SetMaterial(roundassets["burnt"][data.image])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(drawX, drawY, width, height)
        elseif timer > 2 then
            surface.SetMaterial(roundassets["burnt"][data.image])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(drawX, drawY, width, height)
            surface.SetMaterial(roundassets["heat"][data.image])
            surface.SetDrawColor(Color(255, 255, 99, 255 * (3 - timer)))
            surface.DrawTexturedRect(drawX, drawY, width, height)
        elseif timer > 1 and not data.fade then
            surface.SetMaterial(roundassets["normal"][data.image])
            surface.SetDrawColor(Color(255, 255, 255, 255 * (2 - timer)))
            surface.DrawTexturedRect(drawX, drawY, width, height)
            surface.SetMaterial(roundassets["burnt"][data.image])
            surface.SetDrawColor(Color(255, 255, 255, 1024 * (timer - 1)))
            surface.DrawTexturedRect(drawX, drawY, width, height)
            surface.SetMaterial(roundassets["heat"][data.image])
            surface.SetDrawColor(Color(255, 80 + (175 * (timer - 1)), 99 * (timer - 1)))
            surface.DrawTexturedRect(drawX, drawY, width, height)
        elseif timer > 0 and not data.fade then
            surface.SetMaterial(roundassets["normal"][data.image])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(drawX, drawY, width, height)
            surface.SetMaterial(roundassets["heat"][data.image])
            surface.SetDrawColor(Color(255, 80, 0, 255 * timer))
            surface.DrawTexturedRect(drawX, drawY, width, height)
        elseif data.fade then
            local fadeA = ColorAlpha(color_white, 255 * timer)
            local fadeB = ColorAlpha(color_white, 255 * (1 - timer))
            if timer > 1 then
                surface.SetMaterial(roundassets["normal"][data.image])
                surface.SetDrawColor(fadeA)
                surface.DrawTexturedRect(drawX, drawY, width, height)
                surface.SetMaterial(roundassets["burnt"][data.image])
                surface.SetDrawColor(fadeB)
                surface.DrawTexturedRect(drawX, drawY, width, height)
            else
                surface.SetMaterial(roundassets["burnt"][data.image])
                surface.SetDrawColor(fadeA)
                surface.DrawTexturedRect(drawX, drawY, width, height)
            end
        else
            surface.SetMaterial(roundassets["normal"][data.image])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(drawX, drawY, width, height)
        end
    end

    local activeSparks = false
    if not table_isempty(sparkdata) then
        for _, entry in pairs(sparkdata) do
            if CurTime() < entry.state then
                activeSparks = true
                local tally = entry.istally
                local timer = 1 - (entry.state - CurTime())
                local sparkColor = ColorAlpha(color_white, 512 * (1 - timer))
                for _, path in pairs(entry.move) do
                    local movement = (table_count(path) * timer) + 0.6
                    local mod1 = math.floor(movement)
                    local mod2 = math.ceil(movement)
                    local mod3 = mod1 == mod2 and 1 or (movement % 1)
                    local width = tally and tallysize or digitsize.x
                    local entryIndex = math.floor((entry.offset or 0) / spacing) + 1
                    local drawOffset = tally and 0 or ((digits - entryIndex) * spacing)
                    if drawOffset < 0 then
                        drawOffset = 0
                    end
                    local offsetFromLeft = totalWidth - (drawOffset + width)
                    if offsetFromLeft < 0 then
                        offsetFromLeft = 0
                    end
                    local baseX = leftEdge + offsetFromLeft
                    local baseY = anchorY + (tally and 5 or 0) + (entry.offsetheight or 0)
                    local size = entry.overridesize or 1
                    local frame = math.ceil(CurTime() * 30) % 20

                    local function emit(point)
                        local x = point[1] * (tally and tallycoordmult or 1)
                        local y = point[2] * (tally and tallycoordmult or 1)
                        cwimage(
                            "rf/round/sparks/" .. frame .. ".png",
                            baseX + x + (33 * size),
                            baseY + y - (84 * size),
                            168 * size,
                            252 * size,
                            sparkColor
                        )
                    end

                    if path[mod1] and path[mod2] then
                        local x1 = path[mod1][1] * (tally and tallycoordmult or 1)
                        local y1 = path[mod1][2] * (tally and tallycoordmult or 1)
                        local x2 = path[mod2][1] * (tally and tallycoordmult or 1)
                        local y2 = path[mod2][2] * (tally and tallycoordmult or 1)
                        cwimage(
                            "rf/round/sparks/" .. frame .. ".png",
                            baseX + ((x1 * (1 - mod3)) + (x2 * mod3)) + (33 * size),
                            baseY + ((y1 * (1 - mod3)) + (y2 * mod3)) - (84 * size),
                            168 * size,
                            252 * size,
                            sparkColor
                        )
                    elseif path[mod1] then
                        emit(path[mod1])
                    end
                end
            end
        end
    end

    if not activeSparks then
        sparkdata = {}
    end
end

local function StartChangeRound()
    if not isActiveHud() then return end

    local projectedRound = nzRound and nzRound:GetNumber() or 0
    if projectedRound <= oldnum then
        projectedRound = oldnum + 1
    end
    beginRoundEndAnimation(projectedRound)

    if not nzDisplay.HasPlayedRoundIntro then
        nzDisplay.HasPlayedRoundIntro = true
        timer.Simple((nzMapping.Settings.firstroundwaittime or 1) - engine.TickInterval(), function()
            GameBeginRound()
        end)
    end
end

local function EndChangeRound()
    if not isActiveHud() then return end
    roundbusy = false
end

local function ResetRoundState()
    ResetRoundPos()

    timer.Create("nz_cw_round_reseter", 0, 0, function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove("nz_cw_round_reseter")
            WipeRound()
        end
    end)

    nzDisplay.HasPlayedRoundIntro = nil
end

local perkcount = 0
local perkflashtime = 0
local stinkfade = 0

local function ColdWarPerkHud()
    local owner = shouldRenderHud()
    if not owner then
        return
    end

    local ply = getRenderPlayer(owner)
    if not IsValid(ply) then
        return
    end

    if ply:IsNZMenuOpen() then
        return
    end

    ensureLegacyHudCleared()

    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and (illegalspecials[weapon.NZSpecialCategory] or weapon:GetClass() == "nz_multi_tool") then
        return
    end

    local perks = ply:GetPerks()
    if not perks then
        perks = {}
    end

    local downtimeCvar = GetConVar("nz_downtime")
    local bleedtime = ply.GetBleedoutTime and ply:GetBleedoutTime() or (downtimeCvar and downtimeCvar:GetFloat() or 45)
    local reviveData = nzRevive and nzRevive.Players and nzRevive.Players[ply:EntIndex()] or nil
    local bleedoutStyleCvar = GetConVar("nz_hud_bleedout_style")
    if bleedoutStyleCvar and bleedoutStyleCvar:GetInt() == 0 and reviveData then
        local keep = reviveData.PerksToKeep
        if keep and next(keep) ~= nil then
            perks = {}
            for index, info in ipairs(keep) do
                perks[index] = info.id
            end
        end
    end

    local maxperks = ply:GetMaxPerks() or 0
    local pscale = (ScrW() / 1920 + 1) / 2
    local w = ScrW() / 1920 + (206 * pscale)
    local h = ScrH()
    local size = 50

    local centrist = true
    local height = centrist and 82 or 100

    if not centrist then
        local showHealthCvar = GetConVar("nz_hud_show_health")
        local showCompassCvar = GetConVar("nz_hud_show_compass")
        local showCounterCvar = GetConVar("nz_hud_show_alive_counter")
        local showHealth = showHealthCvar and showHealthCvar:GetBool()
        local showCompass = showCompassCvar and showCompassCvar:GetBool()
        local showCounter = showCounterCvar and showCounterCvar:GetBool()

        if showHealth then
            w = w + (64 * pscale)
            if showCompass and showCounter then
                w = w + (6 * pscale)
            end
        elseif showCompass and showCounter then
            w = w + (70 * pscale)
        end
    end

    local num = 0
    local row = 0
    local num_b = 0
    local row_b = 0
    local rowmodCvar = GetConVar("nz_hud_perk_row_modulo")
    local rowmod = math.max((rowmodCvar and rowmodCvar:GetInt()) or 1, 1)
    local columns = math.min(maxperks, rowmod)

    local perkFrameCvar = GetConVar("nz_hud_show_perk_frames")
    local perk_borders = (perkFrameCvar and perkFrameCvar:GetInt()) or 0
    if perk_borders > 0 and maxperks > 0 then
        local modded = false
        surface.SetMaterial(GetPerkFrameMaterial())
        surface.SetDrawColor(color_white_100)
        for i = 1, maxperks do
            local baseX = centrist and (ScrW() / 2) + (num_b * (size + 6) * pscale) - (columns / 2) * (size + 6) * pscale or (w + num_b * (size + 6) * pscale)
            if i == 4 and nzMapping.Settings.modifierslot and perk_borders < 2 then
                surface.SetDrawColor(color_gold)
                modded = true
            end
            if i > #perks then
                surface.DrawTexturedRect(baseX, h - height * pscale - (64 * row_b) * pscale, 54 * pscale, 54 * pscale)
            end
            if modded then
                modded = false
                surface.SetDrawColor(color_white_100)
            end
            num_b = num_b + 1
            if num_b % rowmod == 0 then
                row_b = row_b + 1
                num_b = 0
            end
        end
    end

    if perkcount < #perks and perkflashtime < CurTime() then
        perkflashtime = CurTime() + 1
        perkcount = math.Approach(perkcount, #perks, 1)
    end

    if not ply:Alive() and perkcount ~= 0 then
        perkcount = 0
        perkflashtime = 0
    end

    if perkflashtime > CurTime() then
        local alpha = 1 - math.Clamp((perkflashtime - CurTime()) / 1, 0, 1)
        if alpha > 0.5 then
            alpha = math.Clamp((perkflashtime - CurTime()) / 1, 0, 1)
        end
        local flashRow = perkcount > rowmod and math.floor(perkcount / rowmod) or 0
        local flashCount = perkcount > rowmod and perkcount % rowmod or perkcount
        local baseX = centrist and (ScrW() / 2) + ((flashCount - 1) * (size + 6) * pscale) - (columns / 2) * (size + 6) * pscale or (w + ((flashCount - 1) * (size + 6)) * pscale)
        cwimage("rf/round/sparks/" .. (math.ceil(CurTime() * 30) % 20) .. ".png", baseX + 46 * pscale, h - (height + 54) * pscale - 64 * flashRow, 168 * pscale * 0.8, 252 * pscale * 0.8, ColorAlpha(color_t7_sparks, 255 * alpha))
        surface.SetMaterial(t7_hud_score)
        surface.SetDrawColor(ColorAlpha(color_t7_outline, 255 * alpha))
        surface.DrawTexturedRect(baseX - 40 * pscale, h - (height + 48) * pscale - 64 * flashRow, 128 * pscale, 128 * pscale)
    end

    for index, perk in ipairs(perks) do
        local icon = GetPerkIconMaterial(perk)
        if not icon or (icon.IsError and icon:IsError()) then
            icon = zmhud_icon_missing
        end

        local alpha = 1
        if perkcount > 0 and perks[perkcount] == perk and perkflashtime > CurTime() then
            alpha = 1 - math.Clamp((perkflashtime - CurTime()) / 1, 0, 1)
        end

        local offsetPulse = 0
        local pulse = 1
        local perkcolor = color_white
        if reviveData and reviveData.DownTime and reviveData.PerksToKeep and reviveData.PerksToKeep[index] then
            local pdata = reviveData.PerksToKeep[index]
            if pdata.lost then
                perkcolor = color_grey_100
            elseif not reviveData.ReviveTime then
                local timeLeft = reviveData.DownTime + bleedtime - CurTime()
                if (timeLeft / bleedtime) < (pdata.prc + (1 / (#reviveData.PerksToKeep + 1))) then
                    local wave = math.Clamp(math.sin(CurTime() * 6), 0, 1)
                    pulse = math.Remap(wave, 0, 1, 1, 1.2)
                    offsetPulse = 5.4 * math.Remap(wave, 0, 1, 0, 1)
                end
            end
        end

        local baseX = centrist and (ScrW() / 2 + (num * (size + 6) * pscale) - (columns / 2) * (size + 6) * pscale) or (w + num * (size + 6) * pscale - offsetPulse * pscale)

        surface.SetMaterial(icon)
        surface.SetDrawColor(alpha < 1 and ColorAlpha(perkcolor, 800 * alpha) or perkcolor)
        surface.DrawTexturedRect(baseX, h - (height + offsetPulse) * pscale - (64 * row) * pscale, 54 * pulse * pscale, 54 * pulse * pscale)

        if ply:HasUpgrade(perk) then
            surface.SetDrawColor(GetPerkColor(perk))
            surface.SetMaterial(GetPerkFrameMaterial())
            surface.DrawTexturedRect(baseX, h - (height + offsetPulse) * pscale - (64 * row) * pscale, 54 * pulse * pscale, 54 * pulse * pscale)
        end

        if perk == "vulture" then
            if ply.HasVultureStink and ply:HasVultureStink() then
                stinkfade = 1
            end
            if stinkfade > 0 then
                surface.SetDrawColor(ColorAlpha(color_white, 255 * stinkfade))
                surface.SetMaterial(zmhud_vulture_glow)
                surface.DrawTexturedRect(baseX - 24 * pscale, h - height * pscale - (64 * row) * pscale - 24 * pscale, 102 * pscale, 102 * pscale)
                if stinkTexture and stinkTexture ~= 0 then
                    surface.SetTexture(stinkTexture)
                    surface.DrawTexturedRect(baseX, h - height * pscale - (64 * row) * pscale - 62 * pscale, 64 * pscale, 64 * pscale)
                end
                stinkfade = math.max(stinkfade - FrameTime() * 3, 0)
            end
        end

        num = num + 1
        if num % rowmod == 0 then
            row = row + 1
            num = 0
        end
    end
end

refreshResolution()

hook.Add("OnScreenSizeChanged", "nz_cw_hud_resolution", refreshResolution)

hook.Add("HUDShouldDraw", "nz_cw_hud_should_draw", shouldHideHudElement)

hook.Add("nzShouldDrawScoreHUD", "nz_cw_hide_default_score", function()
    if isActiveHud() then
        return true
    end
end)

hook.Add("nzShouldDrawRoundHUD", "nz_cw_hide_default_round", function()
    if isActiveHud() then
        return true
    end
end)

hook.Add("nzShouldDrawInventoryHUD", "nz_cw_hide_default_inventory", function()
    if isActiveHud() then
        return true
    end
end)

hook.Add("nzShouldDrawGunHUD", "nz_cw_hide_default_gun", function()
    if isActiveHud() then
        return true
    end
end)

hook.Add("nzShouldDrawPerksHUD", "nz_cw_hide_default_perks", function()
    if isActiveHud() then
        return true
    end
end)

hook.Add("HUDPaint", "nz_cw_hud_score", ColdWarScoreHud)
hook.Add("HUDPaint", "nz_cw_hud_gun", ColdWarGunHud)
hook.Add("HUDPaint", "nz_cw_hud_round", ColdWarRoundHud)
hook.Add("HUDPaint", "nz_cw_hud_perks", ColdWarPerkHud)

hook.Add("OnRoundPreparation", "nz_cw_hud_reset_default", function()
    resetLegacyHud()
    legacyCleared = false
end)

hook.Add("OnRoundPreparation", "nz_cw_round_begin_change", StartChangeRound)
hook.Add("OnRoundStart", "nz_cw_round_start_change", EndChangeRound)
hook.Add("OnRoundEnd", "nz_cw_round_end_reset", ResetRoundState)