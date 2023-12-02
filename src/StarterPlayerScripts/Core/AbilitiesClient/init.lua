
local SystemsContainer = {}

local AbilitiesCache = {}

-- // Module // --
local Module = {}

function Module.Start()

	for _, AbilityModule in pairs( AbilitiesCache ) do
		AbilityModule.Start( )
	end

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems

	for _, AbilityModule in ipairs( script:GetChildren() ) do
		AbilitiesCache[ AbilityModule.Name ] = require(AbilityModule)
	end

	for _, AbilityModule in pairs( AbilitiesCache ) do
		AbilityModule.Init( otherSystems )
	end
end

return Module
