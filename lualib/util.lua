local util = {}

-- Position adjustments

function util.moveposition(position, offset)
	return {x=position.x + offset.x, y=position.y + offset.y}
end

function util.offset(direction, longitudinal, orthogonal)
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

function util.move_box(box, offset)
	return {
		left_top = util.moveposition(box.left_top, offset),
		right_bottom = util.moveposition(box.right_bottom, offset),
	}
end

function util.entity_key(entity)
	return entity.surface.name.."@"..entity.position.x..","..entity.position.y
end

-- Direction utilities

function util.is_ns(direction)
	return direction == 0 or direction == 4
end

function util.is_ew(direction)
	return direction == 2 or direction == 6
end

function util.opposite_direction(direction)
	if direction >= 4 then
		return direction - 4
	end
	return direction + 4
end

-- underground-belt utilities

-- underground_side returns the "back" or hood side of the underground belt
function util.underground_side(ug_belt)
	if ug_belt.belt_to_ground_type == "output" then
		return util.opposite_direction(ug_belt.direction)
	end
	return ug_belt.direction
end

-- belt_side returns the "front" side of the underground belt
function util.belt_side(ug_belt)
	if ug_belt.belt_to_ground_type == "input" then
		return util.opposite_direction(ug_belt.direction)
	end
	return ug_belt.direction
end

-- miniloader utilities

function util.find_miniloaders(params)
	params.type = "underground-belt"
	local entities = params.surface.find_entities_filtered(params)
	out = {}
	for i=1,#entities do
		local ent = entities[i]
		if  util.is_miniloader(ent) and ent ~= entity then
			out[#out+1] = ent
		end
	end
	return out
end

function util.is_miniloader(entity)
	return string.find(entity.name, "miniloader$") ~= nil
end

function util.is_miniloader_inserter(entity)
	return string.find(entity.name, "miniloader%-inserter$") ~= nil
end

function util.pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return util.moveposition(entity.position, util.offset(entity.direction, -0.75, 0))
	end
	return util.moveposition(entity.position, util.offset(entity.direction, 0.25, 0))
end

function util.drop_positions(entity)
	if entity.belt_to_ground_type == "output" then
		local dir = entity.direction
		local p1 = util.moveposition(entity.position, util.offset(dir, 0.25, -0.25))
		local p2 = util.moveposition(p1, util.offset(dir, 0, 0.5))
		return {p1, p2}
	end
	local dir = entity.direction
	local p1 = util.moveposition(entity.position, util.offset(dir, 0.75, -0.25))
	local p2 = util.moveposition(p1, util.offset(dir, 0, 0.5))
	return {p1, p2}
end

function util.get_loader_inserters(entity)
	return entity.surface.find_entities_filtered{
		position = entity.position,
		type = "inserter",
	}
end

function util.update_miniloader(entity, direction, type)
	if entity.belt_to_ground_type ~= type then
		entity.rotate()
	end
	entity.direction = direction
	util.update_inserters(entity)
end

function util.update_inserters(entity)
	local inserters = util.get_loader_inserters(entity)
	local pickup = util.pickup_position(entity)
	local drop = util.drop_positions(entity)

	local n = #inserters
	for i=1,n / 2 do
		inserters[i].direction = entity.direction
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[1]
		inserters[i].direction = inserters[i].direction
	end
	for i=n / 2 + 1,n do
		inserters[i].direction = entity.direction
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[2]
		inserters[i].direction = inserters[i].direction
	end
end

function util.num_inserters(entity)
	local speed = entity.prototype.belt_speed
	if speed < 0.1 then return 2
	else return 6 end
end

return util