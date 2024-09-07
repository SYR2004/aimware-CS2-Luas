-- SYR1337 Editor 2024.9.7
xpcall(function()
    assert(ffi, "custom viewmodel error: ffi is not open, please open ffi")
    if not pcall(ffi.sizeof, "struct CViewSetup") then
        ffi.cdef([[
            typedef struct Vector {
                float x, y, z;
            } Vector;
        
            typedef struct CTraceRay {
                struct Vector vecStart;
                struct Vector vecEnd;
                struct Vector vecMins;
                struct Vector vecMaxs;
                char pad_01[0x5];
            } CTraceRay;

            typedef struct CTraceFilter {
                char pad_01[0x8];
                int64_t nTraceMask;
                int64_t arrUnknown[2];
                int32_t arrSkipHandles[4];
                int16_t arrCollisions[2];
                int16_t nUnknown2;
                uint8_t nUnknown3;
                uint8_t nUnknown4;
                uint8_t nUnknown5;
            } CTraceFilter;
        
            typedef struct Thread32Entry {
                uint32_t dwSize;
                uint32_t cntUsage;
                uint32_t th32ThreadID;
                uint32_t th32OwnerProcessID;
                long tpBasePri;
                long tpDeltaPri;
                uint32_t dwFlags;
            } Thread32Entry;
        
            typedef struct CViewRender {
                char pad_01[0x4E8];
                float flFov;
                float flFovViewmodel;
                struct Vector origin;
                char pad_03[0xC];
                struct Vector angles;
                char pad_04[0x14];
                float flAspectRatio;
                char pad_05[0x71];
                uint8_t nFlags;
            } CViewRender;
            
            typedef struct CGameTrace {
                void* pSurface;
                void* pHitEntity;
                void* pHitboxData;
                char pad_01[0x38];
                uint32_t nContents;
                char pad_02[0x24];
                struct Vector vecStart;
                struct Vector vecEnd;
                struct Vector vecNormal;
                struct Vector vecPosition;
                char pad_03[0x4];
                float flFraction;
                char pad_04[0x6];
                bool bStartSolid;
                char pad_05[0x4D];
            } CGameTrace;
        
            typedef struct CViewSetup {
                char pad_01[0x490];
                float flOrthoLeft;
                float flOrthoTop;
                float flOrthoRight;
                float flOrthoBottom;
                char pad_02[0x38];
                float flFov;
                float flFovViewmodel;
                struct Vector origin;
                char pad_03[0xC];
                struct Vector angles;
                char pad_04[0x14];
                float flAspectRatio;
            } CViewSetup;

            int CloseHandle(void*);
            uint32_t ResumeThread(void*);
            uint32_t GetCurrentThreadId();
            uint32_t SuspendThread(void*);
            uint32_t GetCurrentProcessId();
            void* OpenThread(uint32_t, int, uint32_t);
            void* GetProcAddress(uintptr_t, const char*);
            int Thread32Next(void*, struct Thread32Entry*);
            int Thread32First(void*, struct Thread32Entry*);
            void* CreateToolhelp32Snapshot(uint32_t, uint32_t);
            int VirtualProtect(void*, uint64_t, uint32_t, uint32_t*);
        ]])
    end

    local arrHooks = {}
    local bSetup = false
    local arrThreads = {}
    local flBackupAspectRatio = 0
    local bBackupAspectRatio = false
    local NULLPTR = ffi.cast("void*", 0)
    local vecCameraPosition = Vector3(0, 0, 0)
    local INVALID_HANDLE = ffi.cast("void*", - 1)

    local pVisualGroup = gui.Reference("Visuals")
    local pThirdPerson = gui.Reference("Visuals", "World", "Camera", "Third Person Enable")

    local pViewModelTab = gui.Tab(pVisualGroup, "ViewModel__Group", "View Model")
    local pViewModelGroup = gui.Groupbox(pViewModelTab, "Customized", 0, 0, 630, 200)
    gui.Text(pViewModelGroup, "Author: SYR1337")

    local pCustomViewModel = gui.Checkbox(pViewModelGroup, "__CustomViewModel", "Custom View Model", false)
    local pViewModelX = gui.Slider(pViewModelGroup, "__ViewModelX", "View Model X", 0, - 400, 400, 0.01)
    local pViewModelY = gui.Slider(pViewModelGroup, "__ViewModelY", "View Model Y", 0, - 400, 400, 0.01)
    local pViewModelZ = gui.Slider(pViewModelGroup, "__ViewModelZ", "View Model Z", 0, - 400, 400, 0.01)

    local pCustomFov = gui.Checkbox(pViewModelGroup, "__CustomFov", "Custom Fov", false)
    local pViewFov = gui.Slider(pViewModelGroup, "__ViewFov", "View Fov", 90, 0, 180, 0.01)
    local pViewModelFov = gui.Slider(pViewModelGroup, "__ViewModelFov", "View Model Fov", 90, 0, 180, 0.01)

    local pCustomAspectRatio = gui.Checkbox(pViewModelGroup, "__CustomAspectRatio", "Custom Aspect Ratio", false)
    local pAspectRatio = gui.Slider(pViewModelGroup, "__AspectRatio", "Aspect Ratio", 1.8, 0, 3, 0.01)

    local pSmoothCamera = gui.Checkbox(pViewModelGroup, "__SmoothCamera", "Enabled Smooth Camera", false)
    local pCameraSlack = gui.Slider(pViewModelGroup, "__SmoothCameraSlack", "Smooth Camera Slack", 40, 1, 100, 1)
    local pCameraVertical = gui.Slider(pViewModelGroup, "__SmoothCameraVertical", "Smooth Camera Vertical", 0, - 50, 50, 1)
    local pCameraHorizontal = gui.Slider(pViewModelGroup, "__SmoothCameraHorizontal", "Smooth Camera Horizontal", 0, - 30, 30, 1)
    local pCameraDistance = gui.Slider(pViewModelGroup, "__SmoothCameraDistance", "Smooth Camera Distance", 100, 32, 200, 1)

    local fnOverrideView = assert(mem.FindPattern("client.dll", "48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 41 56 41 57 48 83 EC ?? 48 8B FA E8"))
    local fnSetupView = assert(mem.FindPattern("client.dll", "48 89 5C ?? ?? 48 89 ?? ?? ?? 56 57 41 56 48 83 EC ?? 4C 8B F1 48 8D ?? 24 90"), "custom viewmodel error: outdated signature")
    local fnGetViewModel = assert(mem.FindPattern("client.dll", "48 89 5C 24 ?? 48 89 ?? ?? ?? 48 89 ?? ?? ?? 57 48 83 ?? ?? ?? 8B E8 48 8B DA 48 8B F1"), "custom viewmodel error: outdated signature")
    local fnGetClientEntity = ffi.cast("void*(__fastcall*)(void*, int)", assert(mem.FindPattern("client.dll", "81 FA ?? ?? ?? ?? 77 36 8B C2 C1 F8 09 83 F8 3F 77 2C 48 98"), "custom viewmodel error: outdated signature"))
    local fnCreateFilter = ffi.cast("void(__fastcall*)(struct CTraceFilter&, void*, uint64_t, uint8_t, uint16_t)", assert(mem.FindPattern("client.dll", "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 0F B6 41 37 33"), "custom viewmodel error: outdated signature"))
    local fnTraceShape = ffi.cast("bool(__fastcall*)(void*, struct CTraceRay*, struct Vector*, struct Vector*, struct CTraceFilter*, struct CGameTrace*)", assert(mem.FindPattern("client.dll", "48 89 5C 24 10 48 89 74 24 18 48 89 7C 24 20 48 89 4C 24 08 55 41 54 41 55 41 56 41 57 48 8D AC 24 20 E0 FF"), "custom viewmodel error: invalidate signature"))
    local IEngineTrace = (function()
        local pEngineTrace = assert(mem.FindPattern("client.dll", "4C 8B 3D 4B 41 57 01 24 C9 0C 49 66 0F 7F 45"), "custom viewmodel error: outdated signature")
        return ffi.cast("void**", pEngineTrace + 7 + ffi.cast("int*", pEngineTrace + 3)[0])[0]
    end)()

    local IGameEntitySystem = (function()
        local IGameResourceServiceClient = ffi.cast("void*(*)(const char*, void*)",
            ffi.C.GetProcAddress(mem.GetModuleBase("engine2.dll"), "CreateInterface")
        )("GameResourceServiceClientV001", nil)
        assert(IGameResourceServiceClient ~= ffi.NULL, "custom viewmodel error: outdated signature")
        return ffi.cast("void**", ffi.cast("uintptr_t", IGameResourceServiceClient) + 0x58)[0]
    end)()

    local function Lerp(flCurrent, flTarget, flPercentage)
        return flCurrent + ((flTarget - flCurrent) * flPercentage)
    end

    local function TraceShape(vecStart, vecEnd, pSkip)
        local vecFrom = ffi.new("struct Vector[1]")
        local vecFinal = ffi.new("struct Vector[1]")
        local pTraceRay = ffi.new("struct CTraceRay[1]")
        local pFilter = ffi.new("struct CTraceFilter[1]")
        local pGameTrace = ffi.cast("struct CGameTrace*", ffi.new("struct CGameTrace[1]"))
        fnCreateFilter(pFilter[0], pSkip and fnGetClientEntity(IGameEntitySystem, type(pSkip) == "number" and pSkip or pSkip:GetIndex()) or nil, 0x1C3003, 4, 7)
        for _, szKey in pairs({ "x", "y", "z" }) do
            vecFinal[0][szKey] = vecEnd[szKey]
            vecFrom[0][szKey] = vecStart[szKey]
        end

        fnTraceShape(IEngineTrace, pTraceRay, vecFrom, vecFinal, pFilter, pGameTrace)
        return pGameTrace
    end

    local function GetBaseHandle(pEntity)
        local pIdentity = ffi.cast("uintptr_t*", ffi.cast("uintptr_t", pEntity) + 0x10)[0]
        if pIdentity < 0x1000 or pIdentity > 0x7FFFFFFEFFFF then
            return nil
        end

        local nIndex = ffi.cast("uint32_t*", pIdentity + 0x10)[0]
        local nFlags = ffi.cast("uint32_t*", pIdentity + 0x30)[0]
        return bit.bor(bit.band(nIndex, 0x7FFF), bit.lshift(bit.rshift(nIndex, 15) - bit.band(nFlags, 1), 15))
    end

    local function TraceLineImpact(vecSource, vecDestination, pSkip)
        local pTrace = TraceShape(vecSource, vecDestination, pSkip)
        local vecImpact = Lerp(vecSource, vecDestination, pTrace.flFraction)
        return pTrace.flFraction, pTrace.pHitEntity, vecImpact
    end

    local function TraceLine(vecSource, vecDestination, fnSkipCallBack, nMaxTraces)
        local arrTraceData = {
            flFraction = 0,
            pTraceEntity = nil,
            nMaximizedIndex = 0,
            vecImpact = vecSource,
            nMaxTraced = nMaxTraces or 10
        }

        while (arrTraceData.nMaxTraced >= arrTraceData.nMaximizedIndex and arrTraceData.flFraction < 1 and ((arrTraceData.pTraceEntity and fnSkipCallBack(
            (function() return bit.band(GetBaseHandle(arrTraceData.pTraceEntity), 0x7FFF) end)()
        )) or arrTraceData.vecImpact == vecSource)) do
            local pEntity = arrTraceData.pTraceEntity ~= NULLPTR and bit.band(GetBaseHandle(arrTraceData.pTraceEntity), 0x7FFF) or nil
            local flFraction, pTraceEntity, vecImpact = TraceLineImpact(arrTraceData.vecImpact, vecDestination, pEntity)
            arrTraceData.flFraction, arrTraceData.pTraceEntity, arrTraceData.vecImpact, arrTraceData.nMaximizedIndex = flFraction, pTraceEntity, vecImpact, arrTraceData.nMaximizedIndex + 1
        end

        return (arrTraceData.vecImpact - vecSource):Length() / (vecDestination - vecSource):Length()
    end

    local function Thread(nTheardID)
        local hThread = ffi.C.OpenThread(0x0002, 0, nTheardID)
        if hThread == NULLPTR or hThread == INVALID_HANDLE then
            return false
        end

        return setmetatable({
            bValid = true,
            nId = nTheardID,
            hThread = hThread,
            bIsSuspended = false
        }, {
            __index = {
                Suspend = function(self)
                    if self.bIsSuspended or not self.bValid then
                        return false
                    end

                    if ffi.C.SuspendThread(self.hThread) ~= - 1 then
                        self.bIsSuspended = true
                        return true
                    end

                    return false
                end,

                Resume = function(self)
                    if not self.bIsSuspended or not self.bValid then
                        return false
                    end

                    if ffi.C.ResumeThread(self.hThread) ~= - 1 then
                        self.bIsSuspended = false
                        return true
                    end

                    return false
                end,

                Close = function(self)
                    if not self.bValid then
                        return
                    end

                    self:Resume()
                    self.bValid = false
                end
            }
        })
    end

    local function UpdateThreadList()
        arrThreads = {}
        local hSnapShot = ffi.C.CreateToolhelp32Snapshot(0x00000004, 0)
        if hSnapShot == INVALID_HANDLE then
            return false
        end

        local pThreadEntry = ffi.new("struct Thread32Entry[1]")
        pThreadEntry[0].dwSize = ffi.sizeof("struct Thread32Entry")
        if ffi.C.Thread32First(hSnapShot, pThreadEntry) == 0 then
            ffi.C.CloseHandle(hSnapShot);
            return false
        end

        local nCurrentThreadID = ffi.C.GetCurrentThreadId()
        local nCurrentProcessID = ffi.C.GetCurrentProcessId()
        while ffi.C.Thread32Next(hSnapShot, pThreadEntry) > 0 do
            if pThreadEntry[0].dwSize >= 20 and pThreadEntry[0].th32OwnerProcessID == nCurrentProcessID and pThreadEntry[0].th32ThreadID ~= nCurrentThreadID then
                local hThread = Thread(pThreadEntry[0].th32ThreadID)
                if not hThread then
                    for _, pThread in pairs(arrThreads) do
                        pThread:Close()
                    end

                    arrThreads = {}
                    ffi.C.CloseHandle(hSnapShot)
                    return false
                end

                table.insert(arrThreads, hThread)
            end
        end

        ffi.C.CloseHandle(hSnapShot)
        return true
    end

    local function SuspendThreads()
        if not UpdateThreadList() then
            return false
        end

        for _, hThread in pairs(arrThreads) do
            hThread:Suspend()
        end

        return true
    end

    local function ResumeThreads()
        for _, hThread in pairs(arrThreads) do
            hThread:Resume()
            hThread:Close()
        end
    end

    local function CreateHook(pTarget, pDetour, szType)
        assert(type(pDetour) == "function", "custom viewmodel error: invalid detour function")
        assert(type(pTarget) == "cdata" or type(pTarget) == "number" or type(pTarget) == "function", "custom viewmodel error: invalid target function")
        if not SuspendThreads() then
            print("custom viewmodel error: failed suspend threads")
            return false
        end

        local arrBackUp = ffi.new("uint8_t[14]")
        local pTargetFn = ffi.cast(szType, pTarget)
        local arrShellCode = ffi.new("uint8_t[14]", {
            0xFF, 0x25, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        })

        local __Object = {
            bValid = true,
            bAttached = false,
            pBackup = arrBackUp,
            pTarget = pTargetFn,
            pOldProtect = ffi.new("uint32_t[1]")
        }

        ffi.copy(arrBackUp, pTargetFn, ffi.sizeof(arrBackUp))
        ffi.cast("uintptr_t*", arrShellCode + 0x6)[0] = ffi.cast("uintptr_t", ffi.cast(szType, function(...)
            local bSuccessfully, pResult = pcall(pDetour, __Object, ...)
            if not bSuccessfully then
                __Object.bValid = false
                print(("[Custom Viewmodel]: runtime error -> %s"):format(pResult))
                return nil
            end

            return pResult
        end))

        __Object.__index = setmetatable(__Object, {
            __call = function(self, ...)
                if not self.bValid then
                    return nil
                end

                self:Detach()
                local bSuccessfully, pResult = pcall(self.pTarget, ...)
                if not bSuccessfully then
                    self.bValid = false
                    print(("[Custom Viewmodel]: runtime error -> %s"):format(pResult))
                    return nil
                end

                self:Attach()
                return pResult
            end,

            __index = {
                Attach = function(self)
                    if self.bAttached or not self.bValid then
                        return false
                    end

                    self.bAttached = true
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), 0x40, self.pOldProtect)
                    ffi.copy(self.pTarget, arrShellCode, ffi.sizeof(arrBackUp))
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), self.pOldProtect[0], self.pOldProtect)
                    return true
                end,

                Detach = function(self)
                    if not self.bAttached or not self.bValid then
                        return false
                    end

                    self.bAttached = false
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), 0x40, self.pOldProtect)
                    ffi.copy(self.pTarget, self.pBackup, ffi.sizeof(arrBackUp))
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), self.pOldProtect[0], self.pOldProtect)
                    return true
                end
            }
        })

        __Object:Attach()
        table.insert(arrHooks, __Object)
        ResumeThreads()
        return __Object
    end

    CreateHook(fnOverrideView, function(pObject, pClientMode, pViewSetup)
        local pResult = pObject(pClientMode, pViewSetup)
        if not pThirdPerson:GetValue() and pSmoothCamera:GetValue() then
            pViewSetup.origin.x = vecCameraPosition.x
            pViewSetup.origin.y = vecCameraPosition.y
            pViewSetup.origin.z = vecCameraPosition.z
        end

        return pResult
    end, "void*(__fastcall*)(void*, struct CViewSetup*)")

    CreateHook(fnSetupView, function(pObject, pViewRender)
        local pResult = pObject(pViewRender)
        if pCustomFov:GetValue() then
            pViewRender.flFov = pViewFov:GetValue()
            pViewRender.flFovViewmodel = pViewModelFov:GetValue()
        end

        if pCustomAspectRatio:GetValue() then
            if not bBackupAspectRatio then
                bBackupAspectRatio = true
                flBackupAspectRatio = pViewRender.flAspectRatio
            end

            pViewRender.nFlags = bit.bor(pViewRender.nFlags, 2)
            pViewRender.flAspectRatio = pAspectRatio:GetValue()
        elseif bBackupAspectRatio then
            bBackupAspectRatio = false
            pViewRender.flAspectRatio = flBackupAspectRatio
            pViewRender.nFlags = bit.bor(pViewRender.nFlags, 2)
        end

        return pResult
    end, "void*(__fastcall*)(struct CViewRender*)")

    CreateHook(fnGetViewModel, function(pObject, pRcx, vecOffset, pFov)
        local pResult = pObject(pRcx, vecOffset, pFov)
        if pCustomViewModel:GetValue() then
            vecOffset[0] = pViewModelX:GetValue() / 10
            vecOffset[1] = pViewModelY:GetValue() / 10
            vecOffset[2] = pViewModelZ:GetValue() / 10
        end

        return pResult
    end, "void*(__fastcall*)(void*, float*, float*)")

    callbacks.Register("Draw", function()
        local pLocalPlayer = entities.GetLocalPlayer()
        pViewFov:SetInvisible(not pCustomFov:GetValue())
        pViewModelFov:SetInvisible(not pCustomFov:GetValue())
        pCameraSlack:SetInvisible(not pSmoothCamera:GetValue())
        pViewModelX:SetInvisible(not pCustomViewModel:GetValue())
        pViewModelY:SetInvisible(not pCustomViewModel:GetValue())
        pViewModelZ:SetInvisible(not pCustomViewModel:GetValue())
        pCameraDistance:SetInvisible(not pSmoothCamera:GetValue())
        pCameraVertical:SetInvisible(not pSmoothCamera:GetValue())
        pCameraHorizontal:SetInvisible(not pSmoothCamera:GetValue())
        pAspectRatio:SetInvisible(not pCustomAspectRatio:GetValue())
        if not pLocalPlayer or not pLocalPlayer:IsAlive() or not pSmoothCamera:GetValue() then
            bSetup = false
            return
        end

        local flSlack = pCameraSlack:GetValue()
        local flDistance = pCameraDistance:GetValue()
        local vecCameraAnlges = engine:GetViewAngles()
        local flVerticalOffset = pCameraVertical:GetValue()
        local flHorizontalOffset = pCameraHorizontal:GetValue()
        local vecEyePosition = pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset")
        local vecForward, vecRight, vecUp = vecCameraAnlges:Forward(), vecCameraAnlges:Right(), vecCameraAnlges:Up()
        local vecDelta = (- vecForward * flDistance) + (vecRight * flHorizontalOffset) + (vecUp * flVerticalOffset)
        if not bSetup then
            bSetup = true
            vecCameraPosition = vecEyePosition
        end

        local flFraction = TraceLine(vecEyePosition, vecEyePosition + vecDelta, function(nEntIndex)
            return nEntIndex > 0 and nEntIndex <= 64
        end, 64)

        vecCameraPosition = vecCameraPosition + ((vecEyePosition + vecDelta * (flFraction * 0.8)) - vecCameraPosition) * (flSlack * 0.001)
    end)

    callbacks.Register("Unload", function() for _, pObject in pairs(arrHooks) do pObject:Detach() end end)
end, function(...)
    print(("[Custom Viewmodel]: initialize error -> %s"):format(...))
end)