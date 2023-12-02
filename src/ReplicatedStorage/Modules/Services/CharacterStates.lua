
local HttpService = game:GetService('HttpService')

local EventClassModule = require(script.Parent.Parent.Modules.Event)
local MaidClassModule = require(script.Parent.Parent.Modules.Maid)

local TEMPORARY_UUIDS = { }
local PossibleStateCache = { }
local StateEventCache = { }

-- // Module // --
local Module = {}

function Module.StateChanged( Character )
	if not StateEventCache[ Character ] then
		StateEventCache[ Character ] = EventClassModule.New()

		local Maid = MaidClassModule.New()
		local oldValueCache = {}

		Maid:Give(Character.Destroying:Connect(function()
			Maid:Cleanup()
			if StateEventCache[ Character ] then
				StateEventCache[ Character ]:Disconnect()
			end
			StateEventCache[ Character ] = nil
			oldValueCache = nil
		end))

		Maid:Give(Character.AttributeChanged:Connect(function(stateName)
			if StateEventCache[ Character ] then
				local newState = Module.GetState( Character, stateName )
				StateEventCache[ Character ]:Fire( stateName, newState, oldValueCache[stateName] )
				oldValueCache[ stateName ] = newState
			end
		end))
	end
	return StateEventCache[ Character ]
end

function Module.GetCharacterStates( Character : Instance )
	local Attribs = Character:GetAttributes()
	for stateName, _ in ipairs( Attribs ) do
		if not table.find( PossibleStateCache, stateName ) then
			Attribs[stateName] = nil
		end
	end
	return Attribs
end

function Module.GetState( Character : Instance, stateName : string ) : any?
	if not table.find( PossibleStateCache, stateName ) then
		table.insert( PossibleStateCache, stateName )
	end
	return Character:GetAttribute(stateName)
end

function Module.SetState( Character : Instance, stateName : string, stateValue : any? )
	if not table.find( PossibleStateCache, stateName ) then
		table.insert( PossibleStateCache, stateName )
	end
	local oldValue = Module.GetState( Character, stateName )
	Character:SetAttribute( stateName, stateValue )
	if StateEventCache[ Character ] then
		StateEventCache[ Character ]:Fire( stateName, stateValue, oldValue )
	end
end

function Module.GetStateTemporary( Character : Instance, stateName : string ) : any?
	-- stateName ..= '_TEMP'
	if not table.find( PossibleStateCache, stateName ) then
		table.insert( PossibleStateCache, stateName )
	end
	return Character:GetAttribute(stateName)
end

function Module.SetStateTemporary( Character : Instance, stateName : string, duration : number, stateValue : any? )
	-- stateName ..= '_TEMP'
	if not table.find( PossibleStateCache, stateName ) then
		table.insert( PossibleStateCache, stateName )
	end
	Module.SetState( Character, stateName, stateValue )

	local UUID = HttpService:GenerateGUID(false)
	if not TEMPORARY_UUIDS[Character] then
		TEMPORARY_UUIDS[Character] = {}
	end
	TEMPORARY_UUIDS[Character][stateName] = UUID

	task.delay(duration, function()
		if TEMPORARY_UUIDS[Character][stateName] == UUID then
			TEMPORARY_UUIDS[Character][stateName] = nil
			Module.SetState( Character, stateName, nil )
		end
	end)
end

return Module
