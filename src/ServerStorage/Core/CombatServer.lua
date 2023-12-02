
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local ServerModules = require(ServerStorage:WaitForChild("Modules"))

local DamageModule = ServerModules.Modules.DamageModule

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local CombatConfigModule = ReplicatedModules.Data.CombatConfig
local CombatSharedModule = ReplicatedModules.Services.CombatShared
local SoundServiceModule = ReplicatedModules.Services.SoundService
local AnimationService = ReplicatedModules.Services.AnimationService
local CharacterStatesModule = ReplicatedModules.Services.CharacterStates
local HitboxUtility = ReplicatedModules.Utility.Hitbox

local CombatFunction = Instance.new('RemoteFunction')
CombatFunction.Name = 'CombatFunction'
CombatFunction.Parent = ReplicatedStorage
local CombatEvent = Instance.new('RemoteEvent')
CombatEvent.Name = 'CombatEvent'
CombatEvent.Parent = ReplicatedStorage

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.IncrementCharacterCombo( Character )
	-- combo increment
	local resetCutoff = CharacterStatesModule.GetState( Character, 'NextCutoff' )
	local currentCombo = CharacterStatesModule.GetState( Character, 'AttackCombo' ) or 1

	-- reset the combo back to 1
	local comboReset = (currentCombo > #CombatConfigModule.Animations.Attacks) or (resetCutoff and time() > resetCutoff)
	if comboReset then
		-- finished combo (still play the last attack)
		CharacterStatesModule.SetState( Character, 'AttackCombo', 1 )
		currentCombo = 1
	end

	-- timings
	CharacterStatesModule.SetState( Character, 'NextCutoff', time() + CombatConfigModule.CUTOFF_TIME + CombatConfigModule.ATTACK_DURATION )
	CharacterStatesModule.SetStateTemporary( Character, 'AttackCooldown', CombatConfigModule.ATTACK_DURATION, true )
	task.delay(CombatConfigModule.ATTACK_DURATION, function()
		CharacterStatesModule.SetState( Character, 'AttackCombo', currentCombo + 1 )
	end)
end

function Module.AttemptCharacterAttack( Character )
	local canAttack, message = CombatSharedModule.CanCharacterAttack( Character )
	if not canAttack then
		return canAttack, message
	end

	Module.IncrementCharacterCombo( Character )
	CharacterStatesModule.SetStateTemporary( Character, 'Attacking', CombatConfigModule.ATTACK_DURATION, true )

	local _ = SoundServiceModule.PlaySoundAtPosition( ReplicatedAssets.Sounds.PunchSwing, Character:GetPivot().Position, math.random(90, 110)/100 )

	return true, 'Character is now attacking.'
end

function Module.EndCharacterBlock( Character )
	CharacterStatesModule.SetState( Character, 'Blocking', nil )
	CharacterStatesModule.SetState( Character, 'BlockCounter', nil )
	CharacterStatesModule.SetStateTemporary( Character, 'BlockCooldown', CombatConfigModule.BLOCK_COOLDOWN, true )
	return true, 'Character block cleared.'
end

function Module.AttemptCharacterBlock( Character )
	local canBlock, message = CombatSharedModule.CanCharacterBlock( Character )
	if not canBlock then
		return canBlock, message
	end
	CharacterStatesModule.SetState( Character, 'BlockCounter', CombatConfigModule.BLOCK_MAX_HITS )
	CharacterStatesModule.SetState( Character, 'Blocking', true )
	return true, 'Character has begun blocking.'
end

function Module.AttemptCharacterDash( Character )
	local canBlock, message = CombatSharedModule.CanCharacterDash( Character )
	if not canBlock then
		return canBlock, message
	end

	CharacterStatesModule.SetStateTemporary( Character, 'Dashing', CombatConfigModule.DASH_DURATION, true )
	CharacterStatesModule.SetStateTemporary( Character, 'DashCooldown', CombatConfigModule.DASH_COOLDOWN + CombatConfigModule.DASH_DURATION, true )
	CombatEvent:FireAllClients( CombatSharedModule.RemoteEnums.DashEffect, Character )

	return true, 'Character has begun dashing.'
end

function Module.DecrementBlockHealth( Character )
	if not CombatSharedModule.IsCharacterBlocking( Character ) then
		return
	end

	local blockHealth = CharacterStatesModule.GetState( Character, 'BlockCounter' )
	if not blockHealth then
		return false
	end

	blockHealth -= 1
	CombatEvent:FireAllClients( CombatSharedModule.RemoteEnums.BlockCounter, Character, blockHealth )

	if blockHealth <= 0 then
		Module.EndCharacterBlock( Character )
		CharacterStatesModule.SetState( Character, 'BlockCounter', nil )
		return true
	end

	CharacterStatesModule.SetState( Character, 'BlockCounter', blockHealth )
	return false
end

function Module.ResolveStunDuration( isLastComboHit, isAPlayer, blockBreak )
	return blockBreak and CombatConfigModule.StunDurations.BlockBreak or (isAPlayer and (isLastComboHit and CombatConfigModule.StunDurations.LastComboHit or CombatConfigModule.StunDurations.Player) or CombatConfigModule.StunDurations.NPC)
end

function Module.ParseCombatHits( Character, TargetHumanoids : {Humanoid} )
	if typeof(TargetHumanoids) ~= "table" then
		return
	end

	-- use only the first 10 items
	if #TargetHumanoids > 10 then
		local Temp = {}
		table.move(TargetHumanoids, 1, 10, 1, Temp)
		TargetHumanoids = Temp
	end

	CombatSharedModule.FilterDeadHumanoids( TargetHumanoids )
	if #TargetHumanoids == 0 then
		return
	end

	local CharacterPosition = Character:GetPivot().Position

	local CachedDistance = {}
	for _, Humanoid in ipairs( TargetHumanoids ) do
		CachedDistance[Humanoid] = (Humanoid.Parent:GetPivot().Position - CharacterPosition).Magnitude
	end
	table.sort(TargetHumanoids, function(a, b)
		return CachedDistance[a] < CachedDistance[b]
	end)

	warn( string.format('%s has tried to attack a total of %s humanoid%s.', Character.Name, #TargetHumanoids, #TargetHumanoids>1 and 's' or '') )

	local currentCombo = CharacterStatesModule.GetState( Character, 'AttackCombo' ) or 1
	local isLastComboAnim = (currentCombo + 1) > #CombatConfigModule.Animations.Attacks

	for _, Humanoid in ipairs( TargetHumanoids ) do
		if Humanoid.Parent == Character then
			continue
		end

		-- check distance from character
		if CachedDistance[ Humanoid ] > CombatConfigModule.MAX_DISTANCE_CUTOFF then
			continue
		end

		-- check if humanoid CAN be attacked

		-- DECREMENT BLOCK HEALTH (and block break if broken)
		local wasBlockBroken = false
		if CombatSharedModule.IsCharacterBlocking( Humanoid.Parent ) then
			wasBlockBroken = Module.DecrementBlockHealth( Humanoid.Parent )
			if not wasBlockBroken then
				continue
			end
		end

		-- damage the humanoid and run effects
		local isAPlayer = Players:GetPlayerFromCharacter(Humanoid.Parent)
		local stunDuration = Module.ResolveStunDuration( isLastComboAnim, isAPlayer, wasBlockBroken )
		CombatSharedModule.StunCharacter( Humanoid.Parent, stunDuration )
		DamageModule.DamageHumanoid( Humanoid, CombatConfigModule.Damage, Character )
		CombatEvent:FireAllClients( CombatSharedModule.RemoteEnums.CombatHitEffect, Humanoid.Parent )
		if isLastComboAnim or wasBlockBroken then
			CombatSharedModule.Knockback( Humanoid.Parent, CharacterPosition )
		else
			CombatSharedModule.RotateToward( Humanoid.Parent, CharacterPosition )
		end
		break
	end

end

function Module.OnServerInvoke( LocalPlayer, ... )
	local Args = {...}
	if #Args == 0 then
		return false, 'No arguments provided.'
	end

	local JobEnum = table.remove(Args, 1)
	if JobEnum == CombatSharedModule.RemoteEnums.AttemptAttack then
		return Module.AttemptCharacterAttack( LocalPlayer.Character )
	elseif JobEnum == CombatSharedModule.RemoteEnums.StartBlock then
		return Module.AttemptCharacterBlock( LocalPlayer.Character )
	elseif JobEnum == CombatSharedModule.RemoteEnums.StopBlock then
		return Module.EndCharacterBlock( LocalPlayer.Character )
	elseif JobEnum == CombatSharedModule.RemoteEnums.AttemptDash then
		return Module.AttemptCharacterDash( LocalPlayer.Character )
	end

	return false, 'Unknown Job Value Passed.'
end

function Module.OnServerEvent( LocalPlayer, ... )
	local Args = {...}
	if #Args == 0 then
		return false, 'No arguments provided.'
	end

	local JobEnum = table.remove(Args, 1)
	if JobEnum == CombatSharedModule.RemoteEnums.RegisterHits then
		if LocalPlayer.Character then
			Module.ParseCombatHits( LocalPlayer.Character, unpack(Args) )
		end
	end
end

function Module.SetupServerCharacterAnimations( Character )

	local Humanoid = Character and Character:WaitForChild('Humanoid', 2)
	if not Humanoid then
		return
	end
	local Animator = Humanoid and Humanoid:WaitForChild('Animator', 2) or Humanoid

	local LoadedAnimations = {}
	for index, value in pairs( CombatConfigModule.Animations ) do
		if typeof(value) == "table" then
			LoadedAnimations[index] = AnimationService.LoadAnimationsArray( Animator, value )
		elseif typeof(value) == "string" then
			value = AnimationService.ResolveAnimationValue( value )
			LoadedAnimations[index] = value and Animator:LoadAnimation( value ) or false
		end
	end

	local function stateChanged( stateName, stateValue )
		if stateName == 'Attacking' and LoadedAnimations.Attacks then
			local comboNumber = CharacterStatesModule.GetState( Character, 'AttackCombo' ) or 1
			if LoadedAnimations.Attacks[comboNumber] then
				LoadedAnimations.Attacks[comboNumber]:Play()
			end
		elseif stateName == 'Blocking' and LoadedAnimations.Block then
			if stateValue then
				LoadedAnimations.Block.Looped = true
				LoadedAnimations.Block:Play()
			else
				LoadedAnimations.Block:Stop()
			end
		elseif stateName == 'Stunned' and LoadedAnimations.Stunned then
			if stateValue then
				LoadedAnimations.Stunned.Looped = true
				LoadedAnimations.Stunned:Play()
			else
				LoadedAnimations.Stunned:Stop()
			end
		end
	end

	CharacterStatesModule.StateChanged( Character ):Connect(stateChanged)
end

function Module.ServerParseCharacterHitbox( Character )
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { Character }

	local HitboxSize = Vector3.new(4, 3, 3)
	local OffsetCFrame = Character:GetPivot() * CFrame.new( 0, 0, -2 )

	local hitsParts = HitboxUtility.GetHitboxResult( OffsetCFrame, HitboxSize, overlapParams )
	local hitHumanoids = HitboxUtility.FindHumanoidsFromHits( hitsParts )

	Module.ParseCombatHits( Character, hitHumanoids )
end

function Module.SetupDebugDummies()

	for _, Dummy in ipairs( { workspace.Blocking, workspace.Attacking, workspace.Stunned } ) do
		Module.SetupServerCharacterAnimations(Dummy)
	end

	while true do
		if not CombatSharedModule.IsCharacterBlocking( workspace.Blocking ) then
			Module.AttemptCharacterBlock( workspace.Blocking )
		end
		if not CombatSharedModule.IsCharacterAttacking( workspace.Attacking ) then
			local success, _ = Module.AttemptCharacterAttack( workspace.Attacking )
			if success then
				Module.ServerParseCharacterHitbox( workspace.Attacking )
			end
		end
		if not CombatSharedModule.IsCharacterStunned( workspace.Stunned ) then
			CombatSharedModule.StunCharacter( workspace.Stunned )
		end
		task.wait()
	end

end

function Module.Start()

	CombatFunction.OnServerInvoke = Module.OnServerInvoke
	CombatEvent.OnServerEvent:Connect(Module.OnServerEvent)

	task.spawn(Module.SetupDebugDummies)

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
