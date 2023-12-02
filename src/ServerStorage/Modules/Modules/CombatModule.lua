local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local CharacterStatesModule = ReplicatedModules.Services.CharacterStates

-- // Module // --
local Module = {}

function Module.StunCharacter( Character, customDuration )
	customDuration = customDuration or 1.5
	-- TODO: animation for npcs & players
	CharacterStatesModule.SetStateTemporary( Character, 'Stunned', customDuration, true )
end

function Module.KnockdownCharacter( Character, customDuration )
	customDuration = customDuration or 1.5
	-- TODO: animation for npcs & players
	CharacterStatesModule.SetStateTemporary( Character, 'KnockedDown', customDuration, true )
	Module.StunCharacter( Character, customDuration )
end

return Module
