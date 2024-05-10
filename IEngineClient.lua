-- SYR1337
assert(ffi, "engine client error: ffi is not open, please open ffi")
ffi.cdef([[
    void* GetProcAddress(uintptr_t, const char*);
    typedef void*(*fnCreateInterface)(const char*, void*);
]])

return setmetatable({
    IEngineClient = ffi.cast("fnCreateInterface",
        ffi.C.GetProcAddress(mem.GetModuleBase("engine2.dll"), "CreateInterface")
    )("Source2EngineToClient001", nil)
}, {
    __index = {
        Get = function(self)
            return self.IEngineClient
        end,

        IsValid = function(self)
            return self.IEngineClient ~= ffi.NULL
        end,

        CallVFunc = function(self, nIndex, szType, ...)
            if not self:IsValid() then
                return nil
            end

            local pVtable = ffi.cast("void***", self:Get())[0]
            return ffi.cast(szType, pVtable[nIndex])(self:Get(), ...)
        end,

        GetMaxClients = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(34, "int(__thiscall*)(void*)")
        end,

        IsInGame = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(35, "bool(__thiscall*)(void*)")
        end,

        IsConnected = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(36, "bool(__thiscall*)(void*)")
        end,

        GetNetChannel = function(self, nSlot)
            if not self:IsValid() then
                return nil
            end

            return setmetatable({
                pNetChannel = self:CallVFunc(37, "void*(__thiscall*)(void*, int)", nSlot)
            }, {
                __index = {
                    Get = function(this)
                        return this.pNetChannel
                    end,

                    IsValid = function(this)
                        return this.pNetChannel ~= ffi.NULL
                    end,

                    CallVFunc = function(this, nIndex, szType, ...)
                        if not this:IsValid() then
                            return nil
                        end

                        local pVtable = ffi.cast("void***", this:Get())[0]
                        return ffi.cast(szType, pVtable[nIndex])(this:Get(), ...)
                    end,

                    GetName = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return ffi.string(this:CallVFunc(0, "const char*(__thiscall*)(void*)"))
                    end,

                    GetAddress = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return ffi.string(this:CallVFunc(1, "const char*(__thiscall*)(void*)"))
                    end,

                    GetTime = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(2, "float(__thiscall*)(void*)")
                    end,

                    GetTimeConnected = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(3, "float(__thiscall*)(void*)")
                    end,

                    GetBufferSize = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(4, "int(__thiscall*)(void*)")
                    end,

                    GetDataRate = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(5, "int(__thiscall*)(void*)")
                    end,

                    IsLocalHost = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(6, "bool(__thiscall*)(void*)")
                    end,

                    IsLoopback = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(7, "bool(__thiscall*)(void*)")
                    end,

                    IsTimingOut = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(8, "bool(__thiscall*)(void*)")
                    end,

                    IsPlayback = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(9, "bool(__thiscall*)(void*)")
                    end,

                    GetAvgLatency = function(this, nFlowID)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(11, "float(__thiscall*)(void*, int)", nFlowID)
                    end,

                    GetSequenceNr = function(this, nFlowID)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(19, "int(__thiscall*)(void*, int)", nFlowID)
                    end,

                    IsValidPacket = function(this, nSequence, nBytes)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(20, "bool(__thiscall*)(void*, int, int)", nSequence, nBytes)
                    end,

                    GetPacketTime = function(this, nSequence, nBytes)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(21, "float(__thiscall*)(void*, int, int)", nSequence, nBytes)
                    end,

                    GetTimeoutSeconds = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(27, "float(__thiscall*)(void*)")
                    end,

                    ResetLatencyStats = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(29, "void(__thiscall*)(void*)")
                    end,

                    GetTotalPacketBytes = function(this, nFlowID, nSequence)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(42, "int(__thiscall*)(void*, int, int)", nFlowID, nSequence)
                    end,

                    GetTotalPacketReliableBytes = function(this, nFlowID, nSequence)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(43, "int(__thiscall*)(void*, int, int)", nFlowID, nSequence)
                    end,

                    GetTotalPacketSomething = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(44, "int(__thiscall*)(void*)")
                    end,

                    SetTimeout = function(this, flTime, bState)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(63, "void(__thiscall*)(void*, float, bool)", flTime, bState)
                    end,

                    IsTimedOut = function(this)
                        if not this:IsValid() then
                            return nil
                        end

                        return this:CallVFunc(64, "bool(__thiscall*)(void*)")
                    end
                }
            })
        end,

        GetLocalPlayer = function(self)
            if not self:IsValid() then
                return nil
            end

            local pIndex = ffi.new("int[1]", - 1)
            self:CallVFunc(47, "void(__thiscall*)(void*, int*, int)", pIndex, 0)
            return pIndex[0] + 1
        end,

        GetLevelName = function(self)
            if not self:IsValid() then
                return nil
            end

            return ffi.string(self:CallVFunc(56, "const char*(__thiscall*)(void*)"))
        end,

        GetLevelNameShort = function(self)
            if not self:IsValid() then
                return nil
            end

            return ffi.string(self:CallVFunc(57, "const char*(__thiscall*)(void*)"))
        end,

        GetScreenAspectRatio = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(79, "float(__thiscall*)(void*)")
        end,

        GetEngineBuildNumber = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(80, "int(__thiscall*)(void*)")
        end,

        GetProductVersionString = function(self)
            if not self:IsValid() then
                return nil
            end

            return ffi.string(self:CallVFunc(81, "const char*(__thiscall*)(void*)"))
        end,

        GetAppId = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(82, "int(__thiscall*)(void*)")
        end,

        IsLowViolence = function(self)
            if not self:IsValid() then
                return nil
            end

            return self:CallVFunc(166, "bool(__thiscall*)(void*)")
        end,
    }
})
