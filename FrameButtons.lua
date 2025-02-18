local _, RillaUI = ...

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
