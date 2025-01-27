local _, RillaUI = ...

-- Create a container frame for the entire UI
RillaUI.setupManager = CreateFrame("Frame", "BossGroupManagerContainer", UIParent, "BackdropTemplate")
RillaUI.setupManager:SetSize(220, 350) -- Adjusted size for better fit
RillaUI.setupManager:SetPoint("CENTER")
RillaUI.setupManager:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
})
RillaUI.setupManager:SetBackdropColor(0, 0, 0, 0.8) -- Black background with 30% opacity
RillaUI.setupManager:SetBackdropBorderColor(0, 0, 0) -- Black border

-- Enable dragging for the container frame
RillaUI.setupManager:EnableMouse(true)
RillaUI.setupManager:SetMovable(true)
RillaUI.setupManager:RegisterForDrag("LeftButton")
RillaUI.setupManager:SetScript("OnDragStart", RillaUI.setupManager.StartMoving)
RillaUI.setupManager:SetScript("OnDragStop", RillaUI.setupManager.StopMovingOrSizing)