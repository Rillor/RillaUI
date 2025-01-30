local _, RillaUI = ...

-- Define the bosses table
RillaUI.bosses = { "Ulgrax", "Horror", "Sikran", "Rasha'nan", "Ovi'nax", "Ky'veza", "Court", "Ansurek" }

-- Initialize playersByBoss
if not playersByBoss then
    playersByBoss = {}
end

local setupManager = RillaUI.setupManager

-- Create the main frame inside the container
RillaUI.BossGroupManager = CreateFrame("Frame", "BossGroupManagerFrame", setupManager)
RillaUI.BossGroupManager:SetSize(180, 330) -- Adjusted size for the new layout
RillaUI.BossGroupManager:SetPoint("TOPLEFT", setupManager, "TOPLEFT", 10, -10) -- Adjust position for border

-- Container for the title and icon
RillaUI.titleContainer = CreateFrame("Frame", nil, RillaUI.BossGroupManager)
RillaUI.titleContainer:SetSize(160, 40) -- Adjust size as needed
RillaUI.titleContainer:SetPoint("TOP", RillaUI.BossGroupManager, "TOP", 0, 0) -- Center the container and adjust position

-- Icon to the left of the title
local titleIcon = RillaUI.titleContainer:CreateTexture(nil, "OVERLAY")
titleIcon:SetSize(32, 32) -- Adjust size as needed
titleIcon:SetTexture("Interface\\AddOns\\RillaUI\\constantLogo.tga") -- Adjust path as needed
titleIcon:SetPoint("LEFT", 8, 0)

-- Title for the main frame
local title = RillaUI.titleContainer:CreateFontString("BossGroupManagerTitle", "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", titleIcon, "RIGHT") -- Position title to the right of the icon
title:SetText("|cFFFFFFFFSetup Manager|r")
title:SetFont("Fonts\\FRIZQT__.TTF", 16) -- Set font size to 14, no outline

-- Register events and set up event handler
RillaUI.BossGroupManager:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RillaUI" then
        if BossGroupManagerSaved == nil then
            BossGroupManagerSaved = {}
        end
        playersByBoss = BossGroupManagerSaved.playersByBoss or {}
        RillaUI:UpdateBossButtons()
    elseif event == "PLAYER_LOGOUT" then
        BossGroupManagerSaved.playersByBoss = playersByBoss
    end
end)
RillaUI.BossGroupManager:RegisterEvent("ADDON_LOADED")
RillaUI.BossGroupManager:RegisterEvent("PLAYER_LOGOUT")

-- Slash command handling
SLASH_RILLA1 = "/rilla"
SlashCmdList["RILLA"] = function(input)
    local command, data = input:match("^(%S+)%s*(.*)$")
    if command == "import" then
        RillaUI:ImportPlayers(data)
    elseif command == "delete" then
        RillaUI:DeleteBoss(data)
    elseif command == "toggle" then
        if setupManager:IsShown() then
            setupManager:Hide()
        else
            setupManager:Show()
        end
    elseif command == "s" then
        RillaUI:toggleImportDialog()
    elseif command == "clear" then
        RillaUI:ClearBosses()
    else
        print("Unknown command. Use /rilla import [BossName];[Players], /rilla delete [BossName], or /rilla toggle")
    end
end


-- Ensure UpdateBossButtons is called to initialize the buttons
RillaUI:UpdateBossButtons()
setupManager:Hide()

--[[

TODO:    ❌ implement slot preserveation IF slotInfo has been set with function -> table in each boss
TODO:    ❌ Add NorthernSky Nicknames (NS:API) to filtering and look for matches in currentGroup
]]--
