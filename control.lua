require "util"

-- Constants

-- Utility Functions

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

local function is_railloader(entity)
	return string.find(entity.name, "^railloader") ~= nil
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
		position = entity.position,
		name = "railloader-inserter"
	}
end

local function update_inserters(entity)
	local inserters = get_loader_inserters(entity)
	local chest_dir = chest_direction(entity)
	local belt_base_position = moveposition(entity.position, chest_dir, 0.25)
	local ortho = orthogonal_direction(entity.direction)
	for i = 1, 2 do
		local inserter = inserters[i]
		local ortho_offset = (i == 1) and 0.25 or -0.25
		local longi_offset = 0.5
		local belt_position = moveposition(belt_base_position, ortho, ortho_offset)
		local chest_position = moveposition(belt_position, chest_dir, longi_offset)
		if entity.belt_to_ground_type == "output" then
			inserter.pickup_position = chest_position
			inserter.drop_position = belt_position
		else
			inserter.pickup_position = belt_position
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
	game.forces["player"].set_friend(force, true)
	-- allow players to see power icons on railloader inserters
	force.set_friend(game.forces["player"], true)
end

local function on_built(event)
	local entity = event.created_entity
	if not is_railloader(entity) then
		return
	end
	local ortho = orthogonal_direction(entity.direction)
	local surface = entity.surface
	for i = 1, 2 do
		local inserter = surface.create_entity{
			name = "railloader-inserter",
			position = entity.position,
			force = "railloader",
		}
		inserter.destructible = false
	end
	update_inserters(entity)
end

local function on_rotated(event)
	local entity = event.entity
	if not is_railloader(entity) then
		return
	end
	update_inserters(entity)
end

local function on_mined(event)
	local entity = event.entity
	if not is_railloader(entity) then
		return
	end
	for _, inserter in pairs(get_loader_inserters(entity)) do
		-- return items to player / robot if mined
		if event.buffer then
			event.buffer.insert(inserter.held_stack)
		end
		inserter.destroy()
	end
end

script.on_init(on_init)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)