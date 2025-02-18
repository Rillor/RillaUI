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
    elseif type == "info" then
        print("|cff00ffff".. message .."|r")
    end
end

-- get ClassColorForPlayer
function RillaUI:GetClassColor(player)
    -- TOOD: get rid of this function
    -- It'll only work for players who are known to the player (guild,raid, friendList) so default to white is afaik what has to be done

    for i = 1, GetNumGroupMembers() do
        local unitName = GetRaidRosterInfo(i)
        if unitName == player then
            local _, classFileName = UnitClass(unitName)
            local color = RAID_CLASS_COLORS[classFileName]

            return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, player)
        end
    end
    return player
end

-- TODO: check if this is still used
function RillaUI:tableLength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Helper: normalize names (trim and lower-case)
function RillaUI:normalize(name)
    return (name and name:match("^%s*(.-)%s*$") or ""):lower()
end

-- Function to strip server name from a full player name
function RillaUI:stripServer(name)
    local baseName = name:match("^(.-)%-.+$") or name  -- Strip server if present
    return RillaUI:normalize(baseName)
end

function RillaUI:getGuildInfo()
    -- Build guildInfo table from the guild roster.
    local guildInfo = {}
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local fullName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if fullName then
            local nameWithoutServer = RillaUI:stripServer(fullName)
            guildInfo[nameWithoutServer] = { online = online, fullName = fullName }
        end
    end
    return guildInfo
end