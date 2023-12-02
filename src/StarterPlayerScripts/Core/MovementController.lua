local CollectionService = game:GetService('CollectionService')

local LocalPlayer = game:GetService('Players').LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
local Controls = PlayerModule:GetControls()

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.EnableMovement()
	Controls:Enable()
end

function Module.DisableMovement()
	Controls:Disable()
end

function Module.CheckMovementEnabled()
	local Items = CollectionService:GetTagged('MOVEMENT_DISABLE')
	local IsDisabled = table.find( Items, LocalPlayer.Character) or table.find( Items, LocalPlayer)
	if IsDisabled then
		Module.DisableMovement()
	else
		Module.EnableMovement()
	end
end

function Module.Start()
	task.defer(Module.CheckMovementEnabled)

	LocalPlayer.CharacterAdded:Connect(Module.CheckMovementEnabled)

	CollectionService:GetInstanceAddedSignal('MOVEMENT_DISABLE'):Connect(function(item)
		if LocalPlayer.Character == item or LocalPlayer == item then
			Module.CheckMovementEnabled()
		end
	end)

	CollectionService:GetInstanceRemovedSignal('MOVEMENT_DISABLE'):Connect(function(item)
		if (LocalPlayer.Character == item) or (LocalPlayer == item) then
			Module.CheckMovementEnabled()
		end
	end)
end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
