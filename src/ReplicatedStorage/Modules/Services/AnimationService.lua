
-- // Module // --
local Module = {}

function Module.ResolveAnimationValue( animationValue : number | string | Instance ) : Animation?
	if typeof(animationValue) ~= "Instance" and typeof(animationValue) ~= "number" and typeof(animationValue) ~= "string" then
		return nil
	end

	if typeof(animationValue) == "number" or (typeof(animationValue) == "string" and tonumber(animationValue)) then
		animationValue = "rbxassetid://" .. tostring(animationValue)
	end

	if animationValue == 'rbxassetid://-1' then
		warn([[No animation id is set for animation value (rbxassetid://-1).
]].. tostring( debug.traceback() ))
		return nil
	end

	if typeof(animationValue) == "string" then
		local AnimObj = script:FindFirstChild( animationValue )
		if not AnimObj then
			AnimObj = Instance.new('Animation')
			AnimObj.Name = animationValue
			AnimObj.AnimationId = animationValue
			AnimObj.Parent = script
		end
		animationValue = AnimObj
	end

	local isAnimInstance = typeof(animationValue) == "Instance" and animationValue:IsA("Animation")
	return isAnimInstance and animationValue or nil
end

function Module.LoadAnimationsArray( Animator, animations ) : { AnimationTrack }
	local LoadedAnimations = {}
	for _, animationValue in ipairs( animations ) do
		local animationId = Module.ResolveAnimationValue( animationValue )
		if not animationId then
			warn('Could not resolve animationId from: ', tostring(animationId))
			continue
		end
		table.insert(LoadedAnimations, Animator:LoadAnimation( animationId ) )
	end
	return LoadedAnimations
end

function Module.LoadAnimationsDictionary( Animator, animations ) : { [string] : AnimationTrack }
	local LoadedAnimations = {}
	for animName, animationValue in pairs( animations ) do
		local animationId = Module.ResolveAnimationValue( animationValue )
		if not animationId then
			warn('Could not resolve animationId from: ', tostring(animationId))
			continue
		end
		LoadedAnimations[animName] = Animator:LoadAnimation( animationId )
	end
	return LoadedAnimations
end

function Module.LoadAnimationsShallow( Animator, animationTable ) : { AnimationTrack } | { [string] : AnimationTrack }
	if #animationTable > 0 then
		return Module.LoadAnimationsArray( Animator, animationTable )
	end
	return Module.LoadAnimationsDictionary( Animator, animationTable )
end

function Module.LoadAnimationsDeep( Animator, array_or_dict ) : table

	local cachedParent = { }

	local function DeepSearch( animTable, parentTable )
		parentTable = parentTable or { }

		-- prevent cyclic loop
		if cachedParent[parentTable] then
			return
		end
		cachedParent[parentTable] = true

		parentTable = parentTable or { }

		-- load an array of animations (assumes no nested table and only values)
		if #animTable > 0 then
			local animTracks = Module.LoadAnimationsArray( Animator, animTable )
			table.move(animTracks, 1, #animTracks, #animTable + 1, animTable)
			return parentTable
		end

		-- load a dictionary (assumes there may be nested tables at a given index)
		for animName, animValue in pairs( animTable ) do
			-- nested table of animations
			if typeof(animValue) == "table" then
				local tracks = {}
				DeepSearch( animValue, tracks )
				animTable[animName] = tracks
				continue
			end

			-- animation value, attempt to load
			local animationId = Module.ResolveAnimationValue( animValue )
			if not animationId then
				warn('Could not resolve animationId from: ', tostring(animationId))
				continue
			end
			parentTable[animName] = Animator:LoadAnimation( animationId )
		end

		return parentTable
	end

	return DeepSearch(array_or_dict)
end

return Module
