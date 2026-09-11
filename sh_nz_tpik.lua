-- Made by Hari exclusive for nZombies Rezzurection and Bloodshed: Redux. Copying this code is prohibited!

if CLIENT then
    local tpik = CreateConVar("nz_tfa_tpik", 0, FCVAR_ARCHIVE, "", 0, 1)
    local meta = FindMetaTable("Player")
    local TPIKBones = {
        "ValveBiped.Bip01_L_Hand",
        "ValveBiped.Bip01_L_Finger4",
        "ValveBiped.Bip01_L_Finger41",
        "ValveBiped.Bip01_L_Finger42",
        "ValveBiped.Bip01_L_Finger3",
        "ValveBiped.Bip01_L_Finger31",
        "ValveBiped.Bip01_L_Finger32",
        "ValveBiped.Bip01_L_Finger2",
        "ValveBiped.Bip01_L_Finger21",
        "ValveBiped.Bip01_L_Finger22",
        "ValveBiped.Bip01_L_Finger1",
        "ValveBiped.Bip01_L_Finger11",
        "ValveBiped.Bip01_L_Finger12",
        "ValveBiped.Bip01_L_Finger0",
        "ValveBiped.Bip01_L_Finger01",
        "ValveBiped.Bip01_L_Finger02",
        "ValveBiped.Bip01_R_Hand",
        "ValveBiped.Bip01_R_Finger4",
        "ValveBiped.Bip01_R_Finger41",
        "ValveBiped.Bip01_R_Finger42",
        "ValveBiped.Bip01_R_Finger3",
        "ValveBiped.Bip01_R_Finger31",
        "ValveBiped.Bip01_R_Finger32",
        "ValveBiped.Bip01_R_Finger2",
        "ValveBiped.Bip01_R_Finger21",
        "ValveBiped.Bip01_R_Finger22",
        "ValveBiped.Bip01_R_Finger1",
        "ValveBiped.Bip01_R_Finger11",
        "ValveBiped.Bip01_R_Finger12",
        "ValveBiped.Bip01_R_Finger0",
        "ValveBiped.Bip01_R_Finger01",
        "ValveBiped.Bip01_R_Finger02",
    }

    local TPIKDisableHoldtypes = {
        normal = true,
        passive = true,
        magic = true
    }

    local HoldtypeOffsets = {
        default     = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        pistol      = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        revolver    = { pos = Vector(8, 2, 2), ang = Angle(0, 0, 0) },
        ar2         = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        smg         = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        shotgun     = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        crossbow    = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        melee       = { pos = Vector(-8, -2, 4), ang = Angle(0, 0, 0) },
        grenade     = { pos = Vector(4, -4, 4), ang = Angle(0, 0, 0) },
        fist        = { pos = Vector(6, -0, 4), ang = Angle(0, 0, 0) },
    }

    local function wepstate(bool, wpn)
        if !wpn.fwmdataeffects then
            wpn.fwmdataeffects = {wpn.LuaShellEject, wpn.MuzzleFlashEnabled}
        end
        local t = wpn.fwmdataeffects
        if bool then
            wpn.LuaShellEject = t[1]
            wpn.MuzzleFlashEnabled = t[2]
            wpn:SetNoDraw(false)
            wpn.InTPIK = false
        else
            wpn.LuaShellEject = false
            wpn.MuzzleFlashEnabled = false
            wpn:SetNoDraw(true)
            wpn.InTPIK = true
        end
    end

    local function IsWeaponHolstering(wpn)
        if not IsValid(wpn) then return false end
        
        if wpn.GetStatus then
            local status = wpn:GetStatus()
            if status == TFA.Enum.STATUS_HOLSTER or status == TFA.Enum.STATUS_HOLSTER_START or status == TFA.Enum.STATUS_HOLSTER_END then
                return true
            end
        end
        
        if wpn.Holstering or wpn.IsHolstering then
            return true
        end
        
        return false
    end

    local function IsWeaponReloading(wpn)
        if not IsValid(wpn) then return false end
        
        if wpn.GetStatus then
            local status = wpn:GetStatus()
            if status == TFA.Enum.STATUS_RELOADING or status == TFA.Enum.STATUS_RELOADING_WAIT or status == TFA.Enum.STATUS_RELOADING_PUMP then
                return true
            end
        end
        
        if wpn.Reloading or wpn.IsReloading then
            return true
        end
        
        if wpn.GetActivity then
            local act = wpn:GetActivity()
            if act == ACT_VM_RELOAD or act == ACT_VM_RELOAD_EMPTY or act == ACT_SHOTGUN_RELOAD_START or act == ACT_SHOTGUN_RELOAD_FINISH then
                return true
            end
        end
        
        return false
    end

    local cached_children = {}
    local function recursive_get_children(ent, bone, bones, endbone)
        local bone = isstring(bone) and ent:LookupBone(bone) or bone

        if not bone or isstring(bone) or bone == -1 then return end
        
        local children = ent:GetChildBones(bone)
        if #children > 0 then
            local id
            for i = 1,#children do
                id = children[i]
                if id == endbone then continue end
                recursive_get_children(ent, id, bones, endbone)
                table.insert(bones, id)
            end
        end
    end

    local function get_children(ent, bone, endbone)
        local bones = {}

        local mdl = ent:GetModel()
        if cached_children[mdl] and cached_children[mdl][bone] then return cached_children[mdl][bone] end

        recursive_get_children(ent, bone, bones, endbone)

        cached_children[mdl] = cached_children[mdl] or {}
        cached_children[mdl][bone] = bones

        return bones
    end

    local function bone_apply_matrix(ent, bone, new_matrix, endbone)
        local bone = isstring(bone) and ent:LookupBone(bone) or bone

        if not bone or isstring(bone) or bone == -1 then return end

        local matrix = ent:GetBoneMatrix(bone)
        if not matrix then return end
        local inv_matrix = matrix:GetInverse()
        if not inv_matrix then return end

        local children = get_children(ent, bone, endbone)
        
        local translate = (new_matrix * inv_matrix)
        local id
        for i = 1,#children do
            id = children[i]
            local mat = ent:GetBoneMatrix(id)
            if not mat then continue end
            ent:SetBoneMatrix(id, translate * mat)
        end

        ent:SetBoneMatrix(bone, new_matrix)
    end

    function meta:Solve2PartIK(start_p, end_p, length0, length1, sign, angs)
        local length2 = (start_p - end_p):Length()
        local cosAngle0 = math.Clamp(((length2 * length2) + (length0 * length0) - (length1 * length1)) / (2 * length2 * length0), -1, 1)
        local angle0 = -math.deg(math.acos(cosAngle0))
        local cosAngle1 = math.Clamp(((length1 * length1) + (length0 * length0) - (length2 * length2)) / (2 * length1 * length0), -1, 1)
        local angle1 = -math.deg(math.acos(cosAngle1))

        local diff = end_p - start_p
        diff:Normalize()

        local angle2 = math.deg(math.atan2(-math.sqrt(diff.x * diff.x + diff.y * diff.y), diff.z)) - 90
        local angle3 = -math.deg(math.atan2(diff.x, diff.y)) - 90
        angle3 = math.NormalizeAngle(angle3)

        local axis = diff * 1
        axis:Normalize()

        local Joint0 = Angle(angle0 + angle2, angle3, 0)
        local diffa2 = 90 + (sign > 0 and -30 or 30)

        local torsoright = angs.y + 120 * sign
        
        Joint0:RotateAroundAxis(Joint0:Forward(), diffa2)
        Joint0:RotateAroundAxis(axis, angle3 - torsoright)
        local ang1 = -(-Joint0)

        local Joint0 = Joint0:Forward() * length0

        local Joint1 = Angle(angle0 + angle2 + 180 + angle1, angle3, 0)
        Joint1:RotateAroundAxis(Joint1:Forward(), diffa2)
        Joint1:RotateAroundAxis(axis, angle3 - torsoright)
        local ang2 = -(-Joint1)

        local Joint1 = Joint1:Forward() * length1

        local Joint0_F = start_p + Joint0
        local Joint1_F = Joint0_F + Joint1

        return Joint0_F, Joint1_F, ang1, ang2
    end

    function meta:GetHoldtypeOffset()
        local wpn = self:GetActiveWeapon()
        local ht = "default"

        if IsValid(wpn) and (wpn.IsTFAWeapon and (wpn.Base == "tfa_melee_base" or wpn.Base == "tfa_nmrimelee_base")) then
            ht = "melee"
            wpn:SetHoldType("revolver")
        end

        if IsValid(wpn) then
            local posOverride = wpn.TPIKPos
            local angOverride = wpn.TPIKAng
            if posOverride or angOverride then
                return posOverride or Vector(0, 0, 0), angOverride or Angle(0, 0, 0)
            end
        end

        if IsValid(wpn) and wpn.GetHoldType then
            local ok, res = pcall(function() return wpn:GetHoldType() end)
            if ok and isstring(res) and res ~= "" then
                ht = string.lower(res)
            end
        end

        local cfg = HoldtypeOffsets[ht] or HoldtypeOffsets.default
        return cfg.pos, cfg.ang
    end

    function meta:CreateFakeWorldModel(wpn)
        if IsValid(self.FakeWorldModel) then
            return self.FakeWorldModel
        end

        local vm = self:GetViewModel()
        if !IsValid(vm) then return end

        local model = ClientsideModel(vm:GetModel())
        model:SetParent(self)
        model:SetNoDraw(true)
        model.VElementsFWM = {}
        self.FakeWorldModel = model

        if istable(wpn.VElements) then
            for k, v in pairs(wpn.VElements) do
                if v.type != "Model" or v.size:Length() < 0.2 then continue end
                local att = ClientsideModel(v.model)
                att:SetParent(model)
                att:SetNoDraw(true)
                att:SetPos(model:GetPos())
                att:SetAngles(model:GetAngles())
                if v.bonemerge then
                    att:AddEffects(EF_BONEMERGE)
                    att:AddEffects(EF_BONEMERGE_FASTCULL)
                end
                att.Data = {bone = v.bone, pos = v.pos, angle = v.angle, size = v.size, color = v.color, material = v.material, skin = v.skin, bonemerge = v.bonemerge}

                table.insert(model.VElementsFWM, att)
            end
        end

        if istable(wpn.ViewModelBoneMods) then
            for k, v in pairs(wpn.ViewModelBoneMods) do
                local bone = model:LookupBone(k)
                if !bone then continue end
                if isvector(v.scale) then model:ManipulateBoneScale(bone, v.scale) end
                if isangle(v.angle) then model:ManipulateBoneAngles(bone, v.angle) end
                if isvector(v.pos) then model:ManipulateBonePosition(bone, v.pos) end
            end
        end

        if istable(wpn.TPIKHideBones) then
            for _, v in pairs(wpn.TPIKHideBones) do
                local bone = model:LookupBone(v)
                if !bone then continue end
                model:ManipulateBoneScale(bone, Vector(0,0,0))
            end
        end

        local wpn = self:GetActiveWeapon()
        if IsValid(wpn) and isstring(wpn.UseBonemergeHands) and wpn.UseBonemergeHands ~= "" then
            SafeRemoveEntity(self.FWMHands)
            local hands = ClientsideModel(wpn.UseBonemergeHands)
            if IsValid(hands) then
                hands:SetNoDraw(true)
                hands:SetParent(model)
                if hands.AddEffects and EF_BONEMERGE then
                    hands:AddEffects(EF_BONEMERGE)
                    hands:AddEffects(EF_BONEMERGE_FASTCULL)
                end
                self.FWMHands = hands
            end
        end

        return model
    end

    function meta:GetFWM(isbool)
        return !isbool and self.FakeWorldModel or IsValid(self.FakeWorldModel)
    end

    function meta:UpdateBoneListWM()
        if not self.FWMBones then
            self.FWMBones = {}
        end
        self.FWMBones["spine4"] = self:LookupBone("ValveBiped.Bip01_Spine4")
    end

    function meta:UpdateFakeWorldModel()
        if !self:GetFWM(true) or !istable(self.FWMBones) then return end
        
        local fwm = self:GetFWM()
        local vm = self:GetViewModel()
        local wpn = self:GetActiveWeapon()
        local pos = self:GetBonePosition(self.FWMBones["spine4"])
        local ang = self:GetAimVector():Angle()
        local oPos, oAng = self:GetHoldtypeOffset()
        
        local finalPos, finalAng = LocalToWorld(oPos or Vector(4, -4, 4), oAng or Angle(0, 0, 0), pos, ang)

        fwm:SetModel(vm:GetModel())
        fwm:SetPos(finalPos)
        fwm:SetAngles(finalAng)
        fwm:SetSkin(vm:GetSkin())
        
        if fwm.GetNumBodyGroups and vm.GetNumBodyGroups then
            local cnt = math.min(vm:GetNumBodyGroups(), fwm:GetNumBodyGroups())
            for i = 0, cnt - 1 do
                local bg = vm:GetBodygroup(i)
                if isnumber(bg) then fwm:SetBodygroup(i, bg) end
            end
        end
        
        fwm:SetSequence(vm:GetSequence())
        fwm:SetCycle(vm:GetCycle())
        fwm:SetPlaybackRate(vm:GetPlaybackRate())
        fwm:InvalidateBoneCache()
        
        if IsValid(wpn) and wpn.PreDrawViewModel then
            local ok, err = pcall(function()
                wpn:PreDrawViewModel(fwm)
            end)
            if not ok then
                ErrorNoHalt("[TPIK] Error in PreDrawViewModel: " .. tostring(err) .. "\n")
            end
        end
        
        for k, v in ipairs(fwm.VElementsFWM) do
            local t = v.Data
            if !t.bonemerge then
                local bone = fwm:LookupBone(t.bone)
                if bone then
                    local m = fwm:GetBoneMatrix(bone)
                    if !m then continue end
                    local pos, ang = m:GetTranslation(), m:GetAngles()
                    v:SetPos(pos + ang:Forward() * t.pos.x + ang:Right() * t.pos.y + ang:Up() * t.pos.z)
                    ang:RotateAroundAxis(ang:Up(), t.angle.y)
                    ang:RotateAroundAxis(ang:Right(), t.angle.p)
                    ang:RotateAroundAxis(ang:Forward(), t.angle.r)
                    v:SetAngles(ang)
                    local matrix = Matrix()
                    matrix:Scale(t.size)
                    v:EnableMatrix("RenderMultiply", matrix)
                end
            end

            if t.material == "" then
                v:SetMaterial("")
            elseif v:GetMaterial() ~= t.material then
                v:SetMaterial(t.material)
            end

            if t.skin and t.skin ~= v:GetSkin() then
                v:SetSkin(t.skin)
            end

            v:DrawModel()
        end
    end

    function meta:UpdateFWMConnection()
        if !self:GetFWM(true) or !istable(self.FWMBones) then return end

        local wm = self:GetFWM()
        local wmSrc = IsValid(self.FWMHands) and self.FWMHands or wm
        wmSrc:SetupBones()
        self:SetupBones()
        if IsValid(self.FWMHands) then
            self.FWMHands:SetPos(wm:GetPos())
            self.FWMHands:SetAngles(wm:GetAngles())
        end

        local disableTPIK = false

        if not disableTPIK then
            local wm = wmSrc
            local ply_spine_index = self:LookupBone("ValveBiped.Bip01_Spine4")
            if !ply_spine_index then return end
            local ply_spine_matrix = self:GetBoneMatrix(ply_spine_index)
            local wmpos = ply_spine_matrix:GetTranslation()
            local eyeahg = self:EyeAngles()
            local wpn = self:GetActiveWeapon()
            local htype = wpn:GetHoldType()

            if htype == "passive" or htype == "normal" then
                eyeahg.y = eyeahg.y - (self:GetPoseParameter("aim_yaw") or 0) * 160 + 80 or 0
            end

            for _, bone in ipairs(TPIKBones) do
                local wm_boneindex = wm:LookupBone(bone)
                if !wm_boneindex then continue end
                local wm_bonematrix = wm:GetBoneMatrix(wm_boneindex)
                if !wm_bonematrix then continue end

                local ply_boneindex = self:LookupBone(bone)
                if !ply_boneindex then continue end
                local ply_bonematrix = self:GetBoneMatrix(ply_boneindex)
                if !ply_bonematrix then continue end

                local bonepos = wm_bonematrix:GetTranslation()
                local boneang = wm_bonematrix:GetAngles()

                bonepos.x = math.Clamp(bonepos.x, wmpos.x - 38, wmpos.x + 38)
                bonepos.y = math.Clamp(bonepos.y, wmpos.y - 38, wmpos.y + 38)
                bonepos.z = math.Clamp(bonepos.z, wmpos.z - 38, wmpos.z + 38)

                ply_bonematrix:SetTranslation(bonepos)
                ply_bonematrix:SetAngles(boneang)

                self:SetBoneMatrix(ply_boneindex, ply_bonematrix)
                self:SetBonePosition(ply_boneindex, bonepos, boneang)
            end

            local ply_r_upperarm_index = self:LookupBone("ValveBiped.Bip01_R_UpperArm")
            local ply_r_forearm_index = self:LookupBone("ValveBiped.Bip01_R_Forearm")
            local ply_r_hand_index = self:LookupBone("ValveBiped.Bip01_R_Hand")
            if !ply_r_upperarm_index or !ply_r_forearm_index or !ply_r_hand_index then return end

            local ply_l_upperarm_index = self:LookupBone("ValveBiped.Bip01_L_UpperArm")
            local ply_l_forearm_index = self:LookupBone("ValveBiped.Bip01_L_Forearm")
            local ply_l_hand_index = self:LookupBone("ValveBiped.Bip01_L_Hand")
            if !ply_l_upperarm_index or !ply_l_forearm_index or !ply_l_hand_index then return end

            local limblength = self:BoneLength(ply_l_forearm_index)
            if !limblength or limblength == 0 then limblength = 12 end
            local r_upperarm_length = limblength
            local r_forearm_length = limblength
            local l_upperarm_length = limblength
            local l_forearm_length = limblength

            local ply_r_upperarm_matrix = self:GetBoneMatrix(ply_r_upperarm_index)
            local ply_r_forearm_matrix = self:GetBoneMatrix(ply_r_forearm_index)
            local ply_r_hand_matrix = self:GetBoneMatrix(ply_r_hand_index)
            local ply_r_upperarm_pos, ply_r_forearm_pos, ply_r_upperarm_angle, ply_r_forearm_angle = self:Solve2PartIK(ply_r_upperarm_matrix:GetTranslation(), ply_r_hand_matrix:GetTranslation(), r_upperarm_length, r_forearm_length, -1.3, eyeahg)

            ply_r_upperarm_matrix:SetAngles(ply_r_upperarm_angle)
            ply_r_forearm_matrix:SetTranslation(ply_r_upperarm_pos)
            ply_r_forearm_matrix:SetAngles(ply_r_forearm_angle)
            ply_r_hand_matrix:SetTranslation(ply_r_forearm_pos)

            bone_apply_matrix(self, ply_r_upperarm_index, ply_r_upperarm_matrix, ply_r_forearm_index)
            bone_apply_matrix(self, ply_r_forearm_index, ply_r_forearm_matrix, ply_r_hand_index)
            bone_apply_matrix(self, ply_r_hand_index, ply_r_hand_matrix)

            local ply_l_upperarm_matrix = self:GetBoneMatrix(ply_l_upperarm_index)
            local ply_l_forearm_matrix = self:GetBoneMatrix(ply_l_forearm_index)
            local ply_l_hand_matrix = self:GetBoneMatrix(ply_l_hand_index)
            local ply_l_upperarm_pos, ply_l_forearm_pos, ply_l_upperarm_angle, ply_l_forearm_angle = self:Solve2PartIK(ply_l_upperarm_matrix:GetTranslation(), ply_l_hand_matrix:GetTranslation(), l_upperarm_length, l_forearm_length, 1, eyeahg)

            ply_l_upperarm_matrix:SetAngles(ply_l_upperarm_angle)
            ply_l_forearm_matrix:SetTranslation(ply_l_upperarm_pos)
            ply_l_forearm_matrix:SetAngles(ply_l_forearm_angle)
            ply_l_hand_matrix:SetTranslation(ply_l_forearm_pos)

            bone_apply_matrix(self, ply_l_upperarm_index, ply_l_upperarm_matrix, ply_l_forearm_index)
            bone_apply_matrix(self, ply_l_forearm_index, ply_l_forearm_matrix, ply_l_hand_index)
            bone_apply_matrix(self, ply_l_hand_index, ply_l_hand_matrix)

            self:TPIK_UpdateHeadAndEye()
        end

        wm:DrawModel()
    end

    function meta:RemoveFWM()
        SafeRemoveEntity(self.FWMHands)
        local fwm = self:GetFWM()
        if IsValid(fwm) then
            for i = 0, 64 do
                fwm:SetSubMaterial(i, nil)
            end
        end
        SafeRemoveEntity(fwm)
        self.LastFWMwpn = nil
        local wpn = self:GetActiveWeapon()
        if IsValid(wpn) then
            wepstate(true, wpn)
        end
        if CLIENT then
            self._TPIK_AimFrac = 0
            self._TPIK_HeadTilt = 0
            if self.TPIK_ResetEyeFlex then
                self:TPIK_ResetEyeFlex(true)
            end
        end
    end

    function meta:DoFWM(wpn)
        if IsValid(self.LastFWMwpn) and self.LastFWMwpn != wpn then
            self:RemoveFWM()
            return
        end
        self.LastFWMwpn = wpn 
        self:CreateFakeWorldModel(wpn)
        if !self:GetFWM(true) then return end
        if IsValid(wpn) then
            local bool = self == LocalPlayer() and !LocalPlayer():ShouldDrawLocalPlayer()
            wepstate(bool, wpn)
        end
        self:UpdateBoneListWM()
        self:UpdateFakeWorldModel()
        self:UpdateFWMConnection()
        self:AnimSetGestureWeight(0, 0)
    end

    function meta:ShouldFWM(wpn)
        if not IsValid(wpn) then return false end
        
        if wpn.ShouldUseTPIK ~= nil then
            if not wpn.ShouldUseTPIK then
                return false
            end
        end
        
        local isHolstering = IsWeaponHolstering(wpn)
        local isReloading = IsWeaponReloading(wpn)
        local holdtypeDisabled = not (isHolstering or isReloading) and TPIKDisableHoldtypes[wpn:GetHoldType()]
        
        return tpik:GetBool() and (wpn and (wpn.IsTFAWeapon or wpn.TPIKForce) and !wpn.TPIKDisabled and !holdtypeDisabled) and (self:Alive() and !self:GetNoDraw() and self:GetSVAnim() == "") and (self:GetActiveWeapon() != wpn and EyePos():DistToSqr(wpn:GetPos()) < 1000000 or self:GetActiveWeapon() == wpn)
    end

    hook.Add("PrePlayerDraw", "UpdateFakeWorldModel", function(ply)
        local wpn = ply:GetActiveWeapon()
        if ply:ShouldFWM(wpn) then
            ply:DoFWM(wpn)
        else
            ply:RemoveFWM()
        end
    end)

    local oldvm = meta.GetViewModel
    function meta:GetViewModel()
        if LocalPlayer() == self then
            return oldvm(self)
        else
            return self:GetNW2Entity("FWM_Proxy")
        end
    end

    function meta:TPIK_IsAiming()
        local wpn = self:GetActiveWeapon()
        if not IsValid(wpn) then return false end
        local ht = wpn.GetHoldType and wpn:GetHoldType() or ""
        if ht == "fist" or ht == "melee" or ht == "passive" or ht == "normal" then return false end
        local aiming = false
        local ok, res

        if wpn.IsTFAWeapon and wpn.GetIronSightsProgress then
            aiming = wpn:GetIronSightsProgress() > 0.5
        end

        return aiming and true or false
    end

    function meta:TPIK_InitEyeFlex()
        if self._TPIK_FlexReady then return end
        self._TPIK_FlexReady = true
        self._TPIK_LeftFlex = nil
        local flexCount = self:GetFlexNum() or 0
        for i = 0, flexCount - 1 do
            local name = self:GetFlexName(i)
            if not isstring(name) then continue end
            local lname = string.lower(name)
            if not self._TPIK_LeftFlex and (lname:find("left_lid_closer")) then
                self._TPIK_LeftFlex = i
            end
        end
    end

    function meta:TPIK_SetEyeClose(amount)
        self:TPIK_InitEyeFlex()
        amount = math.Clamp(amount or 0, 0, 1)
        if self._TPIK_LeftFlex then
            self:SetFlexWeight(self._TPIK_LeftFlex, amount)
        end
    end

    function meta:TPIK_ResetEyeFlex(hard)
        self:TPIK_InitEyeFlex()
        if self._TPIK_LeftFlex then self:SetFlexWeight(self._TPIK_LeftFlex, 0) end
    end

    function meta:TPIK_UpdateHeadAndEye()
        local ads = self:TPIK_IsAiming()
        self._TPIK_AimFrac = self._TPIK_AimFrac or 0
        local target = ads and 1 or 0
        local rate = FrameTime() * 8
        self._TPIK_AimFrac = math.Clamp(self._TPIK_AimFrac + (target - self._TPIK_AimFrac) * rate, 0, 1)
        self:TPIK_SetEyeClose(self._TPIK_AimFrac)
        local head = self:LookupBone("ValveBiped.Bip01_Head1") or self:LookupBone("ValveBiped.Bip01_Head")
        if head then
            local m = self:GetBoneMatrix(head)
            if m then
            local ang = m:GetAngles()
            ang:RotateAroundAxis(ang:Up(), -10 * self._TPIK_AimFrac)
            ang:RotateAroundAxis(ang:Right(), 20 * self._TPIK_AimFrac)
            m:SetAngles(ang)
                self:SetBoneMatrix(head, m)
            end
        end
    end
else
    hook.Add("PlayerPostThink", "SyncFWMThink", function(ply)
        local vm = ply:GetViewModel()
        if not IsValid(vm) or !isstring(vm:GetModel()) then return end

        if not IsValid(ply.VMProxy) then
            local proxy = ents.Create("nz_tpik_viewmodel")
            proxy:SetModel(vm:GetModel() or "")
            proxy:SetParent(ply)
            proxy:Spawn()
            proxy:SetNotSolid(true)
            proxy:SetRenderMode(10)

            ply.VMProxy = proxy
        end

        local proxy = ply.VMProxy
        proxy:SetModel(vm:GetModel())
        proxy:ResetSequence(vm:GetSequence())
        proxy:SetCycle(vm:GetCycle())
        proxy:SetPlaybackRate(vm:GetPlaybackRate())
        proxy:SetSkin(vm:GetSkin())
        for i = 0, vm:GetNumBodyGroups() - 1 do
            proxy:SetBodygroup(i, vm:GetBodygroup(i))
        end
        ply:SetNW2Entity("FWM_Proxy", proxy)
    end)
end

local thefuckers = {
    ['tfa_bo3_paralyzer'] = true,
    ['tfa_bo2_jetgun'] = true,
    ['tfa_bo3_zapgun'] = true,
    ['tfa_perk_bottle'] = true,
    ['tfa_nz_gum'] = true,
    ['tfa_nz_bubble'] = true,
}

hook.Add("PreRegisterSWEP", "thefixer", function(self, class)
    if thefuckers[class] then
        self.ShouldUseTPIK = false
    end
end)