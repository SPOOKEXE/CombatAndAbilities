local hitboxBlock = Instance.new('Part')
hitboxBlock.Name = ''
hitboxBlock.Color = Color3.new(1, 0, 0)
hitboxBlock.Transparency = 0.5
hitboxBlock.CanCollide = false
hitboxBlock.CanTouch = true
hitboxBlock.CanQuery = true
hitboxBlock.Anchored = true
hitboxBlock.CastShadow = false
hitboxBlock.Parent = workspace:WaitForChild('Terrain')

local infYCFrame = CFrame.new(0, 9e10, 0)

-- // Module // --
local Module = {}

function Module.GetHitboxResult( CF : CFrame, size : Vector3, overlap : OverlapParams? )
	hitboxBlock.Size = size
	hitboxBlock.CFrame = CF
	local collisions = workspace:GetPartsInPart( hitboxBlock, overlap )
	hitboxBlock.CFrame = infYCFrame
	return collisions
end

function Module.GetHitsInBox( partInstance, overlapParams )
	return workspace:GetPartsInPart( partInstance, overlapParams )
end

function Module.GetHitsInBounds( boundCFrame, boundSize, overlapParams )
	return workspace:GetPartBoundsInBox( boundCFrame, boundSize, overlapParams )
end

function Module.FindHumanoidsFromHits( hitParts )
	local Humanoids = {}
	for _, basePart in ipairs( hitParts ) do
		local Humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then
			continue
		end
		if not table.find(Humanoids, Humanoid) then
			table.insert(Humanoids, Humanoid)
		end
	end
	return Humanoids
end

function Module.FindHumanoidsFromHitsWithFilter( hitParts, filterFunction )
	local Humanoids = {}
	for _, basePart in ipairs( hitParts ) do
		local Humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then
			continue
		end
		if filterFunction and filterFunction(basePart) then
			continue
		end
		if not table.find(Humanoids, Humanoid) then
			table.insert(Humanoids, Humanoid)
		end
	end
	return Humanoids
end

return Module
