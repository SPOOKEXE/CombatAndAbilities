
local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')

local Module = { }

function Module.GetPlatform()
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and (not UserInputService.MouseEnabled) then
		return "Mobile"
	end
	return "Desktop"
end

return Module

