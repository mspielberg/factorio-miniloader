require "util"

--[[
	belt_to_ground_type = "input"
	+------------------+
	|                  |
	|        P         |
	|                  |
	|                  |    |
	|        C         |    | chest dir
	|                  |    |
	|                  |    v
	|                  |
	+------------------+
	   D            D

	belt_to_ground_type = "output"
	+------------------+
	|                  |
	|  D            D  |
	|                  |
	|                  |    |
	|        C         |    | chest dir
	|                  |    |
	|                  |    v
	|                  |
	+------------------+
	         P

	C: miniloader-chest
	D: drop positions
	P: pickup position
]]

-- Constants

-- Utility Functions

local function moveposition(position, offset)
	return {x=position.x + offset.x, y=position.y + offset.y}
end

local function offset(direction, longitudinal, orthogonal)
	if direction == defines.direction.north then
		return {x=orthogonal, y=-longitudinal}
	end

	if direction == defines.direction.south then
		return {x=-orthogonal, y=longitudinal}
	end

	if direction == defines.direction.east then
		return {x=longitudinal, y=orthogonal}
	end

	if direction == defines.direction.west then
		return {x=-longitudinal, y=-orthogonal}
	end
end

local function opposite_direction(direction)
	if direction >= 4 then
		return direction - 4
	end
	return direction + 4
end

local function orthogonal_direction(direction)
	if direction == defines.direction.west then
		return defines.direction.north
	end
	return direction + 2
end

local function is_miniloader(entity)
	return string.find(entity.name, "-miniloader$") ~= nil
end

local function chest_direction(entity)
	if entity.belt_to_ground_type == "output" then
		return util.oppositedirection(entity.direction)
	end
	return entity.direction
end

local function pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return moveposition(entity.position, offset(opposite_direction(entity.direction), 0.75, 0))
	end
	return moveposition(entity.position, offset(entity.direction, -0.25, 0))
end

local function drop_positions(entity)
	if entity.belt_to_ground_type == "output" then
		local chest_dir = opposite_direction(entity.direction)
		local p1 = moveposition(entity.position, offset(chest_dir, -1, 0.25))
		local p2 = moveposition(p1, offset(chest_dir, 0, -0.5))
		return {p1, p2}
	end
	local chest_dir = entity.direction
	local p1 = moveposition(entity.position, offset(chest_dir, 0.75, 0.25))
	local p2 = moveposition(p1, offset(chest_dir, 0, -0.5))
	return {p1, p2}
end

local function get_loader_inserters(entity)
	return entity.surface.find_entities_filtered{
		position = entity.position,
		name = entity.name .. "-inserter"
	}
end

local function update_inserters(entity)
	local inserters = get_loader_inserters(entity)
	local chest_dir = chest_direction(entity)
	local pickup = pickup_position(entity, chest_dir)
	game.print("pickup = " .. serpent.line(pickup))
	local drop = drop_positions(entity, chest_dir)
	game.print("drop = " .. serpent.line(drop))

	-- drop inserters
	inserters[1].pickup_position = entity.position
	inserters[1].drop_position = drop[1]
	inserters[2].pickup_position = entity.position
	inserters[2].drop_position = drop[2]
	-- pickup inserter
	inserters[3].pickup_position = pickup
	inserters[3].drop_position = entity.position

	for i = 1, 3 do
		inserters[i].direction = inserters[i].direction
	end
end

-- Event Handlers

local function on_init()
	local force = game.create_force("miniloader")
	force.stack_inserter_capacity_bonus = 24
	-- allow miniloader force to access chests belonging to players
	game.forces["player"].set_friend(force, true)
	-- allow players to see power icons on miniloader inserters
	force.set_friend(game.forces["player"], true)
end

local function on_built(event)
	local entity = event.created_entity
	if not is_miniloader(entity) then
		return
	end
	local surface = entity.surface
	local chest = surface.create_entity{
		name = "miniloader-chest",
		position = entity.position,
		force = "miniloader",
	}
	chest.destructible = false
	for i = 1, 3 do
		local inserter = surface.create_entity{
			name = entity.name .. "-inserter",
			position = entity.position,
			force = "miniloader",
		}
		inserter.destructible = false
	end
	update_inserters(entity)
end

local function on_rotated(event)
	local entity = event.entity
	if not is_miniloader(entity) then
		return
	end
	update_inserters(entity)
end

local function on_mined(event)
	local entity = event.entity
	if not is_miniloader(entity) then
		return
	end

	local inserters = get_loader_inserters(entity)
	for i=1, #inserters do
		-- return items to player / robot if mined
		if event.buffer then
			event.buffer.insert(inserters[i].held_stack)
		end
		inserters[i].destroy()
	end

	local chest = entity.surface.find_entity("miniloader-chest", entity.position)
	if event.buffer then
		local chest_inventory = chest.get_inventory(defines.inventory.chest)
		if not chest_inventory.is_empty() then
			event.buffer.insert(chest_inventory[1])
		end
	end
	chest.destroy()
end

script.on_init(on_init)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)