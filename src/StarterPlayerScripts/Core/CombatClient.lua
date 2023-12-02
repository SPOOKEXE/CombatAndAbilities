
local RunService = game:GetService('RunService')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ItemsModule = ReplicatedModules.Data.Items
local AnimationsModule = ReplicatedModules.Data.Animations
local CharacterStatesModule = ReplicatedModules.Services.CharacterStates
local HitboxUtilityModule = ReplicatedModules.Utility.Hitbox

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.Start()

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module