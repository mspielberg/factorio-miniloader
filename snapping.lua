local snapping = {}

local util = require("util")

local snapTypes = {
	["loader"] = true,
	["splitter"] = true,
	["underground-belt"] = true,
	["transport-belt"] = true
}

-- set loader direction according to adjacent belts
-- returns true if the loader and entity are directionally aligned
local function snap_loader_to_target(loader, entity, event)
	if not entity or not entity.valid or not loader or not loader.valid then
		log("Entity or Loader where invalid.")
		return
	end

	if not snapTypes[entity.type] then
		log(entity.type.." not a valid entity for loader connection")
		return
	end
	-- local targetio = nil
	-- if entity.type == "loader" then targetio = entity.belt_to_ground_type end
	-- if entity.type == "underground-belt" then targetio = entity.belt_to_ground_type end
	-- log("target: "..entity.name.." position: "..entity.position.x..","..entity.position.y.."	direction: "..entity.direction.." "..tostring(targetio))
	-- log("loader: "..loader.name.." position: "..loader.position.x..","..loader.position.y.."	direction: "..loader.direction.." "..loader.belt_to_ground_type)

	-- loader facing
	-- north 0: Loader 0 output or 4 input
	-- east	2: Loader 2 output or 6 input
	-- south 4: Loader 4 output or 0 input
	-- west	6: Loader 6 output or 2 input

	local lx = loader.position.x
	local ly = loader.position.y

	local ex = entity.position.x
	local ey = entity.position.y
	local edir = entity.direction

	local direction
	local belt_to_ground_type
	if lx == ex and (edir == 0 or edir == 4) then -- loader and entity are aligned vertically
		if ly > ey then -- entity to north
			if edir == 4 then
				direction = 4
				belt_to_ground_type = "input"
			else
				direction = 0
				belt_to_ground_type = "output"
			end
		else -- entity to south
			if edir == 0 then
				direction = 0
				belt_to_ground_type = "input"
			else
				direction = 4
				belt_to_ground_type = "output"
			end
		end
	elseif ly == ey and (edir == 2 or edir == 6) then -- loader and entity are aligned horizontally
		if lx > ex then -- entity to west
			if edir == 2 then
				direction = 2
				belt_to_ground_type = "input"
			else
				direction = 6
				belt_to_ground_type = "output"
			end
		else -- entity to east
			if edir == 6 then
				direction = 6
				belt_to_ground_type = "input"
			else
				direction = 2
				belt_to_ground_type = "output"
			end
		end
	end

	if belt_to_ground_type then
		if loader.direction ~= direction or loader.belt_to_ground_type ~= belt_to_ground_type then
			--loader.surface.create_entity{name="flying-text", position={loader.position.x-.25, loader.position.y-.5}, text = "^", color = {g=1}}
			util.update_miniloader(loader, direction, belt_to_ground_type)
		end
		return true
	end
	return false
end

-- returns loaders next to a given entity
local function find_loader_by_entity(entity)
	local position = entity.position
	local box = entity.prototype.selection_box
	local area = {
		{position.x + box.left_top.x - 1, position.y + box.left_top.y - 1},
		{position.x + box.right_bottom.x + 1, position.y + box.right_bottom.y + 1}
	}
	out = {}
	for _, entity in ipairs(entity.surface.find_entities_filtered{type="underground-belt", area=area, force=entity.force}) do
		if string.find(entity.name, "-miniloader$") ~= nil then
			table.insert(out, entity)
		end
	end
	return out
end

local function find_loader_by_underground_belt(entity)
	local direction = entity.direction
	if entity.belt_to_ground_type == "input" then
		direction = util.opposite_direction(direction)
	end
	local entities = entity.surface.find_entities_filtered{
		position = util.moveposition(entity.position, util.offset(direction, 1, 0)),
		type = "underground-belt",
	}
	for _, entity in ipairs(entities) do
		if util.is_miniloader(entity) then
			return entity
		end
	end
	return nil
end

-- returns entities in front and behind a given loader
local function find_entity_by_loader(loader)
	local x = loader.position.x
	local y = loader.position.y

	local areas = {
		{{x - 0.5, y - 1}, {x + 0.5, y + 1}},
		{{x - 1, y - 0.5}, {x + 1, y + 0.5}},
	}

	local out = {}
	for i=1, 2 do
		for _, ent in ipairs(loader.surface.find_entities_filtered{area=areas[i], force=loader.force}) do
			if ent ~= loader and ent.type ~= "player" then
				table.insert(out, ent)
			end
		end
	end
	return out
end

-- called when entity was rotated or non loader was built
function snapping.check_for_loaders(event)
	local entity = event.created_entity or event.entity
	if snapTypes[entity.type] then
		local loaders = find_loader_by_entity(entity)
		for _, loader in ipairs(loaders) do
			snap_loader_to_target(loader, entity, event)
				end

		-- also scan other exit of underground belt
		if entity.type == "underground-belt" then
			local partner = entity.neighbours
			if partner then
				local loader = find_loader_by_underground_belt(partner)
				if loader then
					snap_loader_to_target(loader, partner, event)
				end
			end
		end
	end
end

-- called when loader was built
function snapping.snap_loader(loader, event)
	local x = loader.position.x
	local y = loader.position.y
	local entities = find_entity_by_loader(loader)
	for _, ent in ipairs(entities) do
		-- log("target: "..ent.name.." position: "..ent.position.x..","..ent.position.y.."	direction: "..ent.direction)
		if snapTypes[ent.type] then
			if snap_loader_to_target(loader, ent, event) then
				return
			end
		else
			-- Idiot snapping, face away from non belt entities
			local bounds = util.move_box(ent.prototype.selection_box, ent.position)
			local direction = loader.direction
			if y > bounds.right_bottom.y then
				direction = 4
			elseif y < bounds.left_top.y then
				direction = 0
			elseif x > bounds.right_bottom.x then
				direction = 2
			elseif x < bounds.left_top.x then
				direction = 6
			end
			if loader.direction ~= direction or loader.belt_to_ground_type ~= "output" then
				--loader.surface.create_entity{name="flying-text", position={loader.position.x-.25, loader.position.y-.5}, text = "^", color = {r=1}}
				util.update_miniloader(loader, direction, "output")
				return
			end
		end
	end
end

return snapping
