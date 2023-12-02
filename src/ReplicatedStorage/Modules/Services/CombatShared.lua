
local CollectionService = game:GetService('CollectionService')
local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')

local CombatConfigModule = require(script.Parent.Parent:WaitForChild('Data'):WaitForChild('CombatConfig'))
local CharacterStatesModule = require(script.Parent:WaitForChild('CharacterStates'))
local SoundServiceModule = require(script.Parent.Parent:WaitForChild('Services'):WaitForChild('SoundService'))

-- // Module // --
local Module = {}

Module.RemoteEnums = {
	AttemptAttack = 1,
	StartBlock = 2,
	StopBlock = 3,
	AttemptDash = 4,

	DashEffect = 9,
	BlockCounter = 10,
	RegisterHits = 11,
}

function Module.IsCharacterAlive( Character )
	local Humanoid = Character and Character:FindFirstChildWhichIsA('Humanoid')
	return Humanoid and Humanoid.Health > 0
end

function Module.FilterDeadHumanoids( humanoids : { Humanoid } )
	local index = 1
	while index <= #humanoids do
		if typeof(humanoids[index]) == 'Instance' and humanoids[index]:IsA('Humanoid') and humanoids[index].Health > 0 then
			index += 1
		else
			table.remove( humanoids, index )
		end
	end
end

function Module.IsCharacterBlocking( Character )
	return CharacterStatesModule.GetState( Character, 'Blocking' )
end

function Module.IsCharacterAttacking( Character )
	return CharacterStatesModule.GetStateTemporary( Character, 'Attacking' )
end

function Module.IsCharacterStunned( Character )
	return CharacterStatesModule.GetStateTemporary( Character, 'Stunned' )
end

function Module.IsCharacterDashing( Character )
	return CharacterStatesModule.GetStateTemporary( Character, 'Dashing' )
end

function Module.IsCharacterAvailable( Character )
	if not Module.IsCharacterAlive( Character ) then
		return false, 'Character is not alive.'
	end

	-- is the character stunned?
	if Module.IsCharacterStunned( Character ) then
		return false, 'Character is currently stunned.'
	end

	-- is the character dashing?
	if Module.IsCharacterDashing( Character ) then
		return false, 'Character is currently dashing.'
	end

	-- is the character blocking?
	if Module.IsCharacterBlocking( Character ) then
		return false, 'Character is currently blocking.'
	end

	-- is character attacking
	if Module.IsCharacterAttacking( Character ) then
		return false, 'Character is currently attacking.'
	end

	return true, 'Character is available.'
end

function Module.CanCharacterBlock( Character )
	local success, err = Module.IsCharacterAvailable( Character )
	if not success then
		return false, err
	end

	-- is the character on attack cooldown?
	if CharacterStatesModule.GetStateTemporary( Character, 'BlockCooldown' ) then
		return false, 'Character is currently on block cooldown.'
	end

	-- character is available
	return true, 'Character is available.'
end

function Module.CanCharacterDash( Character )
	local success, err = Module.IsCharacterAvailable( Character )
	if not success then
		return false, err
	end

	-- is the character on attack cooldown?
	if CharacterStatesModule.GetStateTemporary( Character, 'DashCooldown' ) then
		return false, 'Character is currently on dash cooldown.'
	end

	-- character is available
	return true, 'Character is available.'
end

function Module.CanCharacterAttack( Character )
	local success, err = Module.IsCharacterAvailable( Character )
	if not success then
		return false, err
	end

	-- is the character on attack cooldown?
	if CharacterStatesModule.GetStateTemporary( Character, 'AttackCooldown' ) then
		return false, 'Character is currently on attack cooldown.'
	end

	-- character is available
	return true
end

function Module.StunCharacter( Character, customDuration )
	customDuration = customDuration or 1.5
	-- TODO: animation for npcs & players
	CharacterStatesModule.SetStateTemporary( Character, 'Stunned', customDuration, true )
end

function Module.ApplyTemporaryMassless( Model, Duration )
	local MasslessInstances = { }
	for _, BasePart in ipairs( Model:GetDescendants() ) do
		if BasePart:IsA('BasePart') and not BasePart.Massless then
			BasePart.Massless = true
			table.insert(MasslessInstances, BasePart)
		end
	end
	task.delay(Duration, function()
		for _, BasePart in ipairs( MasslessInstances ) do
			BasePart.Massless = false
		end
	end)
end

local ANTI_GRAVITY_FORCE = Vector3.new(0, 650, 0)

function Module.RotateToward( Character, Position )
	local CharacterPosition = Character:GetPivot().Position
	local DirectionCFrame = CFrame.lookAt(CharacterPosition, Vector3.new(Position.X, CharacterPosition.Y, Position.Z))
	Character:PivotTo( DirectionCFrame )
	return DirectionCFrame
end

function Module.Knockback( Character, AttackOrigin )
	Module.ApplyTemporaryMassless( Character, 0.45 )

	local DirectionCFrame = Module.RotateToward( Character, AttackOrigin )

	local forceAttachment = Instance.new('Attachment')
	forceAttachment.Name = 'ForceAttachment'
	forceAttachment.Parent = Character.PrimaryPart
	Debris:AddItem(forceAttachment, 0.45)

	local upVelocityForce = Instance.new('VectorForce')
	upVelocityForce.Name = 'antiGravity'
	upVelocityForce.Attachment0 = forceAttachment
	upVelocityForce.ApplyAtCenterOfMass = true
	upVelocityForce.RelativeTo = Enum.ActuatorRelativeTo.World
	upVelocityForce.Force = ANTI_GRAVITY_FORCE
	upVelocityForce.Parent = forceAttachment

	local bodyGyro = Instance.new('BodyGyro')
	bodyGyro.Name = 'orientatorGyro'
	bodyGyro.CFrame = DirectionCFrame
	bodyGyro.D = 100
	bodyGyro.P = 500
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.Parent = Character.PrimaryPart
	Debris:AddItem(bodyGyro, 0.45)

	local bodyVelocity = Instance.new('BodyVelocity')
	bodyVelocity.Velocity = Character.PrimaryPart.CFrame.LookVector * -47
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.P = 1500
	bodyVelocity.Parent = Character.PrimaryPart
	Debris:AddItem(bodyVelocity, 0.45)

	TweenService:Create( bodyVelocity, TweenInfo.new(0.7), {Velocity = Vector3.zero} ):Play()
end

local baseFadeEffect = Instance.new('SelectionBox')
baseFadeEffect.Color3 = Color3.new(1,1,1)
baseFadeEffect.LineThickness = 0.01
baseFadeEffect.SurfaceColor3 = Color3.fromHSV(172, 127, 128)
baseFadeEffect.SurfaceTransparency = 0.8
baseFadeEffect.Transparency = 0.6
function Module.AttackFadeEffect( Character, effectDuration )
	effectDuration = effectDuration or 0.25
	for _, basePart in ipairs( Character:GetDescendants() ) do
		if basePart:IsA('BasePart') then
			local newEffect = baseFadeEffect:Clone()
			newEffect.Adornee = basePart
			newEffect.Parent = basePart
			TweenService:Create( newEffect, TweenInfo.new(effectDuration), { SurfaceTransparency = 1, Transparency = 1 } ):Play()
			Debris:AddItem(newEffect, effectDuration)
		end
	end
end

function Module.RunCharacterHitEffect( Character )
	Module.AttackFadeEffect( Character )
	SoundServiceModule.PlaySoundAtPosition( ReplicatedAssets.Sounds.PunchHit, Character:GetPivot().Position, math.random(90, 110)/100 )
end

function Module.RunBlockCounterEffect( Character : Model, blockHealth )

	local blockBroken = (blockHealth <= 0)

	local BoundsCF, BoundsSize = Character:GetBoundingBox()

	local attachment = Instance.new('Attachment')
	attachment.WorldCFrame = BoundsCF + Vector3.new( 0, BoundsSize.Y, 0 )
	attachment.Parent = workspace.Terrain

	local templateBillboard = ReplicatedAssets.UI.BlockCounter:Clone()
	templateBillboard.Adornee = attachment
	if blockBroken then
		templateBillboard.Label.Text = 'BLOCK BROKEN'
	else
		templateBillboard.Label.Text = blockHealth..' / '..CombatConfigModule.BLOCK_MAX_HITS
	end
	templateBillboard.Parent = attachment

	task.delay(0.5, function()
		TweenService:Create(templateBillboard.Label, TweenInfo.new(0.3), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		Debris:AddItem(attachment, 0.3)
	end)
end

function Module.RunDashEffect( Character )

	local PivotCFrame = Character:GetPivot()

	-- vfx behind the character
	local DashMesh = ReplicatedAssets.VFX.Dash.DashEffect:Clone()
	DashMesh:PivotTo( PivotCFrame * CFrame.new(0, -1, 3.5) * CFrame.Angles(0, math.rad(90), math.rad(90)) * CFrame.Angles( 0, 0, math.rad(15) ) )
	DashMesh.Parent = workspace.Terrain

	local c; c = RunService.Heartbeat:Connect(function(_)
		DashMesh:PivotTo( DashMesh:GetPivot() * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, math.rad(2), 0) )
	end)

	task.delay(0.5, function()
		local Tween = TweenService:Create(DashMesh, TweenInfo.new(0.8), { Transparency = 1 })
		Tween:Play()
		Tween.Completed:Wait()
		c:Disconnect()
		DashMesh:Destroy()
	end)

	-- hand trails
	local HandInstances = { Character.LeftHand, Character.RightHand }
	for _, hand in ipairs( HandInstances ) do
		local vfx = ReplicatedAssets.VFX.Dash.DashTrail:GetChildren()
		for _, item in ipairs( vfx ) do
			item = item:Clone()
			item.Parent = hand
			Debris:AddItem(item, CombatConfigModule.DASH_DURATION )
		end
		-- backup sets
		hand.Trail.Attachment0 = hand.Attachment0
		hand.Trail.Attachment1 = hand.Attachment1
	end

	-- sound sfx
	SoundServiceModule.PlaySoundAtPosition( ReplicatedAssets.VFX.Dash.DashSFX, PivotCFrame.Position, math.random(90, 110)/100 )

end

return Module
