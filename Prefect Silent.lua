-- SYR1337
xpcall(function()
    local IN_ATTACK = bit.lshift(1, 0)
    local angViewAngles = EulerAngles(0, 0, 0)
    local pRagebotReference = gui.Reference("Ragebot", "Aimbot", "Aiming Adjustment")
    local pRagebotToggleReference = gui.Reference("Ragebot", "Aimbot", "Toggle", "Aimbot")
    local pEnabled = gui.Checkbox(pRagebotReference, "aimbot.silent", "Prefect Silent", false)
    callbacks.Register("CreateMove", function(pUserCmd)
        if not gui.GetValue("rbot.master") or not pEnabled:GetValue() or pRagebotToggleReference:GetValue() == "Off" then
            return
        end

        local nButtons = pUserCmd:GetButtons()
        if bit.band(nButtons, IN_ATTACK) == 0 then
            angViewAngles = pUserCmd:GetViewAngles()
        else
            pUserCmd:SetViewAngles(angViewAngles)
        end
    end)

end, function(...)
    print(("[Prefect Silent]: initialize error -> %s"):format(...))
end)
