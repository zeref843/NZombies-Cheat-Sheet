nzPause = nzPause or {}
nzPause.Paused = false
nzPause.CanBePaused = true

if SERVER then

    function nzPause:IsPossible()
        local bool, reason = true, "Unknown"
        if !nzPause.CanBePaused then
            bool, reason = false, "You cannot pause a round, this feature is currently blocked."
        elseif nzPause.Paused then
            bool, reason = false, "You cannot pause a round when its already paused."
        elseif nzRound:GetState() != ROUND_PROG and nzRound:GetState() != ROUND_PREP then
            bool, reason = false, "You cannot pause a round when game not existing."
        elseif IsValid(nZr_Exfil_Position) then
            bool, reason = false, "You cannot pause a round when an exfil active."
        elseif nzRound:GetZombiesMax() >= 99999 then
            bool, reason = false, "You cannot pause a round when special event is active."
        elseif #player.GetAllPlayingAndAlive() == 0 then
            bool, reason = false, "You cannot pause a round when players are not alive."
        end
        return bool, reason
    end
    
    function nzPause:Begin()
        if !nzPause:IsPossible() then return end

        nzPause.Paused = true
        BroadcastLua([[nzPause.Paused = true]])
        nzRound:Freeze(true)
    end

    function nzPause:Stop()
        if !nzPause.Paused then return end

        nzPause.Paused = false
        BroadcastLua([[nzPause.Paused = false]])
        nzRound:Freeze(false)
        for k,v in pairs(ents.GetAll()) do
            if v:IsPlayer() then
                v:Freeze(false)
                v:GodDisable()
                v:SetTargetPriority(2)
            end
        end
    end

    function nzPause:Vote(ply)
        local bool, reason = nzPause:IsPossible()
        if !isentity(ply) and !bool then 
            return 
        elseif isentity(ply) and !bool then
            ply:ChatPrint(reason)
            return
        end
        
        -- Check if there are multiple players
        if #player.GetAllPlayingAndAlive() > 1 then
            -- Start vote
            if nzVotes then
                nzVotes:StartVote("Pause the game?", 0.75, function()
                    nzPause:Begin()
                end)
            else
                -- Fallback if vote system not available
                nzPause:Begin()
            end
        else
            -- Single player, pause immediately
            nzPause:Begin()
        end
    end

    local function tryPause(ply)
        if IsValid(ply) then
            if nzPause.Paused then
                -- Anyone can unpause
                nzPause:Stop()
            else
                nzPause:Vote(ply)
            end
        end
    end

    nzChatCommand.Add("/pausegame", SERVER, function(ply, text)
        tryPause(ply)
    end, true, "Vote to pause the game.")
    
    concommand.Add("nz_pausegame", function(ply)
        tryPause(ply)
    end)

    hook.Add("PlayerPostThink", "nzPause.Think", function(ply)
        if nzPause.Paused then
            ply:SetTargetPriority(0)
            ply:Freeze(true)
            ply:GodEnable()
        end
    end)

    hook.Add("OnRoundEnd", "nzPauseFix", function()
        nzPause:Stop()
    end)

else

    hook.Add("HUDPaint", "nzrPauseHUD", function()
        if !nzPause.Paused then return end

        surface.SetDrawColor(0,0,0,230)
        surface.DrawRect(0,0,ScrW(),ScrH())
        draw.SimpleText("THE GAME HAS BEEN PAUSED", "BO6_Exfil72", ScrW()/2, ScrH()/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local logoMat = Material("nz_moo/icons/logo_small_hd.png")
        local logoSize = 64
        local logoX = ScrW() / 2
        local logoY = ScrH() - 100
        
        local spinSpeed = 2
        local spinAngle = (CurTime() / spinSpeed) * 360
        
        local scaleX = math.cos(math.rad(spinAngle))
        local depthScale = 1 + (math.abs(math.sin(math.rad(spinAngle))) * 0.15)
        
        local drawW = logoSize * math.abs(scaleX) * depthScale
        local drawH = logoSize * depthScale
        
        local centerOffsetX = (logoSize - drawW) / 2
        local centerOffsetY = (logoSize - drawH) / 2
        
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(logoMat)
        
        if scaleX < 0 then
            surface.DrawTexturedRectUV(logoX - logoSize/2 + centerOffsetX, logoY - logoSize/2 + centerOffsetY, drawW, drawH, 1, 0, 0, 1)
        else
            surface.DrawTexturedRectUV(logoX - logoSize/2 + centerOffsetX, logoY - logoSize/2 + centerOffsetY, drawW, drawH, 0, 0, 1, 1)
        end
        
        if LocalPlayer():IsSuperAdmin() then
            draw.SimpleText("[USE /PAUSEGAME IN CHAT TO CONTINUE THE GAME]", "BO6_Exfil26", ScrW()/2, ScrH()/1.85, Color(200,20,20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)

end