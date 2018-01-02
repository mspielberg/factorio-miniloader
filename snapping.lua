local snapping = {}

local util = require("lualib.util")

local snapTypes = {
	["loader"] = true,
	["splitter"] = true,
	["underground-belt"] = true,
	["transport-belt"] = true
}

-- set loader direction according to adjacent belts
-- returns true if the loader and entity are directionally aligned
local function snap_loader_to_target(loader, entity)
	local lx = loader.position.x
	local ly = loader.position.y
	local ldir = loader.direction

	local ex = entity.position.x
	local ey = entity.position.y
	local edir = entity.direction

	local direction
	local belt_to_ground_type
	if lx == ex and util.is_ns(ldir) then
		-- loader and entity are aligned vertically
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
	elseif ly == ey and util.is_ew(ldir) then
		-- loader and entity are aligned horizontally
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

	if not belt_to_ground_type then
		-- loader and entity are not aligned
		return false
	end

	if direction ~= ldir or loader.belt_to_ground_type ~= belt_to_ground_type then
		util.update_miniloader(loader, direction, belt_to_ground_type)
	end
	return true
end

-- Idiot snapping, face away from non belt entity
local function idiot_snap(loader, entity)
	local x = loader.position.x
	local y = loader.position.y
	local bounds = util.move_box(entity.prototype.selection_box, entity.position)
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
	local loaders = util.find_miniloaders{
		surface = entity.surface,
		type="underground-belt",
		area=area,
		force=entity.force,
	}
	local out = {}
	for _, loader in ipairs(loaders) do
		local lpos = loader.position
		if lpos.x ~= position.x or lpos.y ~= position.y then
			out[#out+1] = loader
		end
	end
	return out
end

-- returns the miniloader connected to the belt of `entity`, if it exists
local function find_loader_by_underground_belt(ug_belt)
	local ug_dir = util.belt_side(ug_belt)
	local entities = ug_belt.surface.find_entities_filtered{
		position = util.moveposition(ug_belt.position, util.offset(ug_dir, 1, 0)),
		type = "underground-belt",
	}
	for _, ent in ipairs(entities) do
		if util.is_miniloader(ent) and util.underground_side(ent) == ug_dir then
			return ent
		end
	end
	return nil
end

-- returns entities in front and behind a given loader
local function find_entity_by_loader(loader)
	local positions = {
		util.moveposition(loader.position, util.offset(util.belt_side(loader), 1, 0)),
		util.moveposition(loader.position, util.offset(util.underground_side(loader), 1, 0)),
	}

	local out = {}
	for i = 1, #positions do
		local neighbors = loader.surface.find_entities_filtered{
			position=positions[i],
			force=loader.force,
		}
		for _, ent in ipairs(neighbors) do
			if ent.type ~= "player" then
				out[#out+1] = ent
			end
		end
	end
	return out
end

-- called when entity was rotated or non loader was built
function snapping.check_for_loaders(event)
	local entity = event.created_entity or event.entity
	if not snapTypes[entity.type] then
		return
	end

	local loaders = find_loader_by_entity(entity)
	for _, loader in ipairs(loaders) do
		snap_loader_to_target(loader, entity)
	end

	-- also scan other exit of underground belt
	if entity.type == "underground-belt" then
		local partner = entity.neighbours
		if partner then
			local loader = find_loader_by_underground_belt(partner)
			if loader then
				snap_loader_to_target(loader, partner)
			end
		end
	end
end

-- called when loader was built
function snapping.snap_loader(loader, event)
	local entities = find_entity_by_loader(loader)
	for _, ent in ipairs(entities) do
		if snapTypes[ent.type] and snap_loader_to_target(loader, ent) then
			return
		end
	end
	for _, ent in ipairs(entities) do
		if not snapTypes[ent.type] and idiot_snap(loader, ent) then
			return
		end
	end
end

return snapping