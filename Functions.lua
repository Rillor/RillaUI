local _, RillaUI = ...



-- open importDialog
function RillaUI:toggleImportDialog()
    if RillaUI.ImportDialog:IsShown() then
        RillaUI.ImportDialog:Hide()
    else
        RillaUI.ImportDialog:Show()
    end
end

-- TODO: add alts to evaluation
-- Function to print players missing from a specific boss setup
function RillaUI:EvaluateMissingPlayers(boss)
    if not playersByBoss[boss] then
        print("Early cancel: No setup found for boss '" .. boss .. "'")
        return
    end

    unmodifiedfullCharList = NSAPI and NSAPI:GetAllCharacters() or {}
    local fullCharList = {}
    -- Normalize both keys and values in fullCharList
    for characterName, mainCharacter in pairs(unmodifiedfullCharList) do
        local normalizedCharacterName = RillaUI:normalize(characterName)
        local normalizedMainName = RillaUI:normalize(mainCharacter)
        fullCharList[normalizedCharacterName] = normalizedMainName
    end

    local missingPlayers = {}
    for _, playerName in ipairs(playersByBoss[boss]) do
        if playerName then
            local player = playerName:match("^%s*(.-)%s*$") -- Trim spaces
            local targetPlayer = RillaUI:normalize(player)
            local found = false

            for i = 1, GetNumGroupMembers() do
                local unitName = GetRaidRosterInfo(i)
                local normalizedUnitName = RillaUI:normalize(unitName)
                -- Map the unit name to its main character
                local mainCharacter = fullCharList[normalizedUnitName] or normalizedUnitName
                -- Check if the main name matches the target player
                if RillaUI:normalize(mainCharacter) == targetPlayer then
                    found = true
                    break
                end
            end

            if not found then
                table.insert(missingPlayers, RillaUI:GetClassColor(player))
            end
        end
    end

    if #missingPlayers > 0 then
        RillaUI:customPrint("Players missing from " .. boss .. " setup:", "err")
        print(table.concat(missingPlayers, ", "))
    else
        RillaUI:customPrint("All assigned players (or their alts) are present for " .. boss .. ".", "success")
    end
end

-- Function to invite missing players
local failedInvites = {} -- List to store players who couldn't be invited

-- Function to handle system messages
local function SystemMessageHandler(msg)
    local playerName = msg:match("Cannot find player '([^']+)'") -- Adjust pattern to extract player name
    if playerName then
        table.insert(failedInvites, playerName)
    end
end


-- Register for system messages
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        SystemMessageHandler(msg)
    end
end)

function RillaUI:InviteMissingPlayers(boss)
    local fullCharList = NSAPI and NSAPI:GetAllCharacters() or {}

    local assignedPlayers = playersByBoss[boss]
    if not assignedPlayers then
        RillaUI:customPrint("No Setup for " .. boss, "err")
        return
    end
    failedInvites = failedInvites or {}

    for _, playerName in ipairs(assignedPlayers) do
        if playerName then
            local targetPlayer = RillaUI:normalize(playerName)
            local found = false
            for i = 1, GetNumGroupMembers() do
                local unitName = GetRaidRosterInfo(i)
                local strippedUnitName = RillaUI:stripServer(unitName)
                local mainName = fullCharList[strippedUnitName] or strippedUnitName
                if RillaUI:normalize(mainName) == targetPlayer then
                    found = true
                    break
                end
            end
            if not found then
                C_PartyInfo.InviteUnit(playerName)
            end
        end
    end

    C_Timer.After(1, function()
        if IsInGroup() and not IsInRaid() then
            ConvertToRaid()
            RillaUI:customPrint("Group converted to a raid.", "info")
        end

        if #failedInvites > 0 then
            RillaUI:customPrint("Failed invites:", "err")
            print(table.concat(failedInvites, ", "))

            local guildInfo = RillaUI:getGuildInfo() or {}

            for _, failedName in ipairs(failedInvites) do
                -- Determine the main name: if failedName is an alt, get its main; else failedName
                local mainCharacter = fullCharList[failedName] or failedName
                local normalizedMain = RillaUI:normalize(mainCharacter)

                local mainInfo = guildInfo[normalizedMain]
                if mainInfo and mainInfo.online then
                    C_PartyInfo.InviteUnit(mainInfo.fullName)
                else
                    local altList = {}
                    for characterName, mappedMain in pairs(fullCharList) do
                        if RillaUI:normalize(mappedMain) == normalizedMain and RillaUI:normalize(characterName) ~= normalizedMain then
                            table.insert(altList, characterName)
                        end
                    end

                    if #altList > 0 then
                        local invitedAny = false
                        for _, altName in ipairs(altList) do
                            local altKey = RillaUI:normalize(altName)
                            local altInfo = guildInfo[altKey]
                            if altInfo and altInfo.online then
                                C_PartyInfo.InviteUnit(altInfo.fullName)
                                invitedAny = true
                                break
                            end
                        end
                        if not invitedAny then
                            RillaUI:customPrint("No online alts for " .. mainCharacter, "info")
                        end
                    else
                        -- TODO: proper logging when no info is found
                        RillaUI:customPrint("No alt data available for " .. failedName .. " (main: " .. mainCharacter .. ")", "info")
                    end
                end
            end

            failedInvites = {}
        end
    end)
end

RillaUI.currentBoss = nil
-- TODO: assign alt to position of main in group-assignment
function RillaUI:AssignPlayersToGroups(boss)
    if not playersByBoss then
        RillaUI:customPrint("There have been not setups provided yet. Please copy sheet Input.", "err")
        return
    end

    if not playersByBoss[boss] then
        RillaUI:customPrint("No Setup for " .. boss, "err")
        return
    end

    RillaUI.currentBoss = boss  -- Store the current boss identifier

    local players = playersByBoss[boss]
    local maxGroupMembers = 5
    local totalGroups = 8

    local raidMembers = {}
    local unassignedPlayers = {}
    local assignedPlayers = {}
    local groupCounts = {}

    -- Initialize group counts
    for i = 1, totalGroups do
        groupCounts[i] = 0
    end

    -- Gather raid members and their current groups
    for i = 1, GetNumGroupMembers() do
        local unitName, _, subgroup = GetRaidRosterInfo(i)
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
            for newGroup = 5, totalGroups do
                if groupCounts[newGroup] < maxGroupMembers then
                    SetRaidSubgroup(index, newGroup)
                    groupCounts[newGroup] = groupCounts[newGroup] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                    break
                end
            end
        end
    end

    -- Create group layout for assigned players
    local groupLayout = {}
    for i = 1, totalGroups do
        groupLayout[i] = {}
    end

    -- First, place players with specified slots
    for _, player in ipairs(players) do
        local slot = tonumber(player:match("%+(%d+)$")) -- Extract slot if specified

        if slot then
            local targetGroup = math.ceil(slot / maxGroupMembers)
            local targetSlot = slot % maxGroupMembers
            if targetSlot == 0 then
                targetSlot = maxGroupMembers
            end

            groupLayout[targetGroup][targetSlot] = player:match("^(.-)%+") -- Remove the slot from the player's name
        end
    end

    -- Then, place players without specified slots
    local nextSlot = 1
    for _, player in ipairs(players) do
        if not player:match("%+(%d+)$") then
            while groupLayout[math.ceil(nextSlot / maxGroupMembers)][nextSlot % maxGroupMembers] do
                nextSlot = nextSlot + 1
            end

            local targetGroup = math.ceil(nextSlot / maxGroupMembers)
            local targetSlot = nextSlot % maxGroupMembers
            if targetSlot == 0 then
                targetSlot = maxGroupMembers
            end

            groupLayout[targetGroup][targetSlot] = player
            nextSlot = nextSlot + 1
        end
    end

    -- Move assigned players to specified slots within groups
    for group, slots in ipairs(groupLayout) do
        for _, player in ipairs(slots) do
            if player and raidMembers[player] then
                local currentGroup = raidMembers[player].group
                if currentGroup ~= group then
                    SetRaidSubgroup(raidMembers[player].index, group)
                    groupCounts[group] = groupCounts[group] + 1
                    groupCounts[currentGroup] = groupCounts[currentGroup] - 1
                end
            else
                for i = 1, GetNumGroupMembers() do
                    local unitName = GetRaidRosterInfo(i)
                    if unitName == player then
                        SetRaidSubgroup(i, group)
                        groupCounts[group] = groupCounts[group] + 1
                        break
                    end
                end
            end
        end
    end

    RillaUI:EvaluateMissingPlayers(boss)
end

-- Function to update boss buttons
function RillaUI:UpdateBossButtons()
    for _, child in ipairs({ RillaUI.BossGroupManager:GetChildren() }) do
        if child:GetName() ~= "BossGroupManagerTitle" and child:GetName() ~= nil and not child:GetName():find("TitleIcon") then
            child:Hide() -- Hide old buttons
        end
    end

    local buttonWidth = 120
    local buttonHeight = 30
    local xOffset = 10 -- Adjusted offset for centering
    local yOffset = -40 -- Start below the titleContainer
    local index = 0

    for _, boss in ipairs(RillaUI.bosses) do
        local button = CreateFrame("Button", "BossButton" .. index, RillaUI.BossGroupManager, "UIPanelButtonTemplate")
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
            RillaUI:AssignPlayersToGroups(boss)
        end)
        button:Show()

        -- Create an invite button
        local inviteButton = CreateFrame("Button", "InviteButton" .. index, RillaUI.BossGroupManager, "UIPanelButtonTemplate")
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
            RillaUI:InviteMissingPlayers(boss)
        end)
        inviteButton:Show()

        index = index + 1
    end

    -- Adjust the main frame's height dynamically based on the number of buttons
    local baseHeight = 40 -- Reduced base height to minimize excess space
    local totalHeight = baseHeight + (buttonHeight + 5) * index
    RillaUI.BossGroupManager:SetHeight(totalHeight)

    -- Adjust the container frame's height to include the border
    RillaUI.setupManager:SetHeight(totalHeight + 20) -- Add extra space for border
end


-- Ulgrax:Rillasp+2,Rilladk+1,Fyfan,Rillaschwanß,Rillad+4
-- Function to import bosses from and prepare boss-Table
-- TODO: Add functionality for split bullshit (kms)
function RillaUI:importBosses(bossString)
    local bossesFromString = { strsplit(";", bossString) }
    local bossNames = {}

    for _, boss in ipairs(bossesFromString) do
        local bossName, players = strsplit(":", boss)
        table.insert(bossNames, bossName)

        if bossName and players then
            local playerList = {}
            local usedSlots = {}
            local nextSlot = 1
            local playersWithoutSlots = {}

            -- players with SlotInfo
            for _, player in ipairs({ strsplit(",", players) }) do
                local playerName, providedSlot = strsplit("+", player)
                playerName = playerName:match("^%s*(.-)%s*$") -- Trim spaces
                local slot = tonumber(providedSlot)

                if slot and not usedSlots[slot] then
                    playerList[slot] = playerName
                    usedSlots[slot] = true
                else
                    table.insert(playersWithoutSlots, playerName)
                end
            end

            -- players w/o slotIfo
            for _, playerName in ipairs(playersWithoutSlots) do
                while usedSlots[nextSlot] do
                    nextSlot = nextSlot + 1
                end
                playerList[nextSlot] = playerName
                usedSlots[nextSlot] = true
                nextSlot = nextSlot + 1
            end

            RillaUI.setupManager:Show()
            playersByBoss[bossName] = playerList
        end
    end

    -- Update saved variable
    BossGroupManagerSaved.playersByBoss = playersByBoss

    -- Print imported setups for the bosses
    RillaUI:customPrint("Imported setups for the following bosses:", "success")
    print(table.concat(bossNames, ", "))

    -- Update the UI
    RillaUI:UpdateBossButtons()
end

-- Slash command: Import players for multiple bosses
function RillaUI:ImportPlayers(input)
    if not input or input == "" then
        RillaUI:customPrint("Invalid format. Use: /Rilla import Ulgrax;Player1,Player2:Boss2;Player3,Player4", "err")
        return
    end

    -- Process the input string using the importBosses function
    RillaUI:importBosses(input)
end

-- Slash command: Delete a boss
function RillaUI:DeleteBoss(boss)
    if playersByBoss[boss] then
        playersByBoss[boss] = nil
        BossGroupManagerSaved.playersByBoss = playersByBoss -- Update saved variable
        RillaUI:customPrint("Deleted boss: " .. boss, "success")
        RillaUI:UpdateBossButtons()
    else
        RillaUI.customPrint("Boss not found: " .. boss, "err")
    end
end

function RillaUI:ClearBosses()
    if playersByBoss then
        playersByBoss = nil
        BossGroupManagerSaved.playersByBoss = nil
        RillaUI:customPrint("Cleared all setups", "success")
    end
end

-- Function to reorder players within their groups based on slots
function RillaUI:ReorderPlayersWithinGroups()
    local boss = RillaUI.currentBoss
    if not boss or not playersByBoss[boss] then
        RillaUI:customPrint("No Setup for current boss", "err")
        return
    end

    local players = playersByBoss[boss]
    local maxGroupMembers = 5
    local totalGroups = 8

    -- Create group layout for assigned players
    local groupLayout = {}
    for i = 1, totalGroups do
        groupLayout[i] = {}
    end

    -- Place players with specified slots first
    for _, player in ipairs(players) do
        local slot = tonumber(player:match("%+(%d+)$")) -- Extract slot if specified

        if slot then
            local targetGroup = math.ceil(slot / maxGroupMembers)
            local targetSlot = slot % maxGroupMembers
            if targetSlot == 0 then
                targetSlot = maxGroupMembers
            end

            groupLayout[targetGroup][targetSlot] = player:match("^(.-)%+") -- Remove the slot from the player's name
        end
    end

    -- Place players without specified slots
    local nextSlot = 1
    for _, player in ipairs(players) do
        if not player:match("%+(%d+)$") then
            while groupLayout[math.ceil(nextSlot / maxGroupMembers)][nextSlot % maxGroupMembers] do
                nextSlot = nextSlot + 1
            end

            local targetGroup = math.ceil(nextSlot / maxGroupMembers)
            local targetSlot = nextSlot % maxGroupMembers
            if targetSlot == 0 then
                targetSlot = maxGroupMembers
            end

            groupLayout[targetGroup][targetSlot] = player
            nextSlot = nextSlot + 1
        end
    end

    -- Reorder players within their respective groups
    for group, slots in ipairs(groupLayout) do
        if group <= 4 then
            -- Collect current positions of players in the group
            local currentPositions = {}
            for i = 1, GetNumGroupMembers() do
                local unitName, _, subgroup, _, class = GetRaidRosterInfo(i)
                if subgroup == group then
                    table.insert(currentPositions, { name = unitName, index = i, class = class })
                end
            end

            -- Create a temporary table to hold the correct order
            local tempPositions = {}
            for _, player in ipairs(slots) do
                if player then
                    for _, pos in ipairs(currentPositions) do
                        if pos.name == player then
                            table.insert(tempPositions, pos)
                            break
                        end
                    end
                end
            end

            -- Move players within the group to match the correct order
            for slot, pos in ipairs(tempPositions) do
                if pos then
                    SetRaidSubgroup(pos.index, group)
                    RillaUI:customPrint("Moved " .. pos.name .. " to group " .. group .. " slot " .. slot, "info")
                end
            end
        end
    end

    RillaUI:customPrint("Reordered players within groups 1-4 successfully.", "success")
end

-- Register the READY_CHECK event
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "READY_CHECK" then
        RillaUI:ReorderPlayersWithinGroups()
    end
end)
