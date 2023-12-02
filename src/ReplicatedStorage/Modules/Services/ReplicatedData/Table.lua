local HttpService = game:GetService("HttpService")

export type deltaTable = {
	["Edits"] : { [any] : any },
	["Removals"] : { any }
}

-- // Module // --
local Module = {}

function Module.DictKeys( dict )
	local Keys = {}
	for key, _ in pairs(dict) do
		table.insert(Keys, key)
	end
	return Keys
end

function Module.readDeltaTable( old, new ) : deltaTable
	local edits = {}
	for propName, propValue in pairs( new ) do
		-- if value does not exist in the old table, was added
		local oldValue = old[propName]
		if oldValue == nil then
			-- print("New index addition: ", propName)
			edits[propName] = propValue
			continue
		end

		if typeof(propValue) == 'Instance' or typeof(oldValue) == "Instance" then
			if propValue ~= oldValue then
				-- print("Instance at index changed: ", propName)
				edits[propName] = propValue
			end
		elseif typeof(propValue) == "table" and typeof(oldValue) == "table" then
			-- table has not changed
			if HttpService:JSONEncode(propValue) == HttpService:JSONEncode(oldValue) then
				continue
			end
			-- has changed (deepDeltaTable?)
			edits[propName] = propValue
		elseif HttpService:JSONEncode(propValue) ~= HttpService:JSONEncode(oldValue) then
			-- print("Value(s) at index changed: ", propName)
			edits[propName] = propValue
		end
	end

	-- find any deleted items
	local removals = {}
	for propName, _ in pairs( old ) do
		if new[propName] == nil then
			table.insert(removals, propName)
		end
	end

	return {Edits = edits, Removals = removals}
end

function Module.applyDeltaTable( target, delta : deltaTable )
	for propName, propValue in pairs( delta.Edits ) do
		target[propName] = propValue
	end
	for _, propName in ipairs( delta.Removals ) do
		target[propName] = nil
	end
end

function Module.DeepCopy(passed_table)
	local clonedTable = {}
	if typeof(passed_table) == "table" then
		for k,v in pairs(passed_table) do
			clonedTable[Module.DeepCopy(k)] = Module.DeepCopy(v)
		end
	else
		clonedTable = passed_table
	end
	return clonedTable
end

return Module
