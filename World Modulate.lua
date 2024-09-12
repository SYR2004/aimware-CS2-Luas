-- SYR1337
xpcall(function()
    assert(ffi, "world modulate error: ffi is not open, please open ffi")
    if not pcall(ffi.sizeof, "struct CMaterialResources") then
        ffi.cdef([[
            void* GetProcAddress(uintptr_t, const char*);
            typedef struct Vector4D {
                float x, y, z, w;
            } Vector4D;

            typedef struct CMaterialResources {
                uint64_t nSize;
                void*** arrMaterials;
                char pad[0x18];
            } CMaterialResources;
            
            typedef struct CMaterialParameter {
                struct Vector4D vecValue;
                void* pTextureValue;
                char pad_01[0x10];
                const char* szParameterName;
                const char* szValue;
                int64_t nValue;
            } CMaterialParameter;
        ]])
    end

    local arrMaterials = {}
    local szLastMapName = ""
    local bUpdateWorld = false
    local bStoredWorld = false
    local bUpdateLights = false
    local clrWorldModulation = {}
    local bUpdateMaterials = false
    local bUpdateRemoveLights = false
    local NULLPTR = ffi.cast("void*", 0)

    local pSettingsReference = gui.Reference("Visuals", "Other", "Effects")
    local pRemoveLights = gui.Checkbox(pSettingsReference, "__RemoveLights", "Remove Lights", false)
    local pWorldModulate = gui.Checkbox(pSettingsReference, "__WorldModulate", "World Modulate", false)
    local pWorldColor = gui.ColorPicker(pSettingsReference, "__WorldModulateColor", "World Color", 255, 255, 255, 255)

    local fnUpdateParameter = ffi.cast("struct CMaterialParameter*(__fastcall*)(void*)", assert(mem.FindPattern("materialsystem2.dll", "40 56 41 54 48 83 EC 28 0F B7 81 F2 03 ?? ?? 66"), "world modulate error: invalidate signature"))
    local fnFindParameter = ffi.cast("struct CMaterialParameter*(__fastcall*)(void*, const char*)", assert(mem.FindPattern("materialsystem2.dll", "48 89 5C 24 ?? 48 89 74 24 ?? 57 48 83 EC 20 48 8B 59 18"), "world modulate error: invalidate signature"))
    local IResourceSystem = ffi.cast("void*(*)(const char*, void*)",
        ffi.C.GetProcAddress(mem.GetModuleBase("resourcesystem.dll"), "CreateInterface")
    )("ResourceSystem013", nil)
    local function CallVFunc(pInterface, nIndex, szType, ...)
        local pVtable = ffi.cast("void***", pInterface)[0]
        return ffi.cast(szType, pVtable[nIndex])(pInterface, ...)
    end

    local function CMaterial(ppMaterial)
        assert(ppMaterial ~= NULLPTR and ppMaterial[0] ~= NULLPTR, "invalid material")
        return setmetatable({
            bOverride = false,
            clrBackupColor = {},
            bOverrideColor = false,
            ppMaterial = ppMaterial,
            pMaterial = ppMaterial[0],
            szName = ffi.string(CallVFunc(ppMaterial[0], 0, "const char*(__thiscall*)(void*)")),
        }, {
            __index = {
                Get = function(self)
                    return self.pMaterial
                end,

                IsValid = function(self)
                    return self.pMaterial ~= NULLPTR
                end,

                GetName = function(self)
                    if not self:IsValid() then
                        return "invalid material"
                    end

                    return self.szName
                end,
--[[
                Override = function(self, pMaterial)
                    if not self:IsValid() or pMaterial == self.pMaterial or pMaterial == NULLPTR then
                        return false
                    end

                    if type(pMaterial) == "table" and pMaterial.pMaterial then
                        if pMaterial.pMaterial == pMaterial or pMaterial.pMaterial == NULLPTR then
                            return
                        end

                        pMaterial = pMaterial.pMaterial
                    end

                    self.bOverride = true
                    self.ppMaterial[0] = pMaterial
                    return true
                end,
]]
                ColorModulate = function(self, clrColor)
                    if not self:IsValid() then
                        return false
                    end

                    local pParameter = self:FindParameter("g_vColorTint")
                    if not pParameter or pParameter == NULLPTR then
                        return false
                    end

                    if not clrColor then
                        return {
                            pParameter.vecValue.x, pParameter.vecValue.y, pParameter.vecValue.z, pParameter.vecValue.w
                        }
                    end

                    if not self.bOverrideColor then
                        self.bOverrideColor = true
                        self.clrBackupColor[1] = pParameter.vecValue.x
                        self.clrBackupColor[2] = pParameter.vecValue.y
                        self.clrBackupColor[3] = pParameter.vecValue.z
                        self.clrBackupColor[4] = pParameter.vecValue.w
                    end

                    pParameter.vecValue.x = clrColor.r or clrColor[1] or pParameter.vecValue.x
                    pParameter.vecValue.y = clrColor.g or clrColor[2] or pParameter.vecValue.y
                    pParameter.vecValue.z = clrColor.b or clrColor[3] or pParameter.vecValue.b
                    pParameter.vecValue.w = clrColor.a or clrColor[4] or pParameter.vecValue.w
                    self:UpdateParameter()
                end,

                FindParameter = function(self, szParameter)
                    if not self:IsValid() then
                        return nil
                    end

                    return fnFindParameter(self:Get(), szParameter)
                end,

                UpdateParameter = function(self)
                    if not self:IsValid() then
                        return nil
                    end

                    return fnUpdateParameter(self:Get())
                end,

                Reset = function(self)
                    if not self:IsValid() then
                        return
                    end

                    if self.bOverride then
                        self.bOverride = false
                        self.ppMaterial[0] = self.pMaterial
                    end

                    if self.bOverrideColor then
                        self:ColorModulate(self.clrBackupColor)
                        self.bOverrideColor = false
                    end
                end
            }
        })
    end

    local function EnumerateMaterials()
        arrMaterials = {}
        local pResources = ffi.new("struct CMaterialResources[1]")
        CallVFunc(IResourceSystem, 38, "void(__thiscall*)(void*, uint64_t, struct CMaterialResources*, uint8_t)", 0x74616D76ULL, pResources, 2)
        for nIndex = 0, tonumber(pResources[0].nSize) - 1 do
            local pMaterial = pResources[0].arrMaterials[nIndex]
            if pMaterial ~= NULLPTR then
                table.insert(arrMaterials, CMaterial(pMaterial))
            end
        end
    end

    local function OverrideWorld(clrColor)
        for _, pMaterial in pairs(arrMaterials) do
            local szName = pMaterial:GetName()
            if szName:find("weapons/") or szName:find("models/tm") or szName:find("models/ctm") or szName:find("characters/models") then
                goto continue
            end

            pMaterial:ColorModulate(clrColor)
            ::continue::
        end
    end

    EnumerateMaterials()
    callbacks.Register("Draw", function()
        local bRemoveLights = pRemoveLights:GetValue()
        local pLocalPlayer = entities.GetLocalPlayer()
        local bOverrideWorld = pWorldModulate:GetValue()
        pWorldColor:SetInvisible(not bOverrideWorld)
        if not pLocalPlayer then
            bUpdateMaterials = true
            return
        end

        local szMapName = engine.GetMapName()
        if not szMapName then
            return
        end

        if szLastMapName ~= szMapName then
            EnumerateMaterials()
            bUpdateMaterials = true
            szLastMapName = szMapName
            return
        end

        if bUpdateMaterials then
            bUpdateLights = true
            bUpdateMaterials = false
            return
        end

        if bUpdateLights or bUpdateRemoveLights ~= bRemoveLights then
            bUpdateLights = false
            bUpdateRemoveLights = bRemoveLights
            client.SetConVar("lb_enable_lights", not bRemoveLights)
        end

        local clrWorld = { pWorldColor:GetValue() }
        for nIndex, flValue in pairs(clrWorld) do
            local flPercentage = flValue / 255
            if clrWorldModulation[nIndex] ~= flPercentage then
                bUpdateWorld = true
                clrWorldModulation[nIndex] = flPercentage
            end
        end

        if bOverrideWorld and bUpdateWorld then
            bStoredWorld = true
            bUpdateWorld = false
            OverrideWorld(clrWorldModulation)
        elseif not bOverrideWorld then
            bUpdateWorld = true
            if bStoredWorld then
                bStoredWorld = false
                OverrideWorld({ 1, 1, 1, 1 })
            end
        end
    end)

    callbacks.Register("Unload", function()
        client.SetConVar("lb_enable_lights", true)
        for _, pMaterial in pairs(arrMaterials) do
            pMaterial:Reset()
        end
    end)

end, function(...)
    print(("[World Modulate]: initialize error -> %s"):format(...))
end)
