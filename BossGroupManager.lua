local BossGroupManager = CreateFrame("Frame", "BossGroupManagerFrame", UIParent)
local playersByBoss = {}
local bosses = {"Ulgrax", "Horror", "Sikran", "Rasha'nan", "Ovi'nax", "Ky'veza", "Court", "Ansurek"}

-- Initialize saved variables
BossGroupManager:SetScript("OnEvent", function(self, event, addonName)
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



-- Function to assign players to groups
local function AssignPlayersToGroups(boss)
    if not playersByBoss[boss] then
        print("No players found for boss:", boss)
        return
    end

    local players = playersByBoss[boss]
    local maxGroupMembers = 5

    local raidMembers = {}
    local assignedPlayers = {}
    local groupCounts = {}

    -- Initialize group counts
    for i = 1, 8 do
        groupCounts[i] = 0
    end

    -- Gather raid members and their current groups
    for i = 1, GetNumGroupMembers() do
        local unitName, rank, subgroup = GetRaidRosterInfo(i)
        raidMembers[unitName] = {index = i, group = subgroup}
        groupCounts[subgroup] = groupCounts[subgroup] + 1
        print("Raid member:", unitName, "Group:", subgroup)
    end

    -- Reassign players who are in the wrong group
    for _, player in ipairs(players) do
        player = player:match("^%s*(.-)%s*$") -- Trim spaces
        print("Assigning player:", player)

        if raidMembers[player] then
            local currentGroup = raidMembers[player].group
            if currentGroup > 4 or currentGroup == nil then
                local newGroup = 1
                while groupCounts[newGroup] >= maxGroupMembers and newGroup <= 4 do
                    newGroup = newGroup + 1
                end

                if newGroup > 4 then
                    print("Warning: All groups 1-4 are full, moving", player, "to group 5-8 later")
                else
                    SetRaidSubgroup(raidMembers[player].index, newGroup)
                    print("Assigned", player, "to group", newGroup)
                    assignedPlayers[player] = true -- Mark player as assigned
                    groupCounts[newGroup] = groupCounts[newGroup] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                end
            else
                print(player, "is already in the correct group", currentGroup)
                assignedPlayers[player] = true -- Mark player as assigned
            end
        else
            print("Player not found in raid:", player)
        end
    end

    -- Move unassigned players out of groups 1-4 and keep them in groups 5-8
    local unassignedGroup = 5
    for unitName, data in pairs(raidMembers) do
        if not assignedPlayers[unitName] then
            if data.group <= 4 then
                while groupCounts[unassignedGroup] >= maxGroupMembers and unassignedGroup <= 8 do
                    unassignedGroup = unassignedGroup + 1
                end

                if unassignedGroup > 8 then
                    print("Warning: More than 40 players, not assigning:", unitName)
                    return
                end

                SetRaidSubgroup(data.index, unassignedGroup)
                print("Moved unassigned player", unitName, "from group", data.group, "to group", unassignedGroup)
                groupCounts[unassignedGroup] = groupCounts[unassignedGroup] + 1
                groupCounts[data.group] = groupCounts[data.group] - 1
            else
                print("Unassigned player", unitName, "remains in group", data.group)
            end
        end
    end
end

-- Helper function: Splits a string by a delimiter
local function SplitString(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match:match("^%s*(.-)%s*$")) -- Trim spaces
    end
    return result
end

-- Helper function: Update Boss Buttons
local function UpdateBossButtons()
    for _, child in ipairs({BossGroupManager:GetChildren()}) do
        if child:GetName() ~= "BossGroupManagerTitle" then
            child:Hide() -- Hide old buttons
        end
    end

    local buttonWidth = 120
    local buttonHeight = 30
    local xOffset = 10
    local yOffset = -40 -- Start below the title
    local index = 0

    for _, boss in ipairs(bosses) do
        local button = CreateFrame("Button", "BossButton" .. index, BossGroupManager, "UIPanelButtonTemplate")
        button:SetSize(buttonWidth, buttonHeight)
        button:SetText(boss)
        button:SetPoint("TOPLEFT", xOffset, yOffset + (-1 * (buttonHeight + 5) * index)) -- Adjust vertical spacing
        button:SetNormalFontObject("GameFontHighlight")
        button:SetScript("OnClick", function()
            AssignPlayersToGroups(boss)
        end)
        button:Show()
        index = index + 1
    end

    -- Adjust the frame's height dynamically based on the number of buttons
    local baseHeight = 70 -- Title and padding
    local totalHeight = baseHeight + (buttonHeight + 5) * index
    BossGroupManager:SetHeight(totalHeight)
end

-- Slash command: Import players for a boss
local function ImportPlayers(input)
    local boss, players = input:match("^(.-);(.*)$")
    if not boss or not players then
        print("Invalid format. Use: /bgm import [BossName];[Player1, Player2, Player3]")
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

-- Slash command handling (same as before, no changes needed)
SLASH_BGM1 = "/bgm"
SlashCmdList["BGM"] = function(input)
    if not input or input == "" then
        BossGroupManager:Show()
        return
    end

    local command, data = input:match("^(%S+)%s*(.*)$")
    if command == "import" then
        ImportPlayers(data)
    elseif command == "delete" then
        DeleteBoss(data)
    else
        print("Unknown command. Use /bgm import [BossName];[Players] or /bgm delete [BossName]")
    end
end

-- Toggle visibility of Boss Group Manager window (same as before, no changes needed)
SLASH_BGMT1 = "/bgmtoggle"
SlashCmdList["BGMT"] = function()
    if BossGroupManager:IsShown() then
        BossGroupManager:Hide()
    else
        BossGroupManager:Show()
    end
end

-- Create a container frame for the entire UI
local containerFrame = CreateFrame("Frame", "BossGroupManagerContainer", UIParent, "BackdropTemplate")
containerFrame:SetSize(160, 70) -- Initial size (will be adjusted dynamically)
containerFrame:SetPoint("CENTER")
containerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
})
containerFrame:SetBackdropColor(0, 0, 0, 0.3) -- Black background with 30% opacity
containerFrame:SetBackdropBorderColor(0, 0, 0) -- Black border

-- Create the main frame inside the container
local BossGroupManager = CreateFrame("Frame", "BossGroupManagerFrame", containerFrame)
BossGroupManager:SetSize(150, 70) -- Initial size (will be adjusted dynamically)
BossGroupManager:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 5, -5) -- Adjust position for border

-- Enable dragging for the container frame
containerFrame:EnableMouse(true)
containerFrame:SetMovable(true)
containerFrame:RegisterForDrag("LeftButton")
containerFrame:SetScript("OnDragStart", containerFrame.StartMoving)
containerFrame:SetScript("OnDragStop", containerFrame.StopMovingOrSizing)

-- Title for the main frame
local title = BossGroupManager:CreateFontString("BossGroupManagerTitle", "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -10)
title:SetText("|cFFFFFFFFSetup Manager|r")
title:SetFont("Fonts\\FRIZQT__.TTF", 16) -- Set font size to 14, no outline

-- Function to update boss buttons
local function UpdateBossButtons()
    for _, child in ipairs({BossGroupManager:GetChildren()}) do
        if child:GetName() ~= "BossGroupManagerTitle" then
            child:Hide() -- Hide old buttons
        end
    end

    local buttonWidth = 120
    local buttonHeight = 30
    local xOffset = (BossGroupManager:GetWidth() - buttonWidth) / 2 -- Center the buttons
    local yOffset = -40 -- Start below the title
    local index = 0

    for _, boss in ipairs(bosses) do
        local button = CreateFrame("Button", "BossButton" .. index, BossGroupManager, "UIPanelButtonTemplate")
        button:SetSize(buttonWidth, buttonHeight)
        button:SetText(boss)
        button:SetPoint("TOPLEFT", xOffset, yOffset + (-1 * (buttonHeight + 5) * index)) -- Adjust vertical spacing
        button:SetNormalFontObject("GameFontHighlight")
        button:SetScript("OnClick", function()
            AssignPlayersToGroups(boss)
        end)
        button:Show()
        index = index + 1
    end

    -- Adjust the main frame's height dynamically based on the number of buttons
    local baseHeight = 40 -- Reduced base height to minimize excess space
    local totalHeight = baseHeight + (buttonHeight + 5) * index
    BossGroupManager:SetHeight(totalHeight)

    -- Adjust the container frame's height to include the border
    containerFrame:SetHeight(totalHeight + 20) -- Add extra space for border
end

-- Ensure UpdateBossButtons is called to initialize the buttons
UpdateBossButtons()




