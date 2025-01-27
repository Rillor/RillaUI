local _, RillaUI = ...


-- Setup Manager Frame Creation
-- Create a container frame for the entire UI
RillaUI.setupManager = CreateFrame("Frame", "BossGroupManagerContainer", UIParent, "BackdropTemplate")
RillaUI.setupManager:SetSize(220, 350) -- Adjusted size for better fit
RillaUI.setupManager:SetPoint("CENTER")
RillaUI.setupManager:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }, })
RillaUI.setupManager:SetBackdropColor(0, 0, 0, 0.8) -- Black background with 30% opacity
RillaUI.setupManager:SetBackdropBorderColor(0, 0, 0) -- Black border

-- Enable dragging for the container frame
RillaUI.setupManager:EnableMouse(true)
RillaUI.setupManager:SetMovable(true)
RillaUI.setupManager:RegisterForDrag("LeftButton")
RillaUI.setupManager:SetScript("OnDragStart", RillaUI.setupManager.StartMoving)
RillaUI.setupManager:SetScript("OnDragStop", RillaUI.setupManager.StopMovingOrSizing)

local backdropData = { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }, }
-- Import Dialog Frame Creation
-- Create the main frame for the dialog
RillaUI.ImportDialog = CreateFrame("Frame", "ImportDialogFrame", UIParent, "BackdropTemplate")
RillaUI.ImportDialog:SetSize(380, 300) -- Adjusted size for better layout
RillaUI.ImportDialog:SetPoint("CENTER") -- Center the dialog on the screen
RillaUI.ImportDialog:SetMovable(true) -- Make the frame movable
RillaUI.ImportDialog:SetResizable(true) -- Make the frame resizable
RillaUI.ImportDialog:EnableMouse(true) -- Enable mouse interaction
RillaUI.ImportDialog:RegisterForDrag("LeftButton") -- Register the frame for dragging
RillaUI.ImportDialog:SetScript("OnDragStart", RillaUI.ImportDialog.StartMoving) -- Script for dragging
RillaUI.ImportDialog:SetScript("OnDragStop", RillaUI.ImportDialog.StopMovingOrSizing) -- Script to stop moving
RillaUI.ImportDialog:SetBackdrop(backdropData)

-- Create the close button (X)
local CloseButton = CreateFrame("Button", nil, RillaUI.ImportDialog, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", RillaUI.ImportDialog, "TOPRIGHT", -5, -5)

-- Create the title for the dialog
RillaUI.ImportDialog.title = RillaUI.ImportDialog:CreateFontString(nil, "OVERLAY")
RillaUI.ImportDialog.title:SetFontObject("GameFontHighlight")
RillaUI.ImportDialog.title:SetPoint("TOP", RillaUI.ImportDialog, "TOP", 0, -15)
RillaUI.ImportDialog.title:SetText("Import String")
RillaUI.ImportDialog.title:SetFont("Fonts\\FRIZQT__.TTF", 16)

-- Create the frame for the backdrop behind the edit box
local BackdropFrame = CreateFrame("Frame", nil, RillaUI.ImportDialog, "BackdropTemplate")
BackdropFrame:SetSize(320, 150) -- Set size for the backdrop frame
BackdropFrame:SetPoint("TOP", RillaUI.ImportDialog, "TOP", 0, -40)
BackdropFrame:SetBackdrop(backdropData)
BackdropFrame:SetBackdropColor(0.7, 0.7, 0.7, 1)
BackdropFrame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

-- Create the scroll frame for the text input
local ScrollFrame = CreateFrame("ScrollFrame", nil, BackdropFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetSize(320, 140) -- Adjusted size to fit inside the backdrop frame
ScrollFrame:SetPoint("TOPLEFT", 5, -5) -- Indent within the backdrop frame

-- Create the edit box for input inside the scroll frame
local EditBox = CreateFrame("EditBox", nil, ScrollFrame)
EditBox:SetMultiLine(true)
EditBox:SetFontObject("ChatFontNormal")
EditBox:SetSize(320, 140) -- Adjust size to fit inside the scroll frame
EditBox:SetAutoFocus(true)
EditBox:SetScript("OnEscapePressed", EditBox.ClearFocus)
EditBox:SetScript("OnEnterPressed", EditBox.ClearFocus)
EditBox:SetPoint("TOPLEFT")
EditBox:SetPoint("BOTTOMRIGHT")

ScrollFrame:SetScrollChild(EditBox)

-- Create the import button
local ImportButton = CreateFrame("Button", "ImportButton", RillaUI.ImportDialog, "GameMenuButtonTemplate")
ImportButton:SetSize(100, 25) -- Adjust size as needed
ImportButton:SetPoint("BOTTOM", RillaUI.ImportDialog, "BOTTOM", 0, 10)
ImportButton:SetText("Import")
ImportButton:SetNormalFontObject("GameFontNormalLarge")
ImportButton:SetHighlightFontObject("GameFontHighlightLarge")

-- Create a texture and set it as the button's background
local normalTexture = ImportButton:CreateTexture()
normalTexture:SetAllPoints()
normalTexture:SetColorTexture(0.11, 0.11, 0.11, 1) -- RGB values for #1c1c1c
ImportButton:SetNormalTexture(normalTexture)

-- Create a texture for hover and set it as the highlight texture
local highlightTexture = ImportButton:CreateTexture()
highlightTexture:SetAllPoints()
highlightTexture:SetColorTexture(0.3, 0.3, 0.3, 1) -- Brighter shade for hover
ImportButton:SetHighlightTexture(highlightTexture)

-- Define the function to handle the import
ImportButton:SetScript("OnClick", function()
    local bossString = EditBox:GetText()
    -- Process the imported string as needed
    if bossString == "" then
        RillaUI:customPrint("No String provided", "err")
        return
    end

    if bossString then
        RillaUI:importBosses(bossString)
        bossString = null
        RillaUI.ImportDialog:Hide()
        return
    end

    RillaUI:customPrint("Encountered unexpected scenario. Please contact Rilla#1506","err")

end)

-- Show the dialog
RillaUI.ImportDialog:Hide()