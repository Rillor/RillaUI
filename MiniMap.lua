local _, RillaUI = ...

-- Create the frame for the Minimap button
local MyMinimapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
MyMinimapButton:SetFrameStrata("MEDIUM")
MyMinimapButton:SetWidth(32)
MyMinimapButton:SetHeight(32)
MyMinimapButton:SetFrameLevel(8)
MyMinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Position the button on the Minimap
local function UpdatePosition()
    local xpos = 52 - (80 * cos(MyMinimapButton.angle))
    local ypos = (80 * sin(MyMinimapButton.angle)) - 52
    MyMinimapButton:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", xpos, ypos)
end

-- Set the default position
MyMinimapButton.angle = 45
UpdatePosition()

-- Make the button draggable
MyMinimapButton:RegisterForDrag("LeftButton")
MyMinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
MyMinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save the position
    local xpos, ypos = MyMinimapButton:GetCenter()
    local minimapCenterX, minimapCenterY = Minimap:GetCenter()
    MyMinimapButton.angle = atan2(ypos - minimapCenterY, xpos - minimapCenterX)
    UpdatePosition()
end)

-- Set the texture for the button
local icon = MyMinimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\AddOns\\RillaUI\\constantLogo.tga")
icon:SetAllPoints(MyMinimapButton)

-- Set the click function for the button
MyMinimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Execute the function when left-clicked
        MyFunction()
    end
end)

-- Define the function to be executed
function MyFunction()
    print("Romp ist ein geiler Hengst!")
end
