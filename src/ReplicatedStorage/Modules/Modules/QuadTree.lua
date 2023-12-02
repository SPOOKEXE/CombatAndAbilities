
export type Point = { x : number, y : number }
export type Rectangle = { x : number, y : number, width : number, height : number }
export type QuadTree = {
	boundary : Rectangle, capacity : number, divide : boolean?,
	northeast : QuadTree?, northwest : QuadTree?, southeast : QuadTree?, southwest : QuadTree?,
	points : { Point | Rectangle },
}

local function SetProperties( Parent, Properties )
	if typeof(Properties) == "table" then
		for propName, propValue in pairs(Properties) do
			Parent[propName] = propValue
		end
	end
	return Parent
end

-- // Point // --
local Point = { ClassName = 'Point' }
Point.__index = Point

function Point.New(Properties)
	return setmetatable(SetProperties({
		x = 0,
		y = 0,
		data = nil,
	}, Properties), Point)
end

function Point:Show( yLevel )
	local A = Instance.new('Attachment')
	A.WorldPosition = Vector3.new( self.x, yLevel, self.y )
	A.Visible = true
	A.Parent = workspace.Terrain
	return A
end

-- // Rectangle // --
local Rectangle = { ClassName = 'Rectangle' }
Rectangle.__index = Rectangle
function Rectangle.New(Properties)
	return setmetatable(SetProperties({
		x = 0,
		y = 0,
		width = 0,
		height = 0,
		data = nil,
	}, Properties), Rectangle)
end

function Rectangle:Intersects(_rectangle)
	return not (
		(_rectangle.x - _rectangle.width > self.x + self.width) or 
		(_rectangle.x + _rectangle.width < self.x - self.width)  or
		(_rectangle.y - _rectangle.height > self.y + self.height) or
		(_rectangle.y + _rectangle.height < self.y - self.height)
	)
end

function Rectangle:Contains(_point)
	return
		(_point.x <= self.x + self.width) and
		(_point.x >= self.x - self.width) and
		(_point.y <= self.y + self.height) and
		(_point.y >= self.y - self.height)
end

function Rectangle:Show( yLevel )

	local locations = {
		Vector3.new(self.x + self.width, yLevel, self.y + self.height),
		Vector3.new(self.x - self.width, yLevel, self.y + self.height),
		Vector3.new(self.x - self.width, yLevel, self.y - self.height),
		Vector3.new(self.x + self.width, yLevel, self.y - self.height),
	}

	local instances = {}
	for i, v in ipairs(locations) do
		local A = Instance.new('Attachment')
		A.Name = i
		A.WorldPosition = v
		A.Visible = true
		A.Parent = workspace.Terrain
		table.insert(instances, A)
	end

	local col = ColorSequence.new(Color3.new(1,1,1))

	local lastAttachment = instances[#instances]
	for _, attachment in ipairs(instances) do
		if lastAttachment then
			local b = Instance.new('Beam')
			b.Color = self.customColor or col
			b.FaceCamera = true
			b.Attachment0 = attachment
			b.Attachment1 = lastAttachment
			b.LightEmission = 1
			b.LightInfluence = 0
			b.Width0 = 0.5
			b.Width1 = 0.5
			b.Parent = workspace.Terrain
		end
		lastAttachment = attachment
	end

	return instances

end

-- // QuadTree // --
local quadTreeCapacity = 8

local QuadTree = { ClassName = 'QuadTree' }
QuadTree.__index = QuadTree

function QuadTree.New(Properties)
	return setmetatable(SetProperties({
		boundary = Rectangle.New(),

		capacity = quadTreeCapacity,
		points = {},

		divide = false,
		northeast = nil,
		northwest = nil,
		southeast = nil,
		southwest = nil,

		data = nil,
	}, Properties), QuadTree)
end

function QuadTree:Subdivide()

	local x = self.boundary.x
	local y = self.boundary.y
	local w = self.boundary.width
	local h = self.boundary.height

	self.northeast = QuadTree.New({
		boundary = Rectangle.New({
			x = x + w/2,
			y = y - h/2,
			width = w/2,
			height = h/2,
		}),
		capacity = self.capacity,
		root = self,
	})

	self.northwest = QuadTree.New({
		boundary = Rectangle.New({
			x = x - w/2,
			y = y - h/2,
			width = w/2,
			height = h/2,
		}),
		capacity = self.capacity,
		root = self,
	})

	self.southeast = QuadTree.New({
		boundary = Rectangle.New({
			x = x + w/2,
			y = y + h/2,
			width = w/2,
			height = h/2,
		}),
		capacity = self.capacity,
		root = self,
	})

	self.southwest = QuadTree.New({
		boundary = Rectangle.New({
			x = x - w/2,
			y = y + h/2,
			width = w/2,
			height = h/2,
		}),
		capacity = self.capacity,
		root = self,
	})

	self.divide = true

end

function QuadTree:Update( _point : Point )
	if _point.Parent and ( not _point.Parent.boundary:Contains( _point ) ) then
		_point.Parent:Remove( _point )
		local c = 0
		local parent = _point.Parent
		while parent.root and c < 50 do
			parent = parent.root
			c += 1
		end
		parent:Insert(_point)
	end
end

function QuadTree:Insert(_point : Point)
	if not self.boundary:Contains(_point) then
		return false
	end

	if #self.points < self.capacity then
		table.insert(self.points, _point)
		_point.Parent = self
		return true
	end

	if not self.divide then
		self:Subdivide()
	end

	if self.northeast:Insert(_point) then
		return true
	elseif self.southwest:Insert(_point) then
		return true
	elseif self.northwest:Insert(_point) then
		return true
	elseif self.southeast:Insert(_point) then
		return true
	end
	return false
end

function QuadTree:Query(_range, found_points)
	if _range:Intersects(self.boundary) then
		for _, p in ipairs(self.points) do
			local isPointContained = p.ClassName == 'Point' and _range:Contains(p)
			local isRectContained = p.ClassName == 'Rectangle' and _range:Intersects(p)
			if isPointContained or isRectContained then
				table.insert(found_points, p)
			end
		end
		if self.divide then
			self.northwest:Query(_range, found_points)
			self.northeast:Query(_range, found_points)
			self.southwest:Query(_range, found_points)
			self.southeast:Query(_range, found_points)
		end
	end
	return found_points
end

function QuadTree:Remove( point_or_range )
	local index = table.find( self.points, point_or_range )
	if index then
		table.remove(self.points, index)
	end
	if self.divide then
		self.northwest:Remove( point_or_range )
		self.northeast:Remove( point_or_range )
		self.southwest:Remove( point_or_range )
		self.southeast:Remove( point_or_range )
		if #self.northwest.points == 0 and #self.northeast.points == 0 and #self.southwest.points == 0 and #self.southeast.points == 0 then
			self.divide = false
			self.northwest = nil
			self.northeast = nil
			self.southwest = nil
			self.southeast = nil
		end
	end
end

function QuadTree:Show( yLevel, instances )
	yLevel = (yLevel or 20)

	instances = instances or { }
	table.insert(instances, self.boundary:Show(yLevel))
	for _, point in ipairs( self.points ) do
		table.insert(instances, point:Show(yLevel))
	end

	if self.divide then
		self.northeast:Show(yLevel, instances)
		self.northwest:Show(yLevel, instances)
		self.southeast:Show(yLevel, instances)
		self.southwest:Show(yLevel, instances)
	end

	return instances
end

-- // Module // --
local Module = {}

Module.Point = Point
Module.Rectangle = Rectangle
Module.QuadTree = QuadTree

return Module
