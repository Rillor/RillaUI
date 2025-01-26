if not Cell then
	return
end

local F = Cell.funcs

if not F then
	return
end

function F:GetNickname(shortname)
	if shortname == nil then
		return nil
	end

	shortname = shortname and NSAPI and NSAPI:GetName(shortname) or shortname
	return string.sub(shortname, 1, 8)
end