local util = require("lualib.util")

local M = {}

local function inserters_in_position(bp_entities, starting_index)
  local out = {}
  local x = bp_entities[starting_index].position.x
  local y = bp_entities[starting_index].position.y
  for i=starting_index,#bp_entities do
    local ent = bp_entities[i]
    if ent.position.x == x and ent.position.y == y and util.is_miniloader_inserter(ent) then
      out[#out+1] = ent
    end
  end
  return out
end

local function count_connections(bp_entity)
  local out = 0
  if not bp_entity.connections then
    return 0
  end
  for _, circuit in pairs(bp_entity.connections) do
    for _, wire_connections in pairs(circuit) do
      out = out + #wire_connections
    end
  end
  return out
end

local function find_slaves(miniloader_inserters, to_remove)
  if not util.is_filter_miniloader_inserter(miniloader_inserters[1])
  or util.orientation_from_bp_inserter(miniloader_inserters[1]).type ~= "output" then
    to_remove[miniloader_inserters[2].entity_number] = true
  end
  for i = 3, #miniloader_inserters do
    local inserter = miniloader_inserters[i]
    to_remove[inserter.entity_number] = true
  end
end

local function remove_connections(bp_entity, to_remove_set)
  local connections = bp_entity.connections
  if not connections then
    return
  end
  for circuit_id, circuit_connections in pairs(connections) do
    if not circuit_id:find("^Cu") then -- ignore copper cables on power switch
      for wire_name, wire_connections in pairs(circuit_connections) do
        local new_wire_connections = {}
        for _, connection in ipairs(wire_connections) do
          if not to_remove_set[connection.entity_id] then
            new_wire_connections[#new_wire_connections+1] = connection
          end
        end
        if next(new_wire_connections) then
          circuit_connections[wire_name] = new_wire_connections
        else
          circuit_connections[wire_name] = nil
        end
      end
    end
  end
end

local function remove_entities(bp_entities, to_remove_set)
  local cnt = #bp_entities
  for i=1,cnt do
    remove_connections(bp_entities[i], to_remove_set)
  end

  local w = 1
  for r=1,cnt do
    if not to_remove_set[bp_entities[r].entity_number] then
      bp_entities[w] = bp_entities[r]
      w = w + 1
    end
  end
  for i=w,cnt do
    bp_entities[i] = nil
  end
end

function M.is_setup_bp(stack)
  return stack and
    stack.valid and
    stack.valid_for_read and
    stack.is_blueprint and
    stack.is_blueprint_setup()
end

local huge = math.huge
function M.bounding_box(bp_entities)
  local left = math.huge
  local top = math.huge
  local right = -math.huge
  local bottom = -math.huge

  for _, e in pairs(bp_entities) do
    local pos = e.position
    if pos.x < left then left = pos.x - 0.5 end
    if pos.y < top then top = pos.y - 0.5 end
    if pos.x > right then right = pos.x + 0.5 end
    if pos.y > bottom then bottom = pos.y + 0.5 end
  end

  local center_x = (right + left) / 2
  local center_y = (bottom + top) / 2

  return {
    left_top = {x = left - center_x, y = top - center_y},
    right_bottom = {x = right - center_x, y = bottom - center_y},
  }
end

function M.get_blueprint_to_setup(player_index)
  local player = game.players[player_index]

  -- normal drag-select
  local blueprint_to_setup = player.blueprint_to_setup
  if blueprint_to_setup
  and blueprint_to_setup.valid_for_read
  and blueprint_to_setup.is_blueprint_setup() then
    return blueprint_to_setup
  end

  -- alt drag-select (skips configuration dialog)
  local cursor_stack = player.cursor_stack
  if cursor_stack
  and cursor_stack.valid_for_read
  and cursor_stack.is_blueprint
  and cursor_stack.is_blueprint_setup() then
    local bp = cursor_stack
    while bp.is_blueprint_book do
      bp = bp.get_inventory(defines.inventory.item_main)[bp.active_index]
    end
    return bp
  end

  -- update of existing blueprint
  local opened_blueprint = global.previous_opened_blueprint_for[player_index]
  if  opened_blueprint
  and opened_blueprint.tick == game.tick
  and opened_blueprint.blueprint
  and opened_blueprint.blueprint.valid_for_read
  and opened_blueprint.blueprint.is_blueprint_setup() then
    return opened_blueprint.blueprint
  end
end

function M.filter_miniloaders(bp)
  local bp_entities = bp.get_blueprint_entities()
  if not bp_entities then
    return
  end
  local to_remove = {}
  local i = 1
  while i <= #bp_entities do
    local ent = bp_entities[i]
    if util.is_miniloader_inserter(ent) then
      local overlapping = inserters_in_position(bp_entities, i)
      find_slaves(overlapping, to_remove)
      i = i + #overlapping
    else
      i = i + 1
    end
  end
  if next(to_remove) then
    remove_entities(bp_entities, to_remove)
    bp.set_blueprint_entities(bp_entities)
  end
end

return M
