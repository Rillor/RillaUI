local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if (event == "PLAYER_LOGIN") then
        UIParent:SetScale(768 / select(2, GetPhysicalScreenSize()))
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
