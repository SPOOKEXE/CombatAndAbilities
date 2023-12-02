local TweenService = game:GetService('TweenService')

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RNetModule = ReplicatedModules.Libraries.RNet
local DamageIndicatorBridge = RNetModule.Create('DamageIndicator')

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.OnDamageIndicator( Humanoid, Damage )

	local Position = Humanoid.Parent:GetPivot().Position

	local Att = Instance.new('Attachment')
	Att.Name = Humanoid:GetFullName()
	Att.WorldCFrame = CFrame.new( Position )
	Att.Parent = workspace.Terrain

	local TemplateDamageIndicator = LocalAssets.UI.DamageIndicator:Clone()
	TemplateDamageIndicator.Name = 'DamageIndicicator'
	TemplateDamageIndicator.Label.Text = tostring(Damage)
	TemplateDamageIndicator.Parent = Att

	task.delay(1.5, function()
		for alpha = 1, 0, -0.05 do
			TemplateDamageIndicator.Size = UDim2.fromScale( 3 * alpha, alpha )
			Att.WorldCFrame *= CFrame.new(0, 0.05, 0)
			task.wait()
		end
		Att:Destroy()
	end)

end

function Module.Start()

	DamageIndicatorBridge:OnClientEvent(function( Humanoid, Damage )
		Module.OnDamageIndicator( Humanoid, Damage )
	end)

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
