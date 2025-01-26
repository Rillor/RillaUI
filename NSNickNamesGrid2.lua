if not Grid2 then return end
local Name = Grid2.statusPrototype:new("NSNickName")

Name.IsActive = Grid2.statusLibrary.IsActive

function Name:UNIT_NAME_UPDATE(_, unit)
	self:UpdateIndicators(unit)
end

function Name:OnEnable()
	self:RegisterEvent("UNIT_NAME_UPDATE")
end

function Name:OnDisable()
	self:UnregisterEvent("UNIT_NAME_UPDATE")
end

function Name:GetText(unit)
	local name = UnitName(unit)
	name = name and NSAPI and NSAPI:GetName(name) or name
	return string.sub(name, 1, 8)
end

local function Create(baseKey, dbx)
	Grid2:RegisterStatus(Name, {"text"}, baseKey, dbx)
	return Name
end

Grid2.setupFunc["NSNickName"] = Create

Grid2:DbSetStatusDefaultValue( "NSNickName", {type = "NSNickName"})
