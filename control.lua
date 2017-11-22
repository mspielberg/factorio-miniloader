require "util"

local function moveposition(position, direction, distance)
	if direction == defines.direction.north then
		return {x=position.x, y=position.y - distance}
	end

	if direction == defines.direction.south then
		return {x=position.x, y=position.y + distance}
	end

	if direction == defines.direction.east then
		return {x=position.x + distance, y=position.y}
	end

	if direction == defines.direction.west then
		return {x=position.x - distance, y=position.y}
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
	else
		return direction + 2
	end
end

local function chest_direction(entity)
	local dir = entity.direction
	if entity.belt_to_ground_type == "output" then
		return util.oppositedirection(dir)
	end
	return dir
end

local function get_loader_inserters(entity)
	return entity.surface.find_entities_filtered{
		area = {
			{entity.position.x - 0.3, entity.position.y - 0.3},
			{entity.position.x + 0.3, entity.position.y + 0.3},
		},
		name = "loader-inserter"
	}
end

local function update_inserters(entity)
	local inserters = get_loader_inserters(entity)
	local chest_dir = chest_direction(entity)
	local chest_position = moveposition(entity.position, chest_dir, 0.7)
	for i = 1, 2 do
		local inserter = inserters[i]
		if entity.belt_to_ground_type == "output" then
			inserter.pickup_position = chest_position
			inserter.drop_position = moveposition(inserter.position, chest_dir, 0.3)
		else
			inserter.pickup_position = moveposition(inserter.position, chest_dir, 0.3)
			inserter.drop_position = chest_position
		end
		inserter.direction = inserter.direction
	end
end

-- Event Handlers

local function on_init()
	local force = game.create_force("railloader")
	force.stack_inserter_capacity_bonus = 24
	-- allow railloader force to access chests belonging to players
	game.forces.player.set_friend(force, true)
end

local function on_built(event)
	local entity = event.created_entity
	if entity.name ~= "railloader" then
		return
	end
	local ortho = orthogonal_direction(entity.direction)
	local surface = entity.surface
	surface.create_entity{
		name = "loader-inserter",
		position = moveposition(entity.position, ortho, 0.25),
		force = "railloader",
	}
	surface.create_entity{
		name = "loader-inserter",
		position = moveposition(entity.position, ortho, -0.25),
		force = "railloader",
	}
	update_inserters(entity)
end

local function on_rotated(event)
	local entity = event.entity
	if entity.name ~= "railloader" then
		return
	end
	update_inserters(entity)
end

local function on_mined(event)
	local entity = event.entity
	if entity.name ~= "railloader" then
		return
	end
	for _, inserter in pairs(get_loader_inserters(entity)) do
		event.buffer.insert(inserter.held_stack)
		inserter.destroy()
	end
end

script.on_init(on_init)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)