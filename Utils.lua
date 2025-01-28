local _, RillaUI = ...

-- custom print by type in formatted String
function RillaUI:customPrint(message, type)
    local printHeader = "==== Rilla's Setup Manager ===="
    if type == "err" then
        print(printHeader)
        print("|cffee5555" .. message .. "|r")
    elseif type == "success" then
        print(printHeader)
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

function RillaUI:DevTool(variable, name)
    DevTool:AddData(variable, name)
end

function RillaUI:tableLength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end