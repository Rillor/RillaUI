-- Define the bosses table
local bosses = { "Ulgrax", "Horror", "Sikran", "Rasha'nan", "Ovi'nax", "Ky'veza", "Court", "Ansurek" }

-- Initialize playersByBoss
if not playersByBoss then
    playersByBoss = {}
end

-- Create a container frame for the entire UI
local containerFrame = CreateFrame("Frame", "BossGroupManagerContainer", UIParent, "BackdropTemplate")
containerFrame:SetSize(220, 350) -- Adjusted size for better fit
containerFrame:SetPoint("CENTER")
containerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
})
containerFrame:SetBackdropColor(0, 0, 0, 0.8) -- Black background with 30% opacity
containerFrame:SetBackdropBorderColor(0, 0, 0) -- Black border

-- Enable dragging for the container frame
containerFrame:EnableMouse(true)
containerFrame:SetMovable(true)
containerFrame:RegisterForDrag("LeftButton")
containerFrame:SetScript("OnDragStart", containerFrame.StartMoving)
containerFrame:SetScript("OnDragStop", containerFrame.StopMovingOrSizing)

-- Create the main frame inside the container
local BossGroupManager = CreateFrame("Frame", "BossGroupManagerFrame", containerFrame)
BossGroupManager:SetSize(260, 330) -- Adjusted size for the new layout
BossGroupManager:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 10, -10) -- Adjust position for border

-- Container for the title and icon
local titleContainer = CreateFrame("Frame", nil, BossGroupManager)
titleContainer:SetSize(200, 40) -- Adjust size as needed
titleContainer:SetPoint("TOP", BossGroupManager, "TOP", 0, 0) -- Center the container and adjust position

-- Icon to the left of the title
local titleIcon = titleContainer:CreateTexture(nil, "OVERLAY")
titleIcon:SetSize(32, 32) -- Adjust size as needed
titleIcon:SetTexture("Interface\\AddOns\\RillaUI\\constantLogo.tga") -- Adjust path as needed
titleIcon:SetPoint("LEFT")

-- Title for the main frame
local title = titleContainer:CreateFontString("BossGroupManagerTitle", "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0) -- Position title to the right of the icon
title:SetText("|cFFFFFFFFSetup Manager|r")
title:SetFont("Fonts\\FRIZQT__.TTF", 16) -- Set font size to 14, no outline

local function customPrint(message,type)
    if type == "err" then
        print("|cffee5555" .. message .. "|r")
        elseif type == "success" then
        print("|cff55ee55" .. message .. "|r")
    end
end

-- Helper function: Get class color
local function GetClassColor(player)
    for i = 1, GetNumGroupMembers() do
        local unitName, _, _, _, classFileName = GetRaidRosterInfo(i)
        if unitName == player then
            local color = RAID_CLASS_COLORS[classFileName]
            return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, player)
        end
    end
    return player -- Default to white if not found
end

-- Function to print players missing from a specific boss setup
local function PrintMissingPlayers(boss)
    if not playersByBoss[boss] then
        return
    end

    local missingPlayers = {}
    for _, player in ipairs(playersByBoss[boss]) do
        player = player:match("^%s*(.-)%s*$") -- Trim spaces
        local found = false
        for i = 1, GetNumGroupMembers() do
            local unitName = GetRaidRosterInfo(i)
            if unitName == player then
                found = true
                break
            end
        end
        if not found then
            table.insert(missingPlayers, GetClassColor(player))
        end
    end
    if #missingPlayers > 0 then
        customPrint("\nPlayers missing from " .. boss .. " setup:|r\n" .. table.concat(missingPlayers, ", "), "err")
    else
        customPrint("All players are present for " .. boss .. " setup.|r", "success")
    end
end

-- Function to assign players to groups
local function AssignPlayersToGroups(boss)
    if not playersByBoss[boss] then
        customPrint("No Setup for " .. boss, "err")
        return
    end

    local players = playersByBoss[boss]
    local maxGroupMembers = 5

    local raidMembers = {}
    local unassignedPlayers = {}
    local assignedPlayers = {}
    local groupCounts = {}

    -- Initialize group counts
    for i = 1, 8 do
        groupCounts[i] = 0
    end

    -- Gather raid members and their current groups
    for i = 1, GetNumGroupMembers() do
        local unitName, _, subgroup = GetRaidRosterInfo(i) -- Corrected parameter position
        if subgroup and type(subgroup) == "number" then
            raidMembers[unitName] = { index = i, group = subgroup }
            groupCounts[subgroup] = groupCounts[subgroup] + 1
            if tContains(players, unitName) then
                assignedPlayers[unitName] = i
            else
                unassignedPlayers[unitName] = i
            end
        end
    end

    -- Move unassigned players out of groups 1-4 to groups 5-8
    for unitName, index in pairs(unassignedPlayers) do
        local currentGroup = raidMembers[unitName].group
        if currentGroup <= 4 then
            for newGroup = 5, 8 do
                if groupCounts[newGroup] < maxGroupMembers then
                    SetRaidSubgroup(index, newGroup)
                    groupCounts[newGroup] = groupCounts[newGroup] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                    break
                end
            end
        end
    end

    -- Move assigned players to groups 1-4
    for unitName, index in pairs(assignedPlayers) do
        local currentGroup = raidMembers[unitName].group
        if currentGroup > 4 then
            for newGroup = 1, 4 do
                if groupCounts[newGroup] < maxGroupMembers then
                    SetRaidSubgroup(index, newGroup)
                    groupCounts[newGroup] = groupCounts[newGroup] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                    break
                end
            end
        end
    end

    PrintMissingPlayers(boss)
end

-- Helper function: Splits a string by a delimiter
local function SplitString(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match:match("^%s*(.-)%s*$")) -- Trim spaces
    end
    return result
end

-- Function to update boss buttons
local function UpdateBossButtons()
    for _, child in ipairs({BossGroupManager:GetChildren()}) do
        if child:GetName() ~= "BossGroupManagerTitle" and child:GetName() ~= nil and not child:GetName():find("TitleIcon") then
            child:Hide() -- Hide old buttons
        end
    end

    -- Function to invite missing players
    local function InviteMissingPlayers(boss)
        local assignedPlayers = playersByBoss[boss]
        if not assignedPlayers then
            customPrint("No Setup for " .. boss, "err")
            return
        end
        DevTool:AddData(assignedPlayers)
        for _, player in ipairs(assignedPlayers) do
            local playerName = player:match("^%s*(.-)%s*$") -- Trim spaces
            local found = false
            for i = 1, GetNumGroupMembers() do
                local unitName = GetRaidRosterInfo(i)
                if unitName == playerName then
                    found = true
                    break
                end
            end
            if not found then
                C_PartyInfo.InviteUnit(playerName) -- Using C_PartyInfo.InviteUnit to invite the player
            end
        end
    end

    local buttonWidth = 120
    local buttonHeight = 30
    local xOffset = 10 -- Adjusted offset for centering
    local yOffset = -40 -- Start below the titleContainer
    local index = 0

    for _, boss in ipairs(bosses) do
        local button = CreateFrame("Button", "BossButton" .. index, BossGroupManager, "UIPanelButtonTemplate")
        button:SetSize(buttonWidth, buttonHeight)
        button:SetText(boss)
        button:SetPoint("TOPLEFT", xOffset, yOffset + (-1 * (buttonHeight + 5) * index)) -- Adjust vertical spacing
        button:SetNormalFontObject("GameFontHighlight")

        -- Create a texture and set it as the button's background
        local normalTexture = button:CreateTexture()
        normalTexture:SetAllPoints()
        normalTexture:SetColorTexture(0.11, 0.11, 0.11, 1) -- RGB values for #1c1c1c
        button:SetNormalTexture(normalTexture)

        -- Create a texture for hover and set it as the highlight texture
        local highlightTexture = button:CreateTexture()
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(0.3, 0.3, 0.3, 1) -- Brighter shade for hover
        button:SetHighlightTexture(highlightTexture)

        button:SetScript("OnClick", function()
            AssignPlayersToGroups(boss)
        end)
        button:Show()

        -- Create an invite button
        local inviteButton = CreateFrame("Button", "InviteButton" .. index, BossGroupManager, "UIPanelButtonTemplate")
        inviteButton:SetSize(buttonHeight, buttonHeight) -- Match height of other buttons
        inviteButton:SetPoint("LEFT", button, "RIGHT", 10, 0)
        inviteButton:SetNormalFontObject("GameFontHighlight")

        -- Set icon as the button's background
        local inviteNormalTexture = inviteButton:CreateTexture()
        inviteNormalTexture:SetAllPoints()
        inviteNormalTexture:SetTexture("Interface\\Icons\\inv_letter_15") -- Mail icon path
        inviteButton:SetNormalTexture(inviteNormalTexture)

        -- Create a texture for hover and set it as the highlight texture
        local inviteHighlightTexture = inviteButton:CreateTexture()
        inviteHighlightTexture:SetAllPoints()
        inviteHighlightTexture:SetColorTexture(0.3, 0.3, 0.3, 1) -- Brighter shade for hover
        inviteButton:SetHighlightTexture(inviteHighlightTexture)

        inviteButton:SetScript("OnClick", function()
            InviteMissingPlayers(boss)
        end)
        inviteButton:Show()

        index = index + 1
    end

    -- Adjust the main frame's height dynamically based on the number of buttons
    local baseHeight = 40 -- Reduced base height to minimize excess space
    local totalHeight = baseHeight + (buttonHeight + 5) * index
    BossGroupManager:SetHeight(totalHeight)

    -- Adjust the container frame's height to include the border
    containerFrame:SetHeight(totalHeight + 20) -- Add extra space for border
end

-- Slash command: Import players for a boss
local function ImportPlayers(input)
    local boss, players = input:match("^(.-);(.*)$")
    if not boss or not players then
        print("Invalid format. Use: /Rilla import [BossName];[Player1, Player2, Player3]")
        return
    end

    local playerList = SplitString(players, ":")
    for i, player in ipairs(playerList) do
        playerList[i] = player:match("^%s*(.-)%s*$") -- Trim spaces from player names
    end
    playersByBoss[boss] = playerList
    BossGroupManagerSaved.playersByBoss = playersByBoss -- Update saved variable

    print("Imported players for boss:", boss)
    UpdateBossButtons()
end

-- Slash command: Delete a boss
local function DeleteBoss(boss)
    if playersByBoss[boss] then
        playersByBoss[boss] = nil
        BossGroupManagerSaved.playersByBoss = playersByBoss -- Update saved variable
        print("Deleted boss:", boss)
        UpdateBossButtons()
    else
        print("Boss not found:", boss)
    end
end

-- Register events and set up event handler
BossGroupManager:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RillaUI" then
        if BossGroupManagerSaved == nil then
            BossGroupManagerSaved = {}
        end
        playersByBoss = BossGroupManagerSaved.playersByBoss or {}
        UpdateBossButtons()
    elseif event == "PLAYER_LOGOUT" then
        BossGroupManagerSaved.playersByBoss = playersByBoss
    end
end)
BossGroupManager:RegisterEvent("ADDON_LOADED")
BossGroupManager:RegisterEvent("PLAYER_LOGOUT")

-- Slash command handling
SLASH_RILLA1 = "/rilla"
SlashCmdList["RILLA"] = function(input)
    if not input or input == "" then
        BossGroupManager:Show()
        return
    end

    local command, data = input:match("^(%S+)%s*(.*)$")
    if command == "import" then
        ImportPlayers(data)
    elseif command == "delete" then
        DeleteBoss(data)
    elseif command == "toggle" then
        if containerFrame:IsShown() then
            containerFrame:Hide()
        else
            containerFrame:Show()
        end
    else
        print("Unknown command. Use /rilla import [BossName];[Players], /rilla delete [BossName], or /rilla toggle")
    end
end


-- Ensure UpdateBossButtons is called to initialize the buttons
UpdateBossButtons()

--[[
TODO: 0.1. create icon(?)
TODO: 0.2 add icon into wow
TODO: 1. add minimap icon
TODO: 2. add popup for longer string input (for all bosses)
TODO: 3. change logic for string splitting to be able to add multiple boss setups at once like 'Ulgrax;Rilla,Dogma,TestChar,Rompschwanß,[...]:Horror;Rilla,Dogma,Böggels,Drill,[...],
]]--
