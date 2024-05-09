-- SYR1337
assert(ffi, "filesystem error: ffi is not open, please open ffi")
ffi.cdef([[
    void* GetProcAddress(uintptr_t, const char*);
    typedef void*(*fnCreateInterface)(const char*, void*);
]])

return setmetatable({
    IFileSystem = ffi.cast("fnCreateInterface",
        ffi.C.GetProcAddress(mem.GetModuleBase("filesystem_stdio.dll"), "CreateInterface")
    )("VFileSystem017", nil)
}, {
    __index = {
        Get = function(this)
            return this.IFileSystem
        end,

        IsValid = function(this)
            return this.IFileSystem ~= ffi.NULL
        end,

        CallVFunc = function(this, nIndex, szType, ...)
            if not this:IsValid() then
                return nil
            end

            local pVtable = ffi.cast("void***", this:Get())[0]
            return ffi.cast(szType, pVtable[nIndex])(this:Get(), ...)
        end,

        Open = function(this, szFileName, szOptions, szPathId)
            if not this:IsValid() then
                return nil
            end

            local hFile = this:CallVFunc(78, "void*(__thiscall*)(void*, const char*, const char*, int, const char*)", szFileName, szOptions or "r", 0, szPathId or "game")
            if not hFile or hFile == ffi.NULL then
                print(("filesystem error: failed open file: %s"):format(szFileName))
                return nil
            end

            return setmetatable({
                hFile = hFile,
                bAvailable = true
            }, {
                __index = {
                    Get = function(self)
                        if not self.bAvailable then
                            print(("filesystem error: failed get file: %s, file already close"):format(szFileName))
                            return nil
                        end

                        return self.hFile
                    end,

                    GetSize = function(self)
                        if not self.bAvailable then
                            print(("filesystem error: failed get file size: %s, file already close"):format(szFileName))
                            return nil
                        end

                        return this:CallVFunc(18, "uint32_t(__thiscall*)(void*, void*)", self:Get())
                    end,

                    Read = function(self, nSize)
                        if not self.bAvailable then
                            print(("filesystem error: failed read file: %s, file already close"):format(szFileName))
                            return nil
                        end

                        if nSize and type(nSize) ~= "number" then
                            print(("filesystem error: failed read file: %s, wrong file size"):format(szFileName))
                            return nil
                        end

                        local nReadSize = nSize or self:GetSize()
                        local pBuffer = ffi.new(("uint8_t[%s]"):format(nReadSize))
                        local nReadedSize = this:CallVFunc(79, "int32_t(__thiscall*)(void*, void*, uint32_t, uint32_t, void*)", pBuffer, nReadSize, nReadSize, self:Get())
                        if nReadedSize < nReadSize then
                            print(("filesystem error: failed read file: %s, readed: %s, need: %s"):format(szFileName, nReadedSize, nReadSize))
                            return nil
                        end

                        return pBuffer
                    end,

                    Close = function(self)
                        if not self.bAvailable then
                            return
                        end

                        this:CallVFunc(14, "void(__thiscall*)(void*, void*)", self:Get())
                        self.bAvailable = false
                    end
                }
            })
        end
    }
})
