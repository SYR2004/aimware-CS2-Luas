-- SYR1337
local IFileSystem = (function()
    local bLoadedBinrary, szLibraryBinrary = pcall(file.Read, "File System.lua")
    if not bLoadedBinrary then
        return nil
    end

    local bLoad, fnGetFileSystem = pcall(loadstring, szLibraryBinrary)
    if not bLoad then
        return nil
    end

    return  fnGetFileSystem()
end)()

assert(ffi, "example error: ffi is not open, please open ffi")
assert(IFileSystem, [[example error: IFileSystem is not loaded, please copy and put "File System.lua" inside aimware lua folder]])
local function FindSignature(pBase, nDataSize, arrSignature)
    local pData = ffi.cast("uint8_t*", pBase)
    for nIndex = 0, nDataSize do
        local bResolved = true
        for nSize = 1, #arrSignature do
            if pData[nIndex + nSize] ~= arrSignature[nSize] then
                bResolved = false
                break
            end
        end

        if bResolved then
            return ffi.cast("uintptr_t", pData + nIndex)
        end
    end

    return nil
end

local mtIcons = setmetatable({}, {
    __index = function(this, szIconName)
        local hFile = IFileSystem:Open(szIconName)
        if not hFile then
            return nil
        end

        local pSvgPosition = FindSignature(hFile:Read(), hFile:GetSize(), {
            0x3C, 0x3F, 0x78, 0x6D, 0x6C -- <?xml Signature
        })

        if not pSvgPosition then
            hFile:Close()
            return nil
        end

        local szSvgBinrary = ffi.cast("const char*", pSvgPosition + 1)
        local imgRGBA, imgWidth, imgHeight = common.RasterizeSVG(ffi.string(szSvgBinrary))
        hFile:Close()
        if imgWidth <= 0 or imgHeight <= 0 then
            return nil
        end

        this[szIconName] = {
            width = imgWidth,
            height = imgHeight,
            img = draw.CreateTexture(imgRGBA, imgWidth, imgHeight)
        }

        return this[szIconName]
    end
})

callbacks.Register("Draw", function()
    local arrIcon = mtIcons["panorama/images/icons/equipment/ak47.vsvg_c"]
    if not arrIcon then
        return
    end

    local ScreenPosition = { draw.GetScreenSize() }
    local vecCenterBoundBox = {
        (ScreenPosition[1] / 2) - (arrIcon.width / 2), (ScreenPosition[2] / 2) - (arrIcon.height / 2),
        (ScreenPosition[1] / 2) + (arrIcon.width / 2), (ScreenPosition[2] / 2) + (arrIcon.height / 2)
    }

    draw.SetTexture(arrIcon.img);
    draw.FilledRect(vecCenterBoundBox[1], vecCenterBoundBox[2], vecCenterBoundBox[3], vecCenterBoundBox[4])
end)
