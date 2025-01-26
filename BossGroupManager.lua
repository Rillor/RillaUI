local BossGroupManager = CreateFrame("Frame", "BossGroupManagerFrame", UIParent)
local playersByBoss = {}
local bosses = {"Ulgrax", "Horror", "Sikran", "Rasha'nan", "Ovi'nax", "Ky'veza", "Court", "Ansurek"}

-- Function to assign players to groups
local function AssignPlayersToGroups(boss)
    if not playersByBoss[boss] then
        print("No players found for boss:", boss)
        return
    end

    local players = playersByBoss[boss]
    local group = 1
    local playerIndex = 1
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

    -- Assign players to groups 1-4
    for _, player in ipairs(players) do
        player = player:match("^%s*(.-)%s*$") -- Trim spaces
        print("Assigning player:", player)

        if group > 4 then
            print("Warning: More than 20 players, not assigning:", player)
            return
        end

        if raidMembers[player] then
            local currentGroup = raidMembers[player].group
            if currentGroup ~= group then
                if groupCounts[group] < maxGroupMembers then
                    SetRaidSubgroup(raidMembers[player].index, group)
                    print("Assigned", player, "to group", group)
                    assignedPlayers[player] = true -- Mark player as assigned
                    groupCounts[group] = groupCounts[group] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                else
                    print("Group", group, "is full, cannot assign", player)
                end
            else
                print(player, "is already in the correct group", group)
                assignedPlayers[player] = true -- Mark player as assigned
            end
        else
            print("Player not found in raid:", player)
        end

        if groupCounts[group] >= maxGroupMembers then
            group = group + 1
        end
        playerIndex = playerIndex + 1
    end

    -- Assign remaining players to groups 5-8
    local unassignedGroup = 5
    for unitName, data in pairs(raidMembers) do
        if not assignedPlayers[unitName] then
            while groupCounts[unassignedGroup] >= maxGroupMembers and unassignedGroup <= 8 do
                unassignedGroup = unassignedGroup + 1
            end

            if unassignedGroup > 8 then
                print("Warning: More than 40 players, not assigning:", unitName)
                return
            end

            SetRaidSubgroup(data.index, unassignedGroup)
            print("Assigned unlisted player", unitName, "to group", unassignedGroup)
            groupCounts[unassignedGroup] = groupCounts[unassignedGroup] + 1
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

    print("Imported players for boss:", boss)
    UpdateBossButtons()
end

-- Slash command: Delete a boss
local function DeleteBoss(boss)
    if playersByBoss[boss] then
        playersByBoss[boss] = nil
        print("Deleted boss:", boss)
        UpdateBossButtons()
    else
        print("Boss not found:", boss)
    end
end

-- Slash command handling
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

-- Toggle visibility of Boss Group Manager window
SLASH_BGMT1 = "/bgmtoggle"
SlashCmdList["BGMT"] = function()
    if BossGroupManager:IsShown() then
        BossGroupManager:Hide()
    else
        BossGroupManager:Show()
    end
end

-- Initialize Frame
BossGroupManager:SetSize(150, 70) -- Width and minimum height
BossGroupManager:SetPoint("CENTER")

-- Add background texture with 30% opacity
local bgTexture = BossGroupManager:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(true)
bgTexture:SetColorTexture(0, 0, 0, 0.3) -- Black background with 30% opacity

-- Add a black border
local border = CreateFrame("Frame", nil, BossGroupManager, "BackdropTemplate")
border:SetAllPoints(true)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
})
border:SetBackdropBorderColor(0, 0, 0)

-- Enable dragging
BossGroupManager:EnableMouse(true)
BossGroupManager:SetMovable(true)
BossGroupManager:RegisterForDrag("LeftButton")
BossGroupManager:SetScript("OnDragStart", BossGroupManager.StartMoving)
BossGroupManager:SetScript("OnDragStop", BossGroupManager.StopMovingOrSizing)

-- Title
local title = BossGroupManager:CreateFontString("BossGroupManagerTitle", "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("|cFFFFFFFFBoss Group Manager|r")
title:SetFont("Fonts\\FRIZQT__.TTF", 14) -- Set font size to 14

-- Create Boss Buttons initially
UpdateBossButtons()
