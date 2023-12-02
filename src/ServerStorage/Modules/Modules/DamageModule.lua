local CollectionService = game:GetService('CollectionService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RNetModule = ReplicatedModules.Libraries.RNet
local DamageIndicatorBridge = RNetModule.Create('DamageIndicator')

local INVULNERABILITY_TAG = 'INVULNERABILITY'

-- // Module // --
local Module = {}

function Module.TagHumanoid( Humanoid, Value )
	assert( Value, 'Cannot tag humanoid will nil value.' )
	local ObjValue = Humanoid:FindFirstChild( Value:GetFullName() )

	if ObjValue and ObjValue:GetAttribute('Expiry') and time() > ObjValue:GetAttribute('Expiry') then
		ObjValue:Destroy()
		ObjValue = nil
	end

	if not ObjValue then
		ObjValue = Instance.new('ObjectValue')
		ObjValue.Name = Value:GetFullName()
		ObjValue.Value = Value
		ObjValue.Parent = Humanoid
	end
	return ObjValue
end

function Module.TagHumanoidTemporary( Humanoid, Value, Duration )
	local ObjValue = Module.TagHumanoid( Humanoid, Value )
	ObjValue:SetAttribute('Expiry', time() + Duration)
end

--[[
	function Module.GetHumanoidTagOwners( Humanoid )
		local TagOwners = { }
		for _, ObjValue in ipairs( Humanoid:GetChildren() ) do
			if ObjValue:IsA("ObjectValue") then
				table.insert( TagOwners, ObjValue.Value )
			end
		end
		return TagOwners
	end
]]

function Module.GetHumanoidTags( Humanoid )
	local TagValues = { }
	for _, ObjValue in ipairs( Humanoid:GetChildren() ) do
		if ObjValue:IsA("ObjectValue") then
			TagValues[ObjValue.Value] = ObjValue:GetAttributes()
		end
	end
	return TagValues
end

function Module.DamageHumanoid( Humanoid, Damage, DamageOwner )
	if typeof(DamageOwner) == "Instance" then
		local tagInstance = Module.TagHumanoid( Humanoid, DamageOwner )
		local currentDamage = tagInstance:GetAttribute('Damage') or 0
		tagInstance:SetAttribute('Damage', currentDamage + Damage)
	end
	Humanoid:TakeDamage( Damage )
	DamageIndicatorBridge:FireAllClients( Humanoid, Damage )
end

function Module.DamageCharacter( Character, Damage, DamageOwner )
	local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return
	end

	if CollectionService:HasTag( Character, INVULNERABILITY_TAG ) then
		-- TODO: display invulnerability above head
		return
	end

	Module.DamageHumanoid( Humanoid, Damage, DamageOwner )
end

function Module.IsHumanoidInCombat( Humanoid )
	local Tags = Module.GetHumanoidTags( Humanoid )
	for _, Attributes in pairs( Tags ) do
		if Attributes['Expiry'] and time() < Attributes['Expiry'] then
			return true
		end
	end
	return false
end

function Module.IsCharacterInCombat( Character )
	local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return false
	end
	return Module.IsHumanoidInCombat( Humanoid )
end

return Module
