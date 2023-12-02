
local RunService = game:GetService('RunService')

local DEFAULT_MOVE_TO_TIMEOUT = 4
local GOAL_DISTANCE_THREASHOLD = 3

local ACTIVE_MOVE_DATA = { }

local function IsDataCompleted( Data )
	-- timeout, success = false
	if time() > Data.Time then
		Data.Success = false
		Data.Reason = 1
		return true
	end

	-- humanoid died, success = false
	if Data.Humanoid.Health <= 0 then
		Data.Success = false
		Data.Reason = 2
		return true
	end

	-- is close enough (on the horziontal plane, excluding Y value), success = true
	local Delta = (Data.HumanoidRootPart:GetPivot().Position - Data.Position)
	if Vector2.new( Delta.X, Delta.Z ).Magnitude < GOAL_DISTANCE_THREASHOLD then
		Data.Success = true
		Data.Reason = 3
		return true
	end

	-- active callback returned false, success = false
	if Data.ActiveCallback and Data.ActiveCallback(Data) == false then
		Data.Success = false
		Data.Reason = 4
		return true
	end

	-- is not completed yet
	return false
end

-- // Module // --
local Module = {}

function Module.MoveToLoop( Humanoid, HumanoidRootPart, Position, ActiveCallback )
	-- create a bindable to yield
	local Bindable = Instance.new('BindableEvent')

	-- setup the MoveTo data for the RunService loop
	local Data = {
		Bindable = Bindable,

		HumanoidRootPart = HumanoidRootPart,
		Humanoid = Humanoid,
		Position = Position,
		ActiveCallback = ActiveCallback,

		Success = nil,
		Reason = -1,

		Time = time() + DEFAULT_MOVE_TO_TIMEOUT,
	}

	-- append it to the active moveto cache
	table.insert(ACTIVE_MOVE_DATA, Data)

	-- if it has not been completed yet
	if typeof(Data.Success) == 'nil' then
		-- yield until the moveto is completed
		Bindable.Event:Wait()
	end

	-- destroy the bindable (prevent memory leak)
	Bindable:Destroy()

	-- return whether the MoveTo succeeded or timed out and for what reason
	-- REASON: 1 = timeout, 2 = humanoid died, 3 = goal reached, 4 = callback return false
	return Data.Success, Data.Reason
end

RunService.Heartbeat:Connect(function()

	local Terrain = workspace.Terrain

	debug.profilebegin('MoveToHeartbeat')

	local index = 1
	while index <= #ACTIVE_MOVE_DATA do
		-- get the data at the index
		local Data = ACTIVE_MOVE_DATA[index]
		-- if its completed
		if IsDataCompleted( Data ) then
			-- remove it from the active cache
			table.remove(ACTIVE_MOVE_DATA, index)
			-- complete the MoveTo yield
			Data.Bindable:Fire()
		else -- otherwise if not completed
			-- move the humanoid towards the point again
			Data.Humanoid:MoveTo( Data.Position, Terrain )
			-- increment the index for the next data
			index += 1
		end
	end

	debug.profileend()

end)

return Module

