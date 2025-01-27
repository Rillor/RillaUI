local _, RillaUI = ...

-- custom print by type in formatted String
function RillaUI:customPrint(message, type)
    if type == "err" then
        print("|cffee5555" .. message .. "|r")
    elseif type == "success" then
        print("|cff55ee55" .. message .. "|r")
    end
end

-- get ClassColorForPlayer
function RillaUI:GetClassColor(player)
    for i = 1, GetNumGroupMembers() do
        local unitName, _, _, _, classFileName = GetRaidRosterInfo(i)
        if unitName == player then
            local color = RAID_CLASS_COLORS[classFileName]
            return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, player)
        end
    end
    return player -- Default to white if not found
end

-- Splits a string by a delimiter
function RillaUI:SplitString(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match:match("^%s*(.-)%s*$")) -- Trim spaces
    end
    return result
end