local util = require("lualib.util")

local M = {}

-- assumes all entities in the same position are consecutive in bp_entities
local function inserters_in_position(bp_entities, starting_index, x, y)
  local out = {}
  for i=starting_index,#bp_entities do
    local ent = bp_entities[i]
    if ent.position.x == x and ent.position.y == y then
      if util.is_miniloader_inserter(ent) then
        out[#out+1] = ent
      end
    else
      return out
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

local function remove_entities(bp_entities, to_remove_set)
  local cnt = #bp_entities
  local w = 1
  for r=1,cnt do
    if not to_remove_set[bp_entities[r].entity_number] then
      bp_entities[w] = bp_entities[r]
      w = w + 1
    end
  end
  for i=w,cnt do
    bp_entities[w] = nil
  end
end

local function remove_connections(bp_entity, to_remove_set)
  if not bp_entity.connections then
    return
  end
  for _, circuit in pairs(bp_entity.connections) do
    for wire_name, wire_connections in pairs(circuit) do
      local new_wire_connections = {}
      for _, connection in ipairs(wire_connections) do
        if not to_remove_set[connection.entity_id] then
          new_wire_connections[#new_wire_connections+1] = connection
        end
      end
      if next(new_wire_connections) then
        circuit[wire_name] = new_wire_connections
      else
        circuit[wire_name] = nil
      end
    end
  end
end

-- expects a list of miniloader-inserter bp_entities in a single location
-- only the miniloader-inserter with the most circuit connections is retained,
-- the others are removed from bp_entities.
local function remove_slaves(bp_entities, miniloader_inserters)
  local most_connected_inserter
  local most_connections
  for _, inserter in ipairs(miniloader_inserters) do
    local num_connections = count_connections(inserter)
    if not most_connected_inserter or num_connections > most_connections then
      most_connected_inserter = inserter
      most_connections = num_connections
    end
  end

  -- iterate back over and remote dupes
  local to_remove_set = {}
  for i, inserter in ipairs(miniloader_inserters) do
    if inserter ~= most_connected_inserter then
      to_remove_set[inserter.entity_number] = true
    end
  end

  remove_connections(most_connected_inserter, to_remove_set)
  remove_entities(bp_entities, to_remove_set)
end

function M.is_setup_bp(stack)
  return stack.valid and
    stack.valid_for_read and
    stack.is_blueprint and
    stack.is_blueprint_setup()
end

function M.filter_miniloaders(bp)
  local bp_entities = bp.get_blueprint_entities()
  for i, ent in ipairs(bp_entities) do
    if util.is_miniloader_inserter(ent) then
      local overlapping = inserters_in_position(bp_entities, i, ent.position.x, ent.position.y)
      remove_slaves(bp_entities, overlapping)
    end
  end
  bp.set_blueprint_entities(bp_entities)
end

return M