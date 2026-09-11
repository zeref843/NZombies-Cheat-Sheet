if CLIENT then
    CreateClientConVar("nz_tpik_offset_x", "0", true, false, "TPIK X position offset")
    CreateClientConVar("nz_tpik_offset_y", "0", true, false, "TPIK Y position offset")
    CreateClientConVar("nz_tpik_offset_z", "0", true, false, "TPIK Z position offset")
    CreateClientConVar("nz_tpik_offset_pitch", "0", true, false, "TPIK pitch angle offset")
    CreateClientConVar("nz_tpik_offset_yaw", "0", true, false, "TPIK yaw angle offset")
    CreateClientConVar("nz_tpik_offset_roll", "0", true, false, "TPIK roll angle offset")
    
    local TPIKOffsets = {}
    
    local OFFSET_FILE = "lf_playermodel_selector/tpik_offsets.txt"
    
    if !file.Exists("lf_playermodel_selector", "DATA") then 
        file.CreateDir("lf_playermodel_selector") 
    end
    
    local function LoadOffsets()
        if file.Exists(OFFSET_FILE, "DATA") then
            local loaded = util.JSONToTable(file.Read(OFFSET_FILE, "DATA"))
            if istable(loaded) then
                TPIKOffsets = loaded
            end
        end
    end
    
    local function SaveOffsets()
        file.Write(OFFSET_FILE, util.TableToJSON(TPIKOffsets, true))
    end
    
    local function GetCurrentPlayerModel()
        return string.lower(player_manager.TranslatePlayerModel(LocalPlayer():GetInfo("cl_playermodel")))
    end
    
    local function SaveCurrentOffsets()
        local model = GetCurrentPlayerModel()
        if !model then return end
        
        TPIKOffsets[model] = {
            pos = Vector(
                GetConVar("nz_tpik_offset_x"):GetFloat(),
                GetConVar("nz_tpik_offset_y"):GetFloat(),
                GetConVar("nz_tpik_offset_z"):GetFloat()
            ),
            ang = Angle(
                GetConVar("nz_tpik_offset_pitch"):GetFloat(),
                GetConVar("nz_tpik_offset_yaw"):GetFloat(),
                GetConVar("nz_tpik_offset_roll"):GetFloat()
            )
        }
        
        SaveOffsets()
    end
    
    local function LoadCurrentOffsets()
        local model = GetCurrentPlayerModel()
        if !model or !TPIKOffsets[model] then 
            RunConsoleCommand("nz_tpik_offset_x", "0")
            RunConsoleCommand("nz_tpik_offset_y", "0")
            RunConsoleCommand("nz_tpik_offset_z", "0")
            RunConsoleCommand("nz_tpik_offset_pitch", "0")
            RunConsoleCommand("nz_tpik_offset_yaw", "0")
            RunConsoleCommand("nz_tpik_offset_roll", "0")
            return 
        end
        
        local offsets = TPIKOffsets[model]
        RunConsoleCommand("nz_tpik_offset_x", tostring(offsets.pos.x))
        RunConsoleCommand("nz_tpik_offset_y", tostring(offsets.pos.y))
        RunConsoleCommand("nz_tpik_offset_z", tostring(offsets.pos.z))
        RunConsoleCommand("nz_tpik_offset_pitch", tostring(offsets.ang.p))
        RunConsoleCommand("nz_tpik_offset_yaw", tostring(offsets.ang.y))
        RunConsoleCommand("nz_tpik_offset_roll", tostring(offsets.ang.r))
    end
    
    function GetTPIKOffset(model)
        model = model or GetCurrentPlayerModel()
        if !model then return Vector(0,0,0), Angle(0,0,0) end
        
        model = string.lower(model)
        
        if TPIKOffsets[model] then
            return TPIKOffsets[model].pos or Vector(0,0,0), TPIKOffsets[model].ang or Angle(0,0,0)
        end
        
        return Vector(0,0,0), Angle(0,0,0)
    end
    
    concommand.Add("nz_tpik_offset_save", function()
        SaveCurrentOffsets()
        chat.AddText(Color(100, 255, 100), "[TPIK] ", color_white, "Offsets saved for current playermodel")
    end, nil, "Save current TPIK offsets for the current playermodel")
    
    concommand.Add("nz_tpik_offset_load", function()
        LoadCurrentOffsets()
        chat.AddText(Color(100, 255, 100), "[TPIK] ", color_white, "Offsets loaded for current playermodel")
    end, nil, "Load TPIK offsets for the current playermodel")
    
    concommand.Add("nz_tpik_offset_reset", function()
        RunConsoleCommand("nz_tpik_offset_x", "0")
        RunConsoleCommand("nz_tpik_offset_y", "0")
        RunConsoleCommand("nz_tpik_offset_z", "0")
        RunConsoleCommand("nz_tpik_offset_pitch", "0")
        RunConsoleCommand("nz_tpik_offset_yaw", "0")
        RunConsoleCommand("nz_tpik_offset_roll", "0")
        chat.AddText(Color(100, 255, 100), "[TPIK] ", color_white, "Offsets reset to defaults")
    end, nil, "Reset TPIK offsets to default values")
    
    concommand.Add("nz_tpik_offset_clear", function()
        local model = GetCurrentPlayerModel()
        if model and TPIKOffsets[model] then
            TPIKOffsets[model] = nil
            SaveOffsets()
            LoadCurrentOffsets()
            chat.AddText(Color(100, 255, 100), "[TPIK] ", color_white, "Saved offsets cleared for current playermodel")
        else
            chat.AddText(Color(255, 100, 100), "[TPIK] ", color_white, "No saved offsets for current playermodel")
        end
    end, nil, "Clear saved TPIK offsets for the current playermodel")
    
    LoadOffsets()
    
    local meta = FindMetaTable("Player")
    local oldGetHoldtypeOffset = meta.GetHoldtypeOffset
    
    function meta:GetHoldtypeOffset()
        local basePos, baseAng = oldGetHoldtypeOffset(self)
        
        if self != LocalPlayer() then 
            return basePos, baseAng 
        end
        
        local offsetPos = Vector(
            GetConVar("nz_tpik_offset_x"):GetFloat(),
            GetConVar("nz_tpik_offset_y"):GetFloat(),
            GetConVar("nz_tpik_offset_z"):GetFloat()
        )
        
        local offsetAng = Angle(
            GetConVar("nz_tpik_offset_pitch"):GetFloat(),
            GetConVar("nz_tpik_offset_yaw"):GetFloat(),
            GetConVar("nz_tpik_offset_roll"):GetFloat()
        )
        
        return basePos + offsetPos, baseAng + offsetAng
    end
    
    hook.Add("Think", "TPIK_AutoLoadOffsets", function()
        local newModel = GetCurrentPlayerModel()
        if newModel != TPIK_LastModel then
            TPIK_LastModel = newModel
            LoadCurrentOffsets()
        end
    end)
    
    _G.TPIK_SaveCurrentOffsets = SaveCurrentOffsets
    _G.TPIK_LoadCurrentOffsets = LoadCurrentOffsets
    _G.TPIK_GetAllOffsets = function() return TPIKOffsets end
    
end