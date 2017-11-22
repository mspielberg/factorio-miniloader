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

local function chest_direction(loader)
	local dir = loader.direction
	if loader.loader_type == "output" then
		return util.oppositedirection(dir)
	end
	return dir
end

local function inserter_position(loader)
	return moveposition(loader.position, chest_direction(loader), 0.5)
end

local function chest_position(loader)
	return moveposition(loader.position, chest_direction(loader), 1.5)
end

local function target_position(loader)
	return moveposition(loader.position, chest_direction(loader), 2.7)
end

local function get_loader_inserter(loader)
	return loader.surface.find_entity("loader-inserter", inserter_position(loader))
end

local function get_loader_chest(loader)
	return loader.surface.find_entity("steel-chest", chest_position(loader))
end

local function update_inserter(loader)
	local inserter = get_loader_inserter(loader)
	if loader.loader_type == "input" then
		inserter.pickup_position = chest_position(loader)
		inserter.drop_position = target_position(loader)
	else
		inserter.pickup_position = target_position(loader)
		inserter.drop_position = chest_position(loader)
	end
	inserter.direction = inserter.direction
end

local function on_built(event)
	local entity = event.created_entity
	if entity.type ~= "loader" then
		return
	end
	local surface = entity.surface
	surface.create_entity{
		name = "steel-chest",
		position = chest_position(entity),
		force = entity.force,
		--bar = 1,
	}
	local inserter = surface.create_entity{
		name = "loader-inserter",
		position = inserter_position(entity),
		force = entity.force,
	}
	update_inserter(entity)
	entity.update_connections()
end

local function on_rotated(event)
	local entity = event.entity
	if entity.type ~= "loader" then
		return
	end
	update_inserter(entity)
end

local function on_mined(event)
	local entity = event.entity
	if entity.type ~= "loader" then
		return
	end
	local inserter = get_loader_inserter(entity)
	event.buffer.insert(inserter.held_stack)
	inserter.destroy()
	local chest = get_loader_chest(entity)
	local chest_inventory = chest.get_inventory(defines.inventory.chest)
	for i = 1, #chest_inventory do
		event.buffer.insert(chest_inventory[i])
	end
	chest.destroy()
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)