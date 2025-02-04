local _, RillaUI = ...

-- Create the frame for the Minimap button
RillaUI.MiniMapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
RillaUI.MiniMapButton:SetFrameStrata("MEDIUM")
RillaUI.MiniMapButton:SetWidth(32)
RillaUI.MiniMapButton:SetHeight(32)
RillaUI.MiniMapButton:SetFrameLevel(8)
RillaUI.MiniMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
RillaUI.MiniMapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- Position the button on the Minimap
local function UpdatePosition()
    local xpos = 52 - (80 * cos(RillaUI.MiniMapButton.angle))
    local ypos = (80 * sin(RillaUI.MiniMapButton.angle)) - 52
    RillaUI.MiniMapButton:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", xpos, ypos)
end

-- Set the default position
RillaUI.MiniMapButton.angle = 45
UpdatePosition()

-- Make the button draggable
RillaUI.MiniMapButton:RegisterForDrag("LeftButton", "RightButton")
RillaUI.MiniMapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
RillaUI.MiniMapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save the position
    local xpos, ypos = RillaUI.MiniMapButton:GetCenter()
    local minimapCenterX, minimapCenterY = Minimap:GetCenter()
    RillaUI.MiniMapButton.angle = atan2(ypos - minimapCenterY, xpos - minimapCenterX)
    UpdatePosition()
end)

-- Set the texture for the button
local icon = RillaUI.MiniMapButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\AddOns\\RillaUI\\constantLogo.tga")
icon:SetAllPoints(RillaUI.MiniMapButton)

-- Set the click function for the button
RillaUI.MiniMapButton:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        RillaUI:toggleImportDialog()
    elseif button == "RightButton" then
        RillaUI:toggleWindowVisibility()
    end
end)

