if not CLIENT then return end

local TPIKOffsetPanel = {}

function TPIKOffsetPanel:Init()
    self.items = {}
    self.sliders = {}
end

function TPIKOffsetPanel:PopulateTPIKSettings()
    for _, item in pairs(self.items) do
        if IsValid(item) then item:Remove() end
    end
    self.items = {}
    self.sliders = {}
    
    local scale = GetUIScale()
    
    local modelPanel = vgui.Create("DPanel", self)
    modelPanel:SetTall(50 * scale)
    modelPanel.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 200)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        local primaryColor = GetUIColorAlpha("primary", 200)
        draw.SimpleText("CURRENT PLAYERMODEL", "pier_small", 10 * scale, 10 * scale, primaryColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        local modelName = LocalPlayer():GetInfo("cl_playermodel")
        local textColor = GetUIColor("text")
        draw.SimpleText(modelName, "pier_small", 10 * scale, 30 * scale, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    self:Add(modelPanel)
    table.insert(self.items, modelPanel)
    
    local infoPanel = vgui.Create("DPanel", self)
    infoPanel:SetTall(70 * scale)
    infoPanel.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("secondary", 180)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        local borderColor = GetUIColorAlpha("accent", 255)
        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    local infoLabel1 = vgui.Create("DLabel", infoPanel)
    infoLabel1:SetPos(10 * scale, 10 * scale)
    infoLabel1:SetText("Adjust TPIK weapon position offsets for the current playermodel.")
    infoLabel1:SetFont("pier_small")
    local descColor = GetUIColorAlpha("text", 200)
    infoLabel1:SetTextColor(descColor)
    infoLabel1:SetSize(1000 * scale, 20 * scale)
    
    local infoLabel2 = vgui.Create("DLabel", infoPanel)
    infoLabel2:SetPos(10 * scale, 35 * scale)
    infoLabel2:SetText("Offsets are saved per-playermodel automatically when you click 'Save Offsets'.")
    infoLabel2:SetFont("pier_small")
    infoLabel2:SetTextColor(descColor)
    infoLabel2:SetSize(1000 * scale, 20 * scale)
    
    self:Add(infoPanel)
    table.insert(self.items, infoPanel)
    
    local posHeader = vgui.Create("DPanel", self)
    posHeader:SetTall(30 * scale)
    posHeader.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 200)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        local primaryColor = GetUIColorAlpha("primary", 200)
        draw.SimpleText("POSITION OFFSETS", "pier_small", 10 * scale, h/2, primaryColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self:Add(posHeader)
    table.insert(self.items, posHeader)
    
    self:AddSliderSetting("X Offset (Forward/Back)", "nz_tpik_offset_x", -50, 50)
    self:AddSliderSetting("Y Offset (Left/Right)", "nz_tpik_offset_y", -50, 50)
    self:AddSliderSetting("Z Offset (Up/Down)", "nz_tpik_offset_z", -50, 50)
    
    local angHeader = vgui.Create("DPanel", self)
    angHeader:SetTall(30 * scale)
    angHeader.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 200)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        local primaryColor = GetUIColorAlpha("primary", 200)
        draw.SimpleText("ANGLE OFFSETS", "pier_small", 10 * scale, h/2, primaryColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self:Add(angHeader)
    table.insert(self.items, angHeader)
    
    self:AddSliderSetting("Pitch (Up/Down rotation)", "nz_tpik_offset_pitch", -180, 180)
    self:AddSliderSetting("Yaw (Left/Right rotation)", "nz_tpik_offset_yaw", -180, 180)
    self:AddSliderSetting("Roll (Tilt rotation)", "nz_tpik_offset_roll", -180, 180)
    
    local actionsHeader = vgui.Create("DPanel", self)
    actionsHeader:SetTall(30 * scale)
    actionsHeader.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 200)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        local primaryColor = GetUIColorAlpha("primary", 200)
        draw.SimpleText("ACTIONS", "pier_small", 10 * scale, h/2, primaryColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self:Add(actionsHeader)
    table.insert(self.items, actionsHeader)
    
    local buttonsPanel = vgui.Create("DPanel", self)
    buttonsPanel:SetTall(90 * scale)
    buttonsPanel.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 180)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
    end
    
    local buttonWidth = (590 * scale - 15 * scale) / 2
    
    local saveBtn = nzUI.Components:CreateStyledButton(
        buttonsPanel,
        10 * scale,
        10 * scale,
        buttonWidth,
        30 * scale,
        "SAVE OFFSETS",
        "pier_small"
    )
    saveBtn.DoClick = function()
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_click_sub.mp3")
        RunConsoleCommand("nz_tpik_offset_save")
    end
    
    local loadBtn = nzUI.Components:CreateStyledButton(
        buttonsPanel,
        buttonWidth + 15 * scale,
        10 * scale,
        buttonWidth,
        30 * scale,
        "LOAD OFFSETS",
        "pier_small"
    )
    loadBtn.DoClick = function()
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_click_sub.mp3")
        RunConsoleCommand("nz_tpik_offset_load")
        timer.Simple(0.1, function()
            for _, slider in ipairs(self.sliders) do
                if slider.cvarName and GetConVar(slider.cvarName) then
                    slider:SetValue(GetConVar(slider.cvarName):GetFloat())
                end
            end
        end)
    end
    
    local resetBtn = nzUI.Components:CreateStyledButton(
        buttonsPanel,
        10 * scale,
        50 * scale,
        buttonWidth,
        30 * scale,
        "RESET TO DEFAULTS",
        "pier_small"
    )
    resetBtn.Paint = function(pnl, w, h)
        local isHovered = pnl:IsHovered()
        local col = isHovered and GetUIColorAlpha("reset_hover", 200) or GetUIColorAlpha("reset", 180)
        draw.RoundedBox(4, 0, 0, w, h, col)
        local btnTextColor = GetUIColor("text")
        draw.SimpleText("RESET TO DEFAULTS", "pier_small", w/2, h/2, btnTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    resetBtn.DoClick = function()
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_click_sub.mp3")
        RunConsoleCommand("nz_tpik_offset_reset")
        for _, slider in ipairs(self.sliders) do
            slider:SetValue(0)
        end
    end
    
    local clearBtn = nzUI.Components:CreateStyledButton(
        buttonsPanel,
        buttonWidth + 15 * scale,
        50 * scale,
        buttonWidth,
        30 * scale,
        "CLEAR SAVED OFFSETS",
        "pier_small"
    )
    clearBtn.Paint = function(pnl, w, h)
        local isHovered = pnl:IsHovered()
        local col = isHovered and GetUIColorAlpha("reset_hover", 200) or GetUIColorAlpha("reset", 180)
        draw.RoundedBox(4, 0, 0, w, h, col)
        local btnTextColor = GetUIColor("text")
        draw.SimpleText("CLEAR SAVED OFFSETS", "pier_small", w/2, h/2, btnTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    clearBtn.DoClick = function()
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_click_sub.mp3")
        RunConsoleCommand("nz_tpik_offset_clear")
        for _, slider in ipairs(self.sliders) do
            slider:SetValue(0)
        end
    end
    
    self:Add(buttonsPanel)
    table.insert(self.items, buttonsPanel)
    
    CreateClientConVar("cl_tpik_autosave", "0", true, false, "Automatically save TPIK offsets when changing playermodel")
    
    local autoSavePanel = vgui.Create("DPanel", self)
    autoSavePanel:SetTall(40 * scale)
    autoSavePanel.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 180)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
    end
    
    local autoSaveCheck = nzUI.Components:CreateSimpleStyledCheckbox(
        autoSavePanel,
        10 * scale,
        10 * scale,
        GetConVar("cl_tpik_autosave"):GetBool()
    )
    autoSaveCheck.OnChange = function(pnl, bVal)
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_click_sub.mp3")
        RunConsoleCommand("cl_tpik_autosave", bVal and "1" or "0")
    end
    
    local autoSaveLabel = vgui.Create("DLabel", autoSavePanel)
    autoSaveLabel:SetPos(50 * scale, 10 * scale)
    autoSaveLabel:SetText("Auto-save on model change")
    autoSaveLabel:SetFont("pier_small")
    local textColor = GetUIColor("text")
    autoSaveLabel:SetTextColor(textColor)
    autoSaveLabel:SizeToContents()
    
    self:Add(autoSavePanel)
    table.insert(self.items, autoSavePanel)
end

function TPIKOffsetPanel:AddSliderSetting(label, cvarName, min, max)
    local scale = GetUIScale()
    
    local panel = vgui.Create("DPanel", self)
    panel:SetTall(60 * scale)
    panel.Paint = function(pnl, w, h)
        local bgColor = GetUIColorAlpha("background", 180)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
    end
    
    local nameLabel = vgui.Create("DLabel", panel)
    nameLabel:SetSize(250 * scale, 20 * scale)
    nameLabel:SetPos(10 * scale, 5 * scale)
    nameLabel:SetText(string.upper(label))
    nameLabel:SetFont("pier_small")
    local textColor = GetUIColor("text")
    nameLabel:SetTextColor(textColor)
    nameLabel:SetContentAlignment(7)
    
    local convar = GetConVar(cvarName)
    local currentValue = convar and convar:GetFloat() or 0
    
    local slider = vgui.Create("DNumSlider", panel)
    slider:SetSize(320 * scale, 30 * scale)
    slider:SetPos(270 * scale, 15 * scale)
    slider:SetText("")
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetDecimals(2)
    slider:SetValue(currentValue)
    slider.cvarName = cvarName
    
    slider.Slider.Paint = function(pnl, w, h)
        local trackColor = GetUIColorAlpha("secondary", 200)
        draw.RoundedBox(4, 0, 0, w, h, trackColor)
        local frac = pnl:GetSlideX()
        local fillColor = GetUIColorAlpha("primary", 200)
        draw.RoundedBox(4, 0, 0, w * frac, h, fillColor)
    end
    
    slider.TextArea:SetVisible(false)
    
    local valueLabel = vgui.Create("DLabel", slider)
    valueLabel:Dock(FILL)
    valueLabel:SetFont("pier_smaller")
    local labelColor = GetUIColor("text")
    valueLabel:SetTextColor(labelColor)
    valueLabel:SetContentAlignment(5)
    
    local originalPaint = valueLabel.Paint
    valueLabel.Paint = function(pnl, w, h)
        local text = pnl:GetText()
        surface.SetFont(pnl:GetFont())
        local textW, textH = surface.GetTextSize(text)
        
        local boxW = textW + 8
        local boxH = textH + 4
        local boxX = (w - boxW) / 2
        local boxY = (h - boxH) / 2 - 2
        
        draw.RoundedBox(3, boxX, boxY, boxW, boxH, Color(0, 0, 0, 120))
        if originalPaint then originalPaint(pnl, w, h) end
    end
    
    local function UpdateValueLabel()
        valueLabel:SetText(string.format("%.2f", slider:GetValue()))
    end
    
    UpdateValueLabel()
    
    slider.OnValueChanged = function(pnl, value)
        RunConsoleCommand(cvarName, tostring(value))
        surface.PlaySound("nz_moo/effects/ui/" .. GetSoundPack() .. "/sys_hover_main.mp3")
        UpdateValueLabel()
    end
    
    self:Add(panel)
    table.insert(self.items, panel)
    table.insert(self.sliders, slider)
end

function TPIKOffsetPanel:Paint(w, h) end

vgui.Register("NZTPIKOffsetPanel", TPIKOffsetPanel, "DListLayout")

hook.Add("InitPostEntity", "RegisterTPIKTab", function()
    nzUserSettings:RegisterTab({
        id = "tpik",
        name = "TPIK",
        order = 10,
        contentFunction = function(parent)
            local panel = vgui.Create("NZTPIKOffsetPanel", parent)
            panel:PopulateTPIKSettings()
            return panel
        end
    })
end)

local lastModel = ""
hook.Add("Think", "TPIK_AutoSave", function()
    if not GetConVar("cl_tpik_autosave") or not GetConVar("cl_tpik_autosave"):GetBool() then return end
    
    local currentModel = string.lower(player_manager.TranslatePlayerModel(LocalPlayer():GetInfo("cl_playermodel")))
    if currentModel != lastModel and lastModel != "" then
        RunConsoleCommand("nz_tpik_offset_save")
    end
    lastModel = currentModel
end)