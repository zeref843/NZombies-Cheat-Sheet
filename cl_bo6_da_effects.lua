local bloodAlwaysMat = Material("bo6/da/screen.png", "noclamp smooth")
local bloodShotMats = {}
for i=1,24 do
    bloodShotMats[#bloodShotMats+1] = Material("bo6/da/shot"..i..".png", "noclamp smooth")
end
local bloodSplattersMats = {}
for i=1,50 do
    bloodSplattersMats[#bloodSplattersMats+1] = Material("bo6/da/splatter"..i..".png", "noclamp smooth")
end
local bloodBigMat = Material("bo6/da/bigshot.png", "noclamp smooth")

nzEffects = nzEffects or {}

function nzEffects:ApplyDamageEffect(damageLevel, duration)
    if !isnumber(duration) then
        duration = 8
    end
    local profiles = {
        [1] = {countMin = 10, countMax = 14, size = 520, motionBlur = 0.38, bloodAlwaysAlpha = 55, dripMin = 14, dripMax = 32, dripAccelMin = 6, dripAccelMax = 14, dripCap = 60, dripSpeedMul = 1.4, dripAccelMul = 1.35, dripCapMul = 1.1, scaleMin = 0.7, scaleMax = 1.1, sway = 18, decay = 0.4, fadeSpeed = 220, globalFade = 0.25, vignette = 80, colourAdd = 0.02, darken = 0.05, contrast = 0.12, desaturate = 0.06, tint = {r = 210, g = 40, b = 40}, splatterAlpha = 120, corner = false},
        [2] = {countMin = 14, countMax = 20, size = 620, motionBlur = 0.48, bloodAlwaysAlpha = 85, dripMin = 22, dripMax = 45, dripAccelMin = 12, dripAccelMax = 18, dripCap = 90, dripSpeedMul = 1.5, dripAccelMul = 1.45, dripCapMul = 1.15, scaleMin = 0.8, scaleMax = 1.2, sway = 20, decay = 0.55, fadeSpeed = 240, globalFade = 0.3, vignette = 110, colourAdd = 0.03, darken = 0.07, contrast = 0.16, desaturate = 0.08, tint = {r = 215, g = 35, b = 35}, splatterAlpha = 160, corner = false},
        [3] = {countMin = 20, countMax = 28, size = 760, motionBlur = 0.58, bloodAlwaysAlpha = 115, dripMin = 30, dripMax = 55, dripAccelMin = 16, dripAccelMax = 24, dripCap = 130, dripSpeedMul = 1.65, dripAccelMul = 1.6, dripCapMul = 1.2, scaleMin = 0.9, scaleMax = 1.35, sway = 24, decay = 0.7, fadeSpeed = 260, globalFade = 0.35, vignette = 140, colourAdd = 0.04, darken = 0.09, contrast = 0.2, desaturate = 0.12, tint = {r = 220, g = 30, b = 30}, splatterAlpha = 200, corner = false},
        [4] = {countMin = 26, countMax = 36, size = 860, motionBlur = 0.66, bloodAlwaysAlpha = 135, dripMin = 34, dripMax = 62, dripAccelMin = 20, dripAccelMax = 28, dripCap = 160, dripSpeedMul = 1.8, dripAccelMul = 1.75, dripCapMul = 1.25, scaleMin = 1, scaleMax = 1.45, sway = 28, decay = 0.85, fadeSpeed = 300, globalFade = 0.42, vignette = 165, colourAdd = 0.05, darken = 0.12, contrast = 0.24, desaturate = 0.16, tint = {r = 225, g = 25, b = 25}, splatterAlpha = 180, corner = true},
    }
    local config = profiles[damageLevel]
    if not config then return end
    local effectDuration = math.max(duration, 1.5)
    local count = math.random(config.countMin, config.countMax)
    local positions = {}
    local splatterMat = false
    local bigShot
    local splatterAlpha = config.splatterAlpha or 0
    local screenW, screenH = ScrW(), ScrH()
    if splatterAlpha > 0 then
        splatterMat = bloodSplattersMats[math.random(#bloodSplattersMats)]
    end
    local speedMul = config.dripSpeedMul or 1
    local accelMul = config.dripAccelMul or speedMul
    local capMul = config.dripCapMul or 1
    for i = 1, count do
        local dripSpeed = math.Rand(config.dripMin, config.dripMax) * speedMul
        local dripAccel = math.Rand(config.dripAccelMin, config.dripAccelMax) * accelMul
        positions[i] = {
            x = math.random(-screenW * 0.1, screenW * 1.1),
            y = math.random(-screenH * 0.15, screenH * 0.95),
            yaw = math.random(-30, 30),
            mat = bloodShotMats[math.random(#bloodShotMats)],
            scale = math.Rand(config.scaleMin, config.scaleMax),
            alpha = math.random(180, 235),
            life = effectDuration * math.Rand(0.65, 1.05),
            maxLife = effectDuration,
            speed = dripSpeed,
            accel = dripAccel,
            cap = config.dripCap * capMul,
            sway = math.Rand(-config.sway, config.sway)
        }
    end
    if damageLevel == 4 then
        bigShot = {
            x = math.random(screenW - We(720), screenW - We(460)),
            y = math.random(screenH - He(420), screenH - He(260)),
            yaw = math.random(-18, 18),
            mat = bloodBigMat,
            scale = math.Rand(0.95, 1.25),
            alpha = 255,
            life = effectDuration,
            maxLife = effectDuration,
            speed = math.Rand(config.dripMin * 0.4, config.dripMin),
            accel = math.Rand(config.dripAccelMin * 0.5, config.dripAccelMin),
            cap = config.dripCap * 0.6,
            sway = math.Rand(-config.sway * 0.3, config.sway * 0.3)
        }
    end
    hook.Remove("HUDPaint", "DamageEffect")
    hook.Remove("RenderScreenspaceEffects", "DamageBlur")
    timer.Remove("RemoveHooksDeathAnimsEffect")
    local alpha = 0
    local mainalpha = 1
    local downalpha = false
    local downmainalpha = false
    timer.Simple(effectDuration - math.min(effectDuration * 0.35, 1), function()
        downmainalpha = true
    end)
    hook.Add("HUDPaint", "DamageEffect", function()
        local frame = FrameTime()
        screenW = ScrW()
        screenH = ScrH()
        if downalpha then
            alpha = math.max(alpha - frame * config.fadeSpeed, 0)
        else
            alpha = math.min(alpha + frame * config.fadeSpeed * 3, config.bloodAlwaysAlpha)
            if alpha >= config.bloodAlwaysAlpha then
                downalpha = true
            end
        end
        if downmainalpha then
            mainalpha = math.max(mainalpha - frame * config.globalFade, 0)
        end
        surface.SetDrawColor(255, 255, 255, alpha * mainalpha)
        surface.SetMaterial(bloodAlwaysMat)
        surface.DrawTexturedRect(0, 0, screenW, screenH)
        if type(splatterMat) == "IMaterial" and splatterAlpha > 0 then
            local overlayAlpha = math.Clamp(math.floor(splatterAlpha * mainalpha), 0, 255)
            if overlayAlpha > 0 then
                surface.SetDrawColor(255, 255, 255, overlayAlpha)
                surface.SetMaterial(splatterMat)
                surface.DrawTexturedRect(0, 0, screenW, screenH)
            end
        end
        for _, pos in ipairs(positions) do
            pos.life = math.max(pos.life - frame * config.decay, 0)
            if pos.life > 0 then
                pos.y = pos.y + pos.speed * frame
                pos.x = pos.x + pos.sway * frame
                pos.speed = math.min(pos.speed + pos.accel * frame, pos.cap)
                local fade = (pos.life / pos.maxLife) * mainalpha
                if fade > 0 and pos.mat then
                    local paintMat = pos.mat
                    local matType = type(paintMat)
                    if matType ~= "IMaterial" then
                        if matType == "number" then
                            paintMat = bloodShotMats[paintMat]
                        elseif matType == "string" then
                            paintMat = Material(paintMat, "noclamp smooth")
                        else
                            paintMat = nil
                        end
                        pos.mat = paintMat
                    end
                    if paintMat then
                        surface.SetDrawColor(config.tint.r, config.tint.g, config.tint.b, pos.alpha * fade)
                        surface.SetMaterial(paintMat)
                        surface.DrawTexturedRectRotated(pos.x, pos.y, We(config.size * pos.scale), He(config.size * pos.scale), pos.yaw)
                    end
                end
            end
        end
        if bigShot then
            bigShot.life = math.max(bigShot.life - frame * config.decay, 0)
            if bigShot.life > 0 and bigShot.mat then
                bigShot.y = bigShot.y + bigShot.speed * frame
                bigShot.x = bigShot.x + bigShot.sway * frame
                bigShot.speed = math.min(bigShot.speed + bigShot.accel * frame, bigShot.cap)
                local fade = (bigShot.life / bigShot.maxLife) * mainalpha
                if fade > 0 then
                    local bigMat = bigShot.mat
                    local matType = type(bigMat)
                    if matType ~= "IMaterial" then
                        if matType == "number" then
                            bigMat = bloodShotMats[bigMat]
                        elseif matType == "string" then
                            bigMat = Material(bigMat, "noclamp smooth")
                        else
                            bigMat = nil
                        end
                        bigShot.mat = bigMat
                    end
                    if bigMat then
                        surface.SetDrawColor(255, 255, 255, bigShot.alpha * fade)
                        surface.SetMaterial(bigMat)
                        surface.DrawTexturedRectRotated(bigShot.x, bigShot.y, We(config.size * bigShot.scale), He(config.size * bigShot.scale), bigShot.yaw)
                    end
                end
            end
        end
    end)
    hook.Add("RenderScreenspaceEffects", "DamageBlur", function()
        DrawMotionBlur(0.08, config.motionBlur, 0.015)
        DrawColorModify({
            ["$pp_colour_addr"] = config.colourAdd * mainalpha,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -config.darken * mainalpha,
            ["$pp_colour_contrast"] = 1 + config.contrast * mainalpha,
            ["$pp_colour_colour"] = 1 - config.desaturate * mainalpha,
            ["$pp_colour_mulr"] = config.colourAdd * 2.5 * mainalpha,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end)
    timer.Create("RemoveHooksDeathAnimsEffect", effectDuration, 1, function()
        hook.Remove("HUDPaint", "DamageEffect")
        hook.Remove("RenderScreenspaceEffects", "DamageBlur")
    end)
end

function nzEffects:DrawDOF(dist, dur)
    RunConsoleCommand("pp_dof", "1")
    RunConsoleCommand("pp_dof_initlength", tostring(dist))
    RunConsoleCommand("pp_dof_spacing", "128")
    timer.Simple(dur, function()
        RunConsoleCommand("pp_dof", "0")
    end)
end

ALLOW_DA_FP_RAGDOLL = false
net.Receive("nZr.DAFP", function()
    ALLOW_DA_FP_RAGDOLL = true
    hook.Add("CalcView", "nZrFPDeath", function(ply,pos,ang,fov)
        local rag = ply:GetRagdollEntity()
        if IsValid(rag) and ALLOW_DA_FP_RAGDOLL then
            rag:ManipulateBoneScale(rag:LookupBone("ValveBiped.Bip01_Head1"), Vector(0,0,0))
            
            local att = rag:GetAttachment(rag:LookupAttachment("eyes"))
            local view = {
                origin = att.Pos,
                angles = att.Ang,
                fov = fov,
                drawviewer = true,
                znear = 1,
            }

            return view
        else
            hook.Remove("CalcView", "nZrFPDeath")
            ALLOW_DA_FP_RAGDOLL = false
        end
    end)
end)