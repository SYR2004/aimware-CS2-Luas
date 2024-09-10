-- SYR1337
xpcall(function()
    assert(ffi, "bullet tracer error: ffi is not open, please open ffi")
    if not pcall(ffi.sizeof, "struct CParticleInformation") then
        ffi.cdef([[
            typedef struct Vector {
                float x, y, z;
            } Vector;
        
            typedef struct CBindingData {
                void* pData;
                uint64_t nUnknown;
                uint64_t nUnknown2;
                uint32_t* pRefCount;
            } CBindingData;
        
            typedef struct CStrongHandle {
                struct CBindingData* pBinding;
            } CStrongHandle;
        
            typedef struct CParticleColor {
                float r, g, b;
            } CParticleColor;
    
            typedef struct CParticleEffect {
                const char* szName;
                char pad_01[0x30];
            } CParticleEffect;
    
            typedef struct CParticleData {
                Vector* vecPositions;
                char pad_01[0x74];
                float* flTimes;
                char pad_02[0x28];
                float* flTimes2;
                char pad_03[0x98];
            } CParticleData;
        
            typedef struct CParticleInformation {
                float flTime;
                float flWidth;
                float flUnknown;
            } CParticleInformation;
        ]])
    end

    local pSettingsReference = gui.Reference("Visuals", "Other", "Effects")
    local pLocalEnabled = gui.Checkbox(pSettingsReference, "local.tracer", "Local Player Bullet Beams", false)
    local pLocalColor = gui.ColorPicker(pSettingsReference, "local.tracer.color", "Local Player Bullet Beams Color", 0, 255, 255, 255)
    local pLocalBeamWidth = gui.Slider(pSettingsReference, "local.tracer.width", "Local Player Bullet Beams Width", 0.1, 0, 2, 0.01)
    local pEnemyEnabled = gui.Checkbox(pSettingsReference, "enemy.tracer", "Enemies Bullet Beams", false)
    local pEnemyColor = gui.ColorPicker(pSettingsReference, "enemy.tracer.color", "Enemies Bullet Beams Color", 150, 130, 255, 255)
    local pEnemyBeamWidth = gui.Slider(pSettingsReference, "enemy.tracer.width", "Enemies Bullet Beams Width", 0.1, 0, 2, 0.01)
    local pTeammateEnabled = gui.Checkbox(pSettingsReference, "teammate.tracer", "Teammates Bullet Beams", false)
    local pTeammateColor = gui.ColorPicker(pSettingsReference, "teammate.tracer.color", "Teammates Bullet Beams Color", 65, 75, 200, 255)
    local pTeammateBeamWidth = gui.Slider(pSettingsReference, "teammate.tracer.width", "Teammates Bullet Beams Width", 0.1, 0, 2, 0.01)
    local pBeamTime = gui.Slider(pSettingsReference, "beam.tracer.time", "Beam Time", 4, 0.2, 5, 0.1)
    local IParticleManager = setmetatable({
        pPatricleManager = nil,
        ppPatricleManager = (function()
            local ppParticleManager = assert(mem.FindPattern("client.dll", "48 8B 05 ?? ?? ?? ?? 48 8B 08 48 8B 59 68"), "bullet tracer: not found patricle manager")
            return ffi.cast("void**", ppParticleManager + 7 + ffi.cast("int*", ppParticleManager + 3)[0])
        end)()
    }, {
        __index = {
            Get = function(this)
                return this.pPatricleManager
            end,

            Update = function(this)
                this.pPatricleManager = this.ppPatricleManager[0]
            end,

            IsValid = function(this)
                return this.pPatricleManager and this.ppPatricleManager and this.pPatricleManager ~= ffi.NULL and this.ppPatricleManager ~= ffi.NULL
            end,

            CallVFunc = function(this, nIndex, szType, ...)
                if not this:IsValid() then
                    return nil
                end

                local pVtable = ffi.cast("void***", this:Get())
                return ffi.cast(szType, pVtable[0][nIndex])(this:Get(), ...)
            end,

            CreateSnapshot = function(this, pSnapShotHandle)
                if not this:IsValid() then
                    return false
                end

                local pUtlStringData = ffi.new("int64_t[1]")
                this:CallVFunc(42, "void(__thiscall*)(void*, struct CStrongHandle*, int64_t*)", pSnapShotHandle, pUtlStringData)
                return true
            end,

            Draw = function(this, pSnapShotHandle, nCount, pEffectData)
                if not this:IsValid() then
                    return false
                end

                this:CallVFunc(43, "void(__thiscall*)(void*, struct CStrongHandle*, int, void*)", pSnapShotHandle, nCount, pEffectData)
                return true
            end
        }
    })

    local IGameParticleManager = setmetatable({
        pGameParticleManager = nil,
        fnSetEffectData = ffi.cast("void(__fastcall*)(void*, uint32_t, int, void*, int)", assert(mem.FindPattern("client.dll", "48 83 EC 58 F3 41 0F 10 51", "bullet tracer: not found create effect"))),
        fnCreateEffectIndex = ffi.cast("void(__fastcall*)(void*, uint32_t*, struct CParticleEffect*)", assert(mem.FindPattern("client.dll", "40 57 48 83 EC 20 49 8B ?? 48 8B"), "bullet tracer: not found create effect index")),
        fnCreateEffect2 = ffi.cast("void(__fastcall*)(void*, uint32_t*, const char*, int, int64_t, int64_t, int64_t, int)", assert(mem.FindPattern("client.dll", "4C 8B DC 53 48 83 EC 60 48 8B 84 24", "bullet tracer: not found create effect 2"))),
        fnInitEffect = ffi.cast("bool(__fastcall*)(void*, int, uint32_t, struct CStrongHandle*)", assert(mem.FindPattern("client.dll", "48 89 74 24 10 57 48 83 EC 30 4C 8B D9 49 8B F9 33 C9 41 8B F0 83 FA FF 0F"), "bullet tracer: not found init effect")),
        fnGetGameParticleManager = ffi.cast("void*(__fastcall*)()", assert(mem.FindPattern("client.dll", "48 8B ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 48 89 5C 24 10 57 48 81 EC 70 06 ?? ?? 48 8B 1D"), "bullet tracer: not found game particle manager"))
    }, {
        __index = {
            Get = function(this)
                return this.pGameParticleManager
            end,

            Update = function(this)
                this.pGameParticleManager = this.fnGetGameParticleManager()
            end,

            IsValid = function(this)
                return this.pGameParticleManager and this.pGameParticleManager ~= ffi.NULL
            end,

            CallVFunc = function(this, nIndex, szType, ...)
                if not this:IsValid() then
                    return nil
                end

                local pVtable = ffi.cast("void***", this:Get())
                return ffi.cast(szType, pVtable[0][nIndex])(...)
            end,

            CreateEffectIndex = function(this, pEffectIndex, pEffectData)
                if not this:IsValid() then
                    return
                end

                this.fnCreateEffectIndex(this:Get(), pEffectIndex, pEffectData)
            end,

            SetEffectData = function(this, nEffectIndex, nDataIndex, pData, nArg4)
                if not this:IsValid() then
                    return
                end

                this.fnSetEffectData(this:Get(), nEffectIndex, nDataIndex, pData, nArg4)
            end,

            CreateEffect = function(this, pEffectIndex, szName)
                if not this:IsValid() then
                    return
                end

                this.fnCreateEffect2(this:Get(), pEffectIndex, szName, 8, 0, 0, 0, 0)
            end,

            InitEffect = function(this, nEffectIndex, nUnknown, pSnapShotHandle)
                if not this:IsValid() then
                    return false
                end

                return this.fnInitEffect(this:Get(), nEffectIndex, nUnknown, pSnapShotHandle)
            end
        }
    })

    local szBeamMaterial = "particles/entity/spectator_utility_trail.vpcf"
    local function CreateBeamPoint(vecStart, vecEnd, clrColor, flTime, flWidth)
        local pEffectIndex = ffi.new("uint32_t[1]")
        local pBeamColor = ffi.new("struct CParticleColor[1]")
        for nIndex, szKey in pairs({ "r", "g", "b" }) do
            pBeamColor[0][szKey] = clrColor[szKey] or clrColor[nIndex] or 255
        end

        IParticleManager:Update()
        IGameParticleManager:Update()
        local vecDirection = (vecEnd - vecStart)
        local pEffectData = ffi.new("struct CParticleData[1]")
        local vecLinePointToEnd = vecStart + (vecDirection * 0.5)
        local vecCenterLinePoint = vecStart + (vecDirection * 0.3)
        local pSnapShotHandle = ffi.new("struct CStrongHandle[1]")
        IGameParticleManager:CreateEffect(pEffectIndex, szBeamMaterial)
        IGameParticleManager:SetEffectData(pEffectIndex[0], 16, pBeamColor, 0)
        local pParticleInformation = ffi.new("struct CParticleInformation[1]")
        pParticleInformation[0].flUnknown = 1
        pParticleInformation[0].flWidth = flWidth
        pParticleInformation[0].flTime = flTime or 4
        IGameParticleManager:SetEffectData(pEffectIndex[0], 3, pParticleInformation, 0)
        local vecStepPoints = { vecStart, vecCenterLinePoint, vecLinePointToEnd, vecEnd }
        for nIndex = 1, #vecStepPoints do
            pEffectData[0].flTimes = ffi.new(("float[%i]"):format(nIndex))
            pEffectData[0].vecPositions = ffi.new(("struct Vector[%i]"):format(nIndex))
            for nPointIndex = 1, nIndex do
                pEffectData[0].flTimes[nPointIndex - 1] = 0.015625 * nPointIndex
                for _, szKey in pairs({ "x", "y", "z" }) do
                    pEffectData[0].vecPositions[nPointIndex - 1][szKey] = vecStepPoints[nPointIndex][szKey]
                end
            end

            IParticleManager:CreateSnapshot(pSnapShotHandle)
            pEffectData[0].flTimes2 = pEffectData[0].flTimes
            IGameParticleManager:InitEffect(pEffectIndex[0], 0, pSnapShotHandle)
            IParticleManager:Draw(pSnapShotHandle, nIndex, pEffectData)
        end
    end

    local function OnHandleElements()
        pLocalColor:SetInvisible(not pLocalEnabled:GetValue())
        pEnemyColor:SetInvisible(not pEnemyEnabled:GetValue())
        pEnemyBeamWidth:SetInvisible(not pEnemyEnabled:GetValue())
        pLocalBeamWidth:SetInvisible(not pLocalEnabled:GetValue())
        pTeammateColor:SetInvisible(not pTeammateEnabled:GetValue())
        pTeammateBeamWidth:SetInvisible(not pTeammateEnabled:GetValue())
        pBeamTime:SetInvisible(not pLocalEnabled:GetValue() and not pEnemyEnabled:GetValue() and not pTeammateEnabled:GetValue())
    end

    local function OnFireGameEvent(pEvent)
        if pEvent:GetName() ~= "bullet_impact" then
            return
        end

        local pLocalPlayer = entities.GetLocalPlayer()
        local pUserController = entities.GetByIndex(pEvent:GetInt("userid") + 1)
        if not pUserController then
            return
        end

        local pPlayerPawn = pUserController:GetPropEntity("m_hPawn")
        if not pPlayerPawn then
            return
        end

        local flBeamTime = pBeamTime:GetValue()
        local vecOrigin = pPlayerPawn:GetAbsOrigin()
        local nTeamNumer = pLocalPlayer:GetTeamNumber()
        local nUserTeamNumer = pPlayerPawn:GetTeamNumber()
        local bTeammatesAreEnemy = client.GetConVar("mp_teammates_are_enemies")
        local vecEyePosition = vecOrigin + pPlayerPawn:GetPropVector("m_vecViewOffset")
        local vecEndPoint = Vector3(pEvent:GetFloat("x"), pEvent:GetFloat("y"), pEvent:GetFloat("z"))
        if pPlayerPawn:GetIndex() == pLocalPlayer:GetIndex() and pLocalEnabled:GetValue() then
            local clrColor = { pLocalColor:GetValue() }
            CreateBeamPoint(vecEyePosition, vecEndPoint, clrColor, flBeamTime, pLocalBeamWidth:GetValue())
        elseif (nTeamNumer ~= nUserTeamNumer or bTeammatesAreEnemy) and pEnemyEnabled:GetValue() then
            local clrColor = { pEnemyColor:GetValue() }
            CreateBeamPoint(vecEyePosition, vecEndPoint, clrColor, flBeamTime, pEnemyBeamWidth:GetValue())
        elseif nTeamNumer == nUserTeamNumer and not bTeammatesAreEnemy and pTeammateEnabled:GetValue() then
            local clrColor = { pTeammateColor:GetValue() }
            CreateBeamPoint(vecEyePosition, vecEndPoint, clrColor, flBeamTime, pTeammateBeamWidth:GetValue())
        end
    end

    callbacks.Register("Draw", OnHandleElements)
    callbacks.Register("FireGameEvent", OnFireGameEvent)
end, function(...)
    print(("[Bullet Impact]: initialize error -> %s"):format(...))
end)
