
local ContextActionService = game:GetService('ContextActionService')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
local Controls = PlayerModule:GetControls()

local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))
local PlatformUtility = LocalModules.Utility.Platform

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local AnimationService = ReplicatedModules.Services.AnimationService
local CombatConfigModule = ReplicatedModules.Data.CombatConfig
local CombatSharedModule = ReplicatedModules.Services.CombatShared
local CharacterStatesModule = ReplicatedModules.Services.CharacterStates
local HitboxUtility = ReplicatedModules.Utility.Hitbox

local CombatFunction = ReplicatedStorage:WaitForChild('CombatFunction') :: RemoteFunction
local CombatEvent = ReplicatedStorage:WaitForChild('CombatEvent') :: RemoteEvent

local SystemsContainer = {}

local HeldKeyValues = {}
local LoadedAnimations = { Attacks = nil, Block = nil, Stunned = nil, Dash = nil }

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

-- // Module // --
local Module = {}

-- yield until the target key is released
function Module.YieldUntilRelease( inputValue : Enum.KeyCode | Enum.UserInputType )
	while HeldKeyValues[inputValue] do
		task.wait()
	end
end

function Module.EnableMovement()
	Controls:Enable()
end

function Module.DisableMovement()
	Controls:Disable()
end

function Module.LoadCombatAnimations( Character )
	local Humanoid = Character and Character:WaitForChild('Humanoid', 2)
	if not Humanoid then
		return
	end

	local Animator = Humanoid and Humanoid:WaitForChild('Animator', 2) or Humanoid

	LoadedAnimations = {}
	for index, value in pairs( CombatConfigModule.Animations ) do
		if typeof(value) == "table" then
			LoadedAnimations[index] = AnimationService.LoadAnimationsArray( Animator, value )
		elseif typeof(value) == "string" then
			value = AnimationService.ResolveAnimationValue( value )
			LoadedAnimations[index] = value and Animator:LoadAnimation( value ) or false
		end
	end
end

function Module.RunMeleeAttack()
	local available, err = CombatSharedModule.CanCharacterAttack( LocalPlayer.Character )
	if not available then
		print('Player cannot attack: ', err)
		return
	end

	local success, message = CombatFunction:InvokeServer( CombatSharedModule.RemoteEnums.AttemptAttack )
	if not success then
		warn( 'Server said you cannot attack: ' .. tostring(message) )
		return
	end

	print('Character is now attacking!')

	local comboValue = CharacterStatesModule.GetStateTemporary( LocalPlayer.Character, 'AttackCombo' ) or 1

	local AnimationTrack = LoadedAnimations.Attacks and LoadedAnimations.Attacks[ comboValue ]
	if AnimationTrack then
		AnimationTrack:Play()
	end

	overlapParams.FilterDescendantsInstances = { LocalPlayer.Character }

	local HitboxSize = Vector3.new(4, 3, 3)
	local OffsetCFrame = LocalPlayer.Character:GetPivot() * CFrame.new( 0, 0, -2 )

	local hitsParts = HitboxUtility.GetHitboxResult( OffsetCFrame, HitboxSize, overlapParams )
	local hitHumanoids = HitboxUtility.FindHumanoidsFromHits( hitsParts )

	CombatEvent:FireServer( CombatSharedModule.RemoteEnums.RegisterHits, hitHumanoids )
end

function Module.AttemptMeleeAttack( inputValue : Enum.KeyCode | Enum.UserInputType )
	if not CombatSharedModule.CanCharacterAttack( LocalPlayer.Character ) then
		print('Could not attack - character is unavailable.')
		return Enum.ContextActionResult.Pass
	end

	task.spawn(function()
		print('Attack started.')
		while true do
			Module.RunMeleeAttack()
			task.wait( CombatConfigModule.ATTACK_DURATION + 0.05 )
			if not HeldKeyValues[inputValue] then
				break
			end
		end
	end)

	return Enum.ContextActionResult.Sink
end

function Module.AttemptBlockStart( inputValue : Enum.KeyCode | Enum.UserInputType )
	if not CombatSharedModule.CanCharacterBlock( LocalPlayer.Character ) then
		print('Could not block - character is unavailable.')
		return Enum.ContextActionResult.Pass
	end

	local success, msg = CombatFunction:InvokeServer( CombatSharedModule.RemoteEnums.StartBlock )
	if not success then
		print('Could not block - ', msg)
		return Enum.ContextActionResult.Pass
	end

	task.spawn(function()
		if LoadedAnimations.Block then
			LoadedAnimations.Block.Looped = true
			LoadedAnimations.Block:Play()
		end
		while HeldKeyValues[inputValue] and CombatSharedModule.IsCharacterBlocking( LocalPlayer.Character ) do
			task.wait(0.05)
		end
		if LoadedAnimations.Block then
			LoadedAnimations.Block:Stop()
		end
		CombatFunction:InvokeServer( CombatSharedModule.RemoteEnums.StopBlock )
	end)

	return Enum.ContextActionResult.Sink
end

function Module.AttemptDash( )
	if not CombatSharedModule.CanCharacterDash( LocalPlayer.Character ) then
		print('Could not dash - character is unavailable.')
		return Enum.ContextActionResult.Pass
	end

	local success, msg = CombatFunction:InvokeServer( CombatSharedModule.RemoteEnums.AttemptDash )
	if not success then
		print('Could not dash - ', msg)
		return Enum.ContextActionResult.Pass
	end

	if LoadedAnimations.Dash then
		LoadedAnimations.Dash.Looped = true
		LoadedAnimations.Dash:Play()
	end

	local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart

	local CharacterCFrame = LocalPlayer.Character:GetPivot()
	local EndCFrame = CharacterCFrame + (CharacterCFrame.LookVector * CombatConfigModule.DASH_DISTANCE)

	local BodyPosition = Instance.new('BodyPosition')
	BodyPosition.Position = CharacterCFrame.Position
	BodyPosition.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	BodyPosition.P = 50000
	BodyPosition.D = 900
	BodyPosition.Parent = HumanoidRootPart
	local BodyGyro = Instance.new('BodyGyro')
	BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	BodyGyro.CFrame = CharacterCFrame
	BodyGyro.Parent = HumanoidRootPart

	local ti = TweenInfo.new(CombatConfigModule.DASH_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local Tween = TweenService:Create(BodyPosition, ti, { Position = EndCFrame.Position + Vector3.new(0, 5, 0) })
	Tween:Play()

	local c; c = CharacterStatesModule.StateChanged( LocalPlayer.Character ):Connect(function(stateName, newValue, _)
		if stateName == 'Stunned' and newValue and Tween.PlaybackState ~= Enum.PlaybackState.Completed then
			Tween:Cancel()
			c:Disconnect()
		end
	end)

	Tween.Completed:Wait()

	if LoadedAnimations.Dash then
		LoadedAnimations.Dash:Stop()
	end

	BodyPosition:Destroy()
	BodyGyro:Destroy()
end

function Module.HandleActionInput( inputState : Enum.UserInputState, inputObject : InputObject )

	local inputValue = (inputObject.KeyCode == Enum.KeyCode.Unknown) and inputObject.UserInputType or inputObject.KeyCode
	-- print( inputValue.Name, inputState.Name )
	HeldKeyValues[inputValue] = (inputState==Enum.UserInputState.Begin) or nil

	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if inputValue == Enum.UserInputType.MouseButton1 then
		return Module.AttemptMeleeAttack( inputValue )
	elseif inputValue == Enum.KeyCode.F then
		return Module.AttemptBlockStart( inputValue )
	elseif inputValue == Enum.KeyCode.Q then
		return Module.AttemptDash()
	end

	return Enum.ContextActionResult.Pass
end

function Module.ReleaseBinds()
	warn('Releasing Keybinds')
	ContextActionService:UnbindAction('combatBind')
end

function Module.SetupDesktopBinds()

	Module.ReleaseBinds()
	warn('Setting up Desktop keybinds.')

	local DesktopKeybinds = {
		Enum.UserInputType.MouseButton1, -- combat
		Enum.KeyCode.Q, -- dash
		Enum.KeyCode.F, -- block
		-- abilities (below)
		Enum.KeyCode.Z,
		Enum.KeyCode.X,
		Enum.KeyCode.C,
		Enum.KeyCode.V,
	}

	ContextActionService:BindAction('combatBind', function(actionName, inputState, inputObject)
		if actionName == 'combatBind' then
			return Module.HandleActionInput( inputState, inputObject )
		end
		return Enum.ContextActionResult.Pass
	end, false, unpack(DesktopKeybinds))

end

function Module.SetupConsoleBinds()

	Module.ReleaseBinds()
	warn('Setting up Console keybinds.')

end

function Module.SetupMobileBinds()

	Module.ReleaseBinds()
	warn('Setting up Mobile buttons.')

end

function Module.CheckMovementState( stateName, newValue, oldValue )
	if stateName == 'Stunned' or stateName == 'Blocking' or stateName == 'Attacking' then
		if newValue then
			Module.DisableMovement()
		else
			Module.EnableMovement()
		end
	end

	if stateName == 'Stunned' and LoadedAnimations.Stunned then
		if newValue then
			LoadedAnimations.Stunned.Looped = true
			LoadedAnimations.Stunned:Play()
		else
			LoadedAnimations.Stunned:Stop()
		end
	end
end

function Module.OnCharacterAdded( Character )
	local Humanoid = Character and Character:WaitForChild('Humanoid', 2)
	if not Humanoid then
		return
	end

	Module.LoadCombatAnimations(Character)

	local MaidInstance = ReplicatedModules.Modules.Maid.New()
	MaidInstance:Give(CharacterStatesModule.StateChanged(Character):Connect(Module.CheckMovementState))
	MaidInstance:Give(Humanoid.Died:Connect(function()
		MaidInstance:Cleanup()
		MaidInstance = nil
	end))
end

function Module.Start()

	CombatEvent.OnClientEvent:Connect(function( ... )
		local Args = {...}
		local JobEnum = table.remove(Args, 1)
		if JobEnum == CombatSharedModule.RemoteEnums.CombatHitEffect then
			CombatSharedModule.RunCharacterHitEffect( unpack(Args) )
		elseif JobEnum == CombatSharedModule.RemoteEnums.BlockCounter then
			CombatSharedModule.RunBlockCounterEffect( unpack(Args) )
		elseif JobEnum == CombatSharedModule.RemoteEnums.DashEffect then
			CombatSharedModule.RunDashEffect( unpack(Args) )
		end
	end)

	-- mouse (mouse and keyboard)
	-- touch (mobile, touch-screen)
	-- gamepad (controller, ps4 and xbox)
	local platform = PlatformUtility.GetPlatform()
	if platform == 'Desktop' then
		Module.SetupDesktopBinds()
	elseif platform == 'Console' then
		Module.SetupConsoleBinds()
	elseif platform == 'Mobile' then
		Module.SetupMobileBinds()
	end

	task.defer(Module.OnCharacterAdded, LocalPlayer.Character)
	LocalPlayer.CharacterAdded:Connect(Module.OnCharacterAdded)
end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module