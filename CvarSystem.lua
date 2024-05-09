-- SYR1337
assert(ffi, "cvar system error: ffi is not open, please open ffi")
if not pcall(ffi.sizeof, "struct CUtlLinkedList") then
    ffi.cdef([[
        void* GetProcAddress(uintptr_t, const char*);
        typedef void*(*fnCreateInterface)(const char*, void*);
        typedef struct Color {
            uint8_t r, g, b, a;
        } Color;

        typedef struct Vector2D {
            float x, y;
        } Vector2D;

        typedef struct Vector {
            float x, y, z;
        } Vector;

        typedef struct Vector4D {
            float x, y, z, w;
        } Vector4D;

        typedef struct CConCommand {
            const char* szName;
            const char* szHelpString;
            uint64_t nFlags;
            uint64_t nUnk1;
            uint64_t nUnk2;
            uint64_t nUnk3;
            uint64_t nUnk4;
        } CConCommand;

        typedef struct CConVar {
            const char* szName;
            struct CConVar* pNext;
            char pad_01[0x10];
            const char* szDescription;
            uint32_t nType;
            uint32_t nRegistered;
            uint32_t nFlags;
            uint32_t m_unk3;
            uint32_t m_nCallbacks;
            uint32_t m_unk4;
            union {
                bool Bool;
                short Int16;
                uint16_t Uint16;
                int Int;
                uint32_t Uint32;
                int64_t Int64;
                uint64_t Uint64;
                float Float;
                double Double;
                const char* String;
                struct Color Color;
                struct Vector2D Vector2D;
                struct Vector Vector3D;
                struct Vector4D Vector4D;
                struct Vector Angles;
            } Value;

            union {
                bool Bool;
                short Int16;
                uint16_t Uint16;
                int Int;
                uint32_t Uint32;
                int64_t Int64;
                uint64_t Uint64;
                float Float;
                double Double;
                const char* String;
                struct Color Color;
                struct Vector2D Vector2D;
                struct Vector Vector3D;
                struct Vector4D Vector4D;
                struct Vector Angles;
            } OldValue;
        } CConVar;

        typedef struct CUtlLinkedListElement {
            struct CConVar* element;
            uint16_t iPrevious;
            uint16_t iNext;
        } CUtlLinkedListElement;

        typedef struct CUtlMemory {
            struct CUtlLinkedListElement* pMemory;
            int nAllocationCount;
            int nGrowSize;
        } CUtlMemory;
        
        typedef struct CUtlLinkedList {
            struct CUtlMemory memory;
            uint16_t iHead;
            uint16_t iTail;
            uint16_t iFirstFree;
            uint16_t nElementCount;
            uint16_t nAllocated;
            struct CUtlLinkedListElement* pElements;
        } CUtlLinkedList;

        typedef struct IEngineCvar {
            char pad_01[0x40];
            struct CUtlLinkedList listCvars;
        } IEngineCvar;
    ]])
end

return setmetatable({
    IEngineCvar = setmetatable({
        IEngineCvar = ffi.cast("struct IEngineCvar*", ffi.cast("fnCreateInterface",
            ffi.C.GetProcAddress(mem.GetModuleBase("tier0.dll"), "CreateInterface")
        )("VEngineCvar007", nil))
    }, {
        __index = {
            Get = function(self)
                return self.IEngineCvar
            end,

            IsValid = function(self)
                return self.IEngineCvar ~= ffi.NULL
            end,

            GetCvars = function(self)
                if not self:IsValid() then
                    return {}
                end

                local arrCvars = {}
                local listCvar = self.IEngineCvar.listCvars
                for nIndex = 0, listCvar.memory.nAllocationCount - 1 do
                    local pConVar = listCvar.memory.pMemory[nIndex].element
                    if not pConVar then
                        goto continue
                    end

                    table.insert(arrCvars, pConVar)
                    ::continue::
                end

                return arrCvars
            end,

            FindCvar = function(self, szName)
                if not self:IsValid() then
                    return nil
                end

                for _, pConVar in pairs(self:GetCvars()) do
                    if szName == ffi.string(pConVar.szName) then
                        return pConVar
                    end
                end

                return nil
            end
        }
    })
}, {
    __index = function(self, szCvarName)
        local pConVar = self.IEngineCvar:FindCvar(szCvarName)
        if not pConVar then
            return nil
        end

        self[szCvarName] = setmetatable({
            pRawConvar = pConVar
        }, {
            __index = {
                int = function(this, nValue)
                    if nValue then
                        this.pRawConvar.Value.Int = nValue
                        return
                    end

                    return this.pRawConvar.Value.Int
                end,

                bool = function(this, bValue)
                    if bValue then
                        this.pRawConvar.Value.Bool = bValue
                        return
                    end

                    return this.pRawConvar.Value.Bool
                end,

                float = function(this, flValue)
                    if flValue then
                        this.pRawConvar.Value.Int = flValue
                        return
                    end

                    return this.pRawConvar.Value.Float
                end,

                string = function(this, szValue)
                    if szValue then
                        this.pRawConvar.Value.String = szValue
                        return
                    end

                    return ffi.string(this.pRawConvar.Value.String)
                end,
            }
        })

        return self[szCvarName]
    end
})
