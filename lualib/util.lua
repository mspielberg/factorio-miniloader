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

function util.rotate_position(position, direction)
  if direction == defines.direction.north then
    return position
  elseif direction == defines.direction.east then
    return { x = -position.y, y = position.x }
  elseif direction == defines.direction.south then
    return { x = -position.x, y = -position.y }
  elseif direction == defines.direction.west then
    return { x = position.y, y = -position.x }
  else
    error("invalid position passed to rotate_position")
  end
end

-- BoundingBox utilities

--[[
  +----------------------+
  |                      |
  |                      |
  |                      |
  |       O              |
  |                      |
  +----------------------+
]]
function util.rotate_box(box, direction)
  local left = box.left_top.x
  local top = box.left_top.y
  local right = box.right_bottom.x
  local bottom = box.right_bottom.y

  if direction == defines.direction.north then
    return box
  elseif direction == defines.direction.east then
    -- 90 degree rotation
    return {
      left_top = {x=-bottom, y=left},
      right_bottom = {x=-top, y=right},
    }
  elseif direction == defines.direction.south then
    -- 180 degree rotation
    return {
      left_top = {x=-right, y=-bottom},
      right_bottom = {x=-left, y=-top},
    }
  elseif direction == defines.direction.west then
    -- 270 degree rotation
    return {
      left_top = {x=top, y=-right},
      right_bottom = {x=bottom, y=-left},
    }
  else
    error('invalid direction passed to rotate_box')
  end
end

function util.move_box(box, offset)
  return {
    left_top = util.moveposition(box.left_top, offset),
    right_bottom = util.moveposition(box.right_bottom, offset),
  }
end

function util.expand_box(box, size)
  return {
    left_top = { x = box.left_top.x - size, y = box.left_top.y - size },
    right_bottom = { x = box.right_bottom.x + size, y = box.right_bottom.y + size },
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

-- orientation utilities

-- hood_side returns the "back" or hood side of a loader or underground belt
function util.hood_side(entity)
  if entity.type == "loader-1x1" and entity.loader_type == "output" then
    return util.opposite_direction(entity.direction)
  end
  if entity.type == "underground-belt" and entity.belt_to_ground_type == "output" then
    return util.opposite_direction(entity.direction)
  end
  return entity.direction
end

-- belt_side returns the "front" side of a loader or underground belt
function util.belt_side(entity)
  if entity.type == "loader-1x1" and entity.loader_type == "input" then
    return util.opposite_direction(entity.direction)
  end
  if entity.type == "underground-belt" and entity.belt_to_ground_type == "input" then
    return util.opposite_direction(entity.direction)
  end
  return entity.direction
end

-- miniloader utilities

function util.find_miniloaders(params)
  params.type = "loader-1x1"
  local entities = params.surface.find_entities_filtered(params)
  local out = {}
  for i=1,#entities do
    local ent = entities[i]
    if util.is_miniloader(ent) then
      out[#out+1] = ent
    end
  end
  return out
end

function util.is_miniloader(entity)
  return string.find(entity.name, "miniloader%-loader$") ~= nil
end

function util.is_miniloader_inserter(entity)
  return util.is_miniloader_inserter_name(entity.name)
end

function util.is_miniloader_inserter_name(name)
  return name:find("miniloader%-inserter$") ~= nil
end

function util.is_output_miniloader_inserter(inserter)
  local orientation = util.orientation_from_inserter(inserter)
  return orientation and orientation.type == "output"
end

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
local BELT_SPEED_FOR_60_PER_SECOND = 60/60/8
function util.num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / BELT_SPEED_FOR_60_PER_SECOND) * 2
end

function util.pickup_position(entity)
  if entity.loader_type == "output" then
    return util.moveposition(entity.position, util.offset(entity.direction, -0.8, 0))
  end
  return util.moveposition(entity.position, util.offset(entity.direction, -0.2, 0))
end

local moveposition = util.moveposition
local offset = util.offset
-- drop positions for input  (belt->chest) = { 0.7, +-0.25}, { 0.9, +-0.25}, {1.1, +-0.25}, {1.3, +-0.25}
-- drop positions for output (chest->belt) = {-0.2, +-0.25}, {-0.0, +-0.25}, {0.1, +-0.25}, {0.3, +-0.25}
function util.drop_positions(entity)
  local base_offset = 1.2
  if entity.loader_type == "output" then
    base_offset = base_offset - 1
  end
  local out = {}
  local dir = entity.direction
  local p1 = moveposition(entity.position, offset(dir, base_offset, -0.25))
  local p2 = moveposition(p1, offset(dir, 0, 0.5))
  out[1] = p1
  out[2] = p2
  for i=1,3 do
    local j = i * 2 + 1
    out[j  ] = moveposition(p1, offset(dir, -0.20*i, 0))
    out[j+1] = moveposition(p2, offset(dir, -0.20*i, 0))
  end
  for i=0,3 do
    local j = i * 2 + 9
    out[j  ] = moveposition(p1, offset(dir, -0.20*i, 0))
    out[j+1] = moveposition(p2, offset(dir, -0.20*i, 0))
  end
  return out
end

function util.get_loader_inserters(entity)
  local out = {}
  for _, e in pairs(entity.surface.find_entities_filtered{
    position = entity.position,
    type = "inserter",
  }) do
    if util.is_miniloader_inserter(e) then
      out[#out+1] = e
    end
  end
  return out
end

function util.get_inserter_lane(inserter, blueprint_entity)
  local factors = nil
  if inserter.direction == defines.direction.north
      or (blueprint_entity and inserter.direction == nil) then
    factors = {x=1, y=0}
  elseif inserter.direction == defines.direction.east then
    factors = {x=0, y=1}
  elseif inserter.direction == defines.direction.south then
    factors = {x=-1, y=0}
  elseif inserter.direction == defines.direction.west then
    factors = {x=0, y=-1}
  else
    error("invalid direction for miniloader inserter: ".. serpent.line(inserter.direction))
  end

  local base_position = inserter.position
  if blueprint_entity then
    base_position = { x=0, y=0 }
  end
  local left = (base_position.x - inserter.drop_position.x) * factors.x
             + (base_position.y - inserter.drop_position.y) * factors.y
  if left >= 0.2 then
    return "left"
  elseif left <= -0.2 then
    return "right"
  else
    return nil
  end
end

function util.get_loader_filter_settings(entity)
  local inserters = util.get_loader_inserters(entity)
  if #inserters < 1 or inserters[1].filter_slot_count < 1 then
    return nil
  end
  local settings = {
    split = false,
    mode = {left = "whitelist", right = "whitelist"},
    filters = {left = {}, right = {}}
  }
  for i=1,#inserters do
    if global.split_lane_configuration[inserters[i].unit_number] ~= nil then
      settings.split = global.split_lane_configuration[inserters[i].unit_number]
      break
    end
  end
  if settings.split == false or #inserters == 1 then
    settings.mode.left = inserters[1].inserter_filter_mode
    settings.mode.right = settings.mode.left
    for i=1,inserters[1].filter_slot_count do
      settings.filters.left[i] = inserters[1].get_filter(i)
      settings.filters.right[i] = settings.filters.left[i]
    end
    if global.split_lane_configuration[inserters[1].unit_number] then
      settings.split = true
    end
    return settings
  end

  local opposite_lane = { left = "right", right = "left" }
  local have_lanes = {left = false, right = false}
  for _, inserter in ipairs(inserters) do
    local inserter_lane = util.get_inserter_lane(inserter)
    if inserter_lane == nil then
      if global.debug then
        game.print(debug.traceback("get_loader_filter_settings found inserter not dropping on a lane ".. inserter.unit_number))
      end
    elseif not have_lanes[inserter_lane] then
      if inserter.inserter_filter_mode == nil then error("nil inserter mode") end
      settings.mode[inserter_lane] = inserter.inserter_filter_mode
      for i=1,inserter.filter_slot_count do
        settings.filters[inserter_lane][i] = inserter.get_filter(i)
      end
      have_lanes[inserter_lane] = true
      if have_lanes[opposite_lane[inserter_lane]] then
        break
      end
    end
  end
  if global.debug and not (have_lanes.left and have_lanes.right) then
    game.print("get_loader_filter_settings did not find inserters for both lanes")
    game.print("#inserters: ".. #inserters .." hvl: ".. serpent.line(have_lanes))
  end
  return settings
end

function util.get_split_configuration(entity)
  local inserters = util.get_loader_inserters(entity)
  local is_split = nil
  for i=1,#inserters do
    is_split = global.split_lane_configuration[inserters[i].unit_number]
    if  is_split ~= nil then
      break
    end
  end
  return is_split
end

function util.set_split_configuration(entity, is_split)
  local inserters = util.get_loader_inserters(entity)
  for i=1,#inserters do
    global.split_lane_configuration[inserters[i].unit_number] = nil
  end
  global.split_lane_configuration[inserters[1].unit_number] = is_split
end

local function update_miniloader_ghost(ghost, direction, type)
  local position = ghost.position
  -- We should normally destroy the ghost and recreate it facing the right direction,
  -- but destroying an entity during its on_built_entity handler makes for compatibility
  -- headaches.

  -- add offset within tile to inform orientation_from_inserters that this ghost is preconfigured
  if type == "input" then
    ghost.pickup_position = moveposition(position, offset(direction, 0.25, 0.25))
    ghost.drop_position = moveposition(position, offset(direction, 1, 0.25))
  else
    ghost.pickup_position = moveposition(position, offset(direction, -1, 0.25))
    ghost.drop_position = moveposition(position, offset(direction, 0.25, 0.25))
  end
end

function util.update_miniloader(entity, direction, type)
  if entity.type == "entity-ghost" and entity.ghost_type == "inserter" then
    return update_miniloader_ghost(entity, direction, type)
  end
  if entity.loader_type ~= type then
    entity.rotate()
  end
  entity.direction = direction
  util.update_inserters(entity)
end

function util.update_inserters(entity, filter_settings)
  if filter_settings == nil then
    filter_settings = util.get_loader_filter_settings(entity)
  end
  local inserters = util.get_loader_inserters(entity)
  local pickup = util.pickup_position(entity)
  local drop = util.drop_positions(entity)
  local direction = entity.direction
  local loader_type = entity.loader_type
  if loader_type == "input" then
    direction = util.opposite_direction(direction)
  end

  local swapped_items = { left = {}, right = {} }
  for i=1,#inserters do
    local original_lane = nil
    if inserters[i].held_stack.count ~= 0 then
      original_lane = util.get_inserter_lane(inserters[i])
    end
    -- Assigning direction will change drop/pickup positions so assign it first
    inserters[i].direction = direction
    inserters[i].drop_position = drop[i]
    inserters[i].pickup_position = pickup

    if loader_type == "input" then
      inserters[i].pickup_target = entity
    else
      inserters[i].drop_target = entity
    end

    if original_lane ~= nil then
      local final_lane = util.get_inserter_lane(inserters[i])
      if final_lane ~= original_lane then
        swapped_items[original_lane][#swapped_items[original_lane]+1] = inserters[i]
      end
    end
  end

  while #swapped_items.left ~= 0 and #swapped_items.right ~= 0 do
    local left_ix = #swapped_items.left
    local left_stack = swapped_items.left[left_ix].held_stack
    local right_ix = #swapped_items.right
    local right_stack = swapped_items.right[right_ix].held_stack
    if not left_stack.swap_stack(right_stack) then
      error("Could not swap held items between inserters")
    end
    swapped_items.left[left_ix] = nil
    swapped_items.right[right_ix] = nil
  end
  local next_check = 1
  for i=1,#swapped_items.left do
    if next_check > #inserters then
      if global.debug then
        game.print("Ran out of left lane inserters to swap items to")
      end
      break
    end
    for ci=next_check,#inserters do
      next_check = ci + 1
      if inserters[ci].held_stack.count == 0
          and util.get_inserter_lane(inserters[ci]) == "left" then
        target_stack = inserters[ci].held_stack
        source_stack = swapped_items.left[i].held_stack
        if not source_stack.swap_stack(target_stack) then
          error("Could not swap held item stack with empty inserter")
        end
        break
      end
    end
  end
  next_check = 1
  for i=1,#swapped_items.right do
    if next_check > #inserters then
      if global.debug then
        game.print("Ran out of right lane inserters to swap items to")
      end
      break
    end
    for ci=next_check,#inserters do
      next_check = ci + 1
      if inserters[ci].held_stack.count == 0
          and util.get_inserter_lane(inserters[ci]) == "right" then
        target_stack = inserters[ci].held_stack
        source_stack = swapped_items.right[i].held_stack
        if not source_stack.swap_stack(target_stack) then
          error("Could not swap held item stack with empty inserter")
        end
        break
      end
    end
  end

  util.update_filters(entity, filter_settings)
end

function util.update_filters(entity, settings)
  if settings == nil then return end
  local inserters = util.get_loader_inserters(entity)
  if #inserters < 1 or inserters[1].filter_slot_count == 0 then return end

  for i=1,#inserters do
    local lane = util.get_inserter_lane(inserters[i])
    if lane == nil then
      if global.debug then
        game.print("update_filters got inserter not assigned to a lane ".. inserters[i].unit_number)
      end
      lane = "left"
    end
    inserters[i].inserter_filter_mode = settings.mode[lane]
    for slot=1,inserters[i].filter_slot_count do
      inserters[i].set_filter(slot, settings.filters[lane][slot])
    end
    global.split_lane_configuration[inserters[i].unit_number] = nil
  end
  global.split_lane_configuration[inserters[1].unit_number] = settings.split
end

function util.propagate_filters(entity)
  local inserters = util.get_loader_inserters(entity)
  if #inserters < 1 or inserters[1].filter_slot_count == 0 then return end
  local target_lane = nil
  if util.get_split_configuration(entity) then
    target_lane = util.get_inserter_lane(entity)
    if not target_lane and global.debug then
      game.print("propagate_filters given non-lane inserter for lane propagation")
    end
  end
  local mode = entity.inserter_filter_mode
  local filters = {}
  for i=1,entity.filter_slot_count do
    filters[i] = entity.get_filter(i)
  end
  for i=1,#inserters do
    if target_lane == nil or util.get_inserter_lane(inserters[i]) == target_lane then
      inserters[i].inserter_filter_mode = mode
      for slot=1,inserters[i].filter_slot_count do
        inserters[i].set_filter(slot, filters[slot])
      end
    end
  end
end

function util.select_main_inserter(surface, position)
  local inserters = surface.find_entities_filtered{type = "inserter", position = position}
  if not next(inserters) then
    inserters = surface.find_entities_filtered{ghost_type = "inserter", position = position}
  end

  if not next(inserters) then return nil end
  for _, inserter in ipairs(inserters) do
    if inserter.pickup_target == nil and inserter.drop_target == nil then
      return inserter
    end
  end
  return inserters[1]
end

function util.orientation_from_bp_inserter(bp_inserter)
  local position_x = bp_inserter.position.x
  local position_y = bp_inserter.position.y
  local drop_position_x = bp_inserter.drop_position.x + position_x
  local drop_position_y = bp_inserter.drop_position.y + position_y
  local pickup_position_x = bp_inserter.pickup_position.x + position_x
  local pickup_position_y = bp_inserter.pickup_position.y + position_y
  if drop_position_x == position_x or drop_position_y == position_y then
    return nil -- freshly placed with no inherited positions
  elseif drop_position_x > position_x + 0.5 then
    return {direction=defines.direction.east, type="input"}
  elseif drop_position_x < position_x - 0.5 then
    return {direction=defines.direction.west, type="input"}
  elseif drop_position_y > position_y + 0.5 then
    return {direction=defines.direction.south, type="input"}
  elseif drop_position_y < position_y - 0.5 then
    return {direction=defines.direction.north, type="input"}
  elseif pickup_position_x > position_x + 0.5 then
    return {direction=defines.direction.west, type="output"}
  elseif pickup_position_x < position_x - 0.5 then
    return {direction=defines.direction.east, type="output"}
  elseif pickup_position_y > position_y + 0.5 then
    return {direction=defines.direction.north, type="output"}
  elseif pickup_position_y < position_y - 0.5 then
    return {direction=defines.direction.south, type="output"}
  end
end

function util.orientation_from_inserter(inserter)
  if inserter.drop_position.x == inserter.position.x and inserter.drop_position.y == inserter.position.y then
    return nil -- freshly placed with no inherited positions
  elseif inserter.drop_position.x > inserter.position.x + 0.5 then
    return {direction=defines.direction.east, type="input"}
  elseif inserter.drop_position.x < inserter.position.x - 0.5 then
    return {direction=defines.direction.west, type="input"}
  elseif inserter.drop_position.y > inserter.position.y + 0.5 then
    return {direction=defines.direction.south, type="input"}
  elseif inserter.drop_position.y < inserter.position.y - 0.5 then
    return {direction=defines.direction.north, type="input"}
  elseif inserter.pickup_position.x > inserter.position.x + 0.5 then
    return {direction=defines.direction.west, type="output", is_secondary=inserter.drop_position.y < inserter.position.y}
  elseif inserter.pickup_position.x < inserter.position.x - 0.5 then
    return {direction=defines.direction.east, type="output", is_secondary=inserter.drop_position.y > inserter.position.y}
  elseif inserter.pickup_position.y > inserter.position.y + 0.5 then
    return {direction=defines.direction.north, type="output", is_secondary=inserter.drop_position.x > inserter.position.x}
  elseif inserter.pickup_position.y < inserter.position.y - 0.5 then
    return {direction=defines.direction.south, type="output", is_secondary=inserter.drop_position.x < inserter.position.x}
  end
end

function util.orientation_from_inserters(entity)
  local inserter = util.select_main_inserter(entity.surface, entity.position)
  return util.orientation_from_inserter(inserter)
end

function util.rebuild_belt(entity)
  local surface = entity.surface
  local name = entity.name
  local protos = game.get_filtered_entity_prototypes{{filter="type", type=entity.type}}
  local temporary_replacement
  for proto_name in pairs(protos) do
    if proto_name ~= name and proto_name ~= "__self" then
      temporary_replacement = proto_name
      break
    end
  end
  if not temporary_replacement then return false end

  local last_user = entity.last_user
  local params = {
    name = temporary_replacement,
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    fast_replace = true,
    spill = false,
    create_build_effect_smoke = false,
    type = entity.type:find("loader") and entity.loader_type
      or entity.type == "underground-belt" and entity.belt_to_ground_type,
  }

  surface.create_entity(params)
  params.name = name
  local belt = surface.create_entity(params)

  if belt then
    belt.last_user = last_user
    return true
  else
    return false
  end
end

local control_behavior_keys = {
  "circuit_condition", "logistic_condition", "connect_to_logistic_network",
  "circuit_read_hand_contents", "circuit_mode_of_operation", "circuit_hand_read_mode", "circuit_set_stack_size", "circuit_stack_control_signal",
}

function util.capture_settings(ghost)
  local control_behavior = ghost.get_or_create_control_behavior()
  local control_behavior_state = {}
  for _, key in pairs(control_behavior_keys) do
    control_behavior_state[key] = control_behavior[key]
  end

  local filters = {}
  for i=1,ghost.filter_slot_count do
    filters[i] = ghost.get_filter(i)
  end

  return {
    control_behavior = control_behavior_state,
    filters = filters,
  }
end

function util.apply_settings(settings, inserter)
  local control_behavior = inserter.get_or_create_control_behavior()
  for k, v in pairs(settings.control_behavior) do
    control_behavior[k] = v
  end
end


return util
