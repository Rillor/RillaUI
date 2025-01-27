local _, RillaUI = ...

-- open dialog for string Import
function RillaUI:Dialog()

end
-- Function to print players missing from a specific boss setup
function RillaUI:EvaluateMissingPlayers(boss)
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
            table.insert(missingPlayers, RillaUI:GetClassColor(player))
        end
    end
    if #missingPlayers > 0 then
        RillaUI:customPrint("\nPlayers missing from " .. boss .. " setup:|r\n" .. table.concat(missingPlayers, ", "), "err")
    else
        RillaUI:customPrint("All players are present for " .. boss .. " setup.|r", "success")
    end
end

-- Function to invite missing players
function RillaUI:InviteMissingPlayers(boss)
    local assignedPlayers = playersByBoss[boss]
    if not assignedPlayers then
        RillaUI:customPrint("No Setup for " .. boss, "err")
        return
    end
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

-- Function to assign players to groups
function RillaUI:AssignPlayersToGroups(boss)
    if not playersByBoss[boss] then
        RillaUI:customPrint("No Setup for " .. boss, "err")
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

    for _, boss in ipairs(bosses) do
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