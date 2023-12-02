local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')
require(ReplicatedStorage:WaitForChild('Modules'))

local LocalPlayer = game:GetService('Players').LocalPlayer
ReplicatedAssets:WaitForChild('Interface').Parent = LocalPlayer:WaitForChild('PlayerGui') -- moved here to fix issues

require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Modules'))
require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Core'))

local Data = require(ReplicatedStorage:WaitForChild('Framework'))
Data.Start()
