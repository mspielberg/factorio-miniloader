--[[
	belt_to_ground_type = "input"
	+------------------+
	|                  |
	|        P         |
	|                  |
	|                  |    |
	|                  |    | chest dir
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
	|                  |    | chest dir
	|                  |    |
	|                  |    v
	|                  |
	+------------------+
	         P

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

local function pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return moveposition(entity.position, offset(opposite_direction(entity.direction), 0.75, 0))
	end
	return moveposition(entity.position, offset(entity.direction, 0.25, 0))
end

local function drop_positions(entity)
	if entity.belt_to_ground_type == "output" then
		local chest_dir = opposite_direction(entity.direction)
		local p1 = moveposition(entity.position, offset(chest_dir, -0.25, 0.25))
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
	local pickup = pickup_position(entity)
	local drop = drop_positions(entity)

	local n = #inserters
	for i = 1, n / 2 do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[1]
		inserters[i].direction = inserters[i].direction
	end
	for i = n / 2 + 1, n do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[2]
		inserters[i].direction = inserters[i].direction
	end
end

local function num_inserters(entity)
	local speed = entity.prototype.belt_speed
	if speed < 0.1 then return 2
	else return 6 end
end

-- Event Handlers

local function on_init()
	local force = game.create_force("miniloader")
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
	for i = 1, num_inserters(entity) do
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
end

script.on_init(on_init)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)