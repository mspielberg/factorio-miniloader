local ontick = require "lualib.ontick"
local util = require "lualib.util"

local M = {}

-- how often to poll circuit network connections when the player is holding wire over an entity
local POLL_INTERVAL = 15

local NO_CONNECTIONS = 0
local ONLY_PARTNERS = 1
local ONLY_OTHERS = 2
local PARTNERS_AND_OTHERS = 3

function M.sync_filters(inserter)
  local filters = {}
  local slots = inserter.filter_slot_count
  for i=1,slots do
    filters[i] = inserter.get_filter(i)
  end
  local inserters = util.get_loader_inserters(inserter)
  for _, inserter in ipairs(inserters) do
    for j=1,slots do
      inserter.set_filter(j, filters[j])
    end
  end
end

function M.sync_behavior(inserter)
  local source_behavior = inserter.get_control_behavior()
  local inserters = util.get_loader_inserters(inserter)
  for _, inserter in ipairs(inserters) do
    if source_behavior then
      local behavior = inserter.get_or_create_control_behavior()
      behavior.circuit_read_hand_contents = source_behavior.circuit_read_hand_contents
      behavior.circuit_mode_of_operation = source_behavior.circuit_mode_of_operation
      behavior.circuit_hand_read_mode = source_behavior.circuit_hand_read_mode
      behavior.circuit_set_stack_size = false
      behavior.circuit_stack_control_signal = {type="item"}
      behavior.circuit_condition = source_behavior.circuit_condition
      behavior.logistic_condition = source_behavior.logistic_condition
      behavior.connect_to_logistic_network = source_behavior.connect_to_logistic_network
    end
    inserter.inserter_stack_size_override = 1
  end
end

-- tracking for wire connection changes

-- map from player_index to an array of the miniloader-inserters connected via circuit
-- to the player's selected entity
local selections = {}

local function connected_non_partners(inserters)
  local out = {[defines.wire_type.red] = {}, [defines.wire_type.green] = {}}
  for _, inserter in ipairs(inserters) do
    local connections = inserter.circuit_connection_definitions
    local pos = inserter.position
    for _, connection in ipairs(connections) do
      local wire_type = connection.wire
      local other = connection.target_entity
      local otherpos = other.position
      if otherpos.x ~= pos.x or otherpos.y ~= pos.y then
        out[wire_type][#out[wire_type]+1] = connection
      end
    end
  end
  return out
end

local function count_connections_on_wire(entity, wire_type)
  local count = 0
  for _, connection in ipairs(entity.circuit_connection_definitions) do
    if connection.wire == wire_type then
      count = count + 1
    end
  end
  return count
end

local function partner_connections_need_sync(inserters, connections)
  local master_inserter = inserters[1]
  for wire_type, wire_connections in pairs(connections) do
    local network = master_inserter.get_circuit_network(wire_type)
    if network then
      if not next(wire_connections) then
        return true
      end
      local network_id = network.network_id
      for i=2,#inserters do
        local slave_inserter = inserters[i]
        local slave_network = slave_inserter.get_circuit_network(wire_type)
        if not slave_network or slave_network.network_id ~= network_id then
          return true
        end
        if count_connections_on_wire(slave_inserter, wire_type) ~= 1 then
          return true
        end
      end
    else
      for i=2,#inserters do
        local slave_inserter = inserters[i]
        local slave_network = slave_inserter.get_circuit_network(wire_type)
        if slave_network then
          return true
        end
      end
    end
  end
  return false
end

function M.sync_partner_connections(inserter)
  local inserters = util.get_loader_inserters(inserter)
  local connections = connected_non_partners(inserters)

  if not partner_connections_need_sync(inserters, connections) then
    M.sync_behavior(inserter)
    return
  end

  local master_inserter = inserters[1]
  for wire_type, wire_connections in pairs(connections) do
    if not next(wire_connections) then
      for _, inserter in ipairs(inserters) do
        inserter.disconnect_neighbour(wire_type)
      end
    else
      master_inserter.disconnect_neighbour(wire_type)
      for i=2,#inserters do
        local inserter = inserters[i]
        inserter.disconnect_neighbour(wire_type)
        inserter.connect_neighbour{wire=wire_type, target_entity=master_inserter}
      end
      for _, wire_connection in ipairs(wire_connections) do
        master_inserter.connect_neighbour(wire_connection)
      end
    end
  end
  M.sync_behavior(inserter)
end

local function position_set(entities)
  local out = {}
  for _, entity in ipairs(entities) do
    if entity.valid then
      out[util.entity_key(entity)] = entity
    end
  end
  return out
end

local function diff_entity_lists(old, new)
  local old_positions = position_set(old)
  local new_positions = position_set(new)

  local removed = {}
  for old_pos, entity in pairs(old_positions) do
    if not new_positions[old_pos] then
      removed[#removed+1] = entity
    end
    new_positions[old_pos] = nil
  end

  local added = {}
  for _, entity in pairs(new_positions) do
    added[#added+1] = entity
  end
  return removed, added
end

local function find_connected_miniloader_inserters(entity)
  local connected = entity.circuit_connected_entities
  if not connected then
    return {}
  end
  local out = {}
  for _, entities in pairs(connected) do
    for _, e in ipairs(entities) do
      if util.is_miniloader_inserter(e) then
        out[#out+1] = e
      end
    end
  end
  return out
end

function M.update_connected_miniloader_inserters(entity)
  for _, inserter in ipairs(find_connected_miniloader_inserters(entity)) do
    M.sync_partner_connections(inserter)
  end
end

local function check_connected_entities(player_index, entity)
  local old = selections[player_index] or {}
  local new = find_connected_miniloader_inserters(entity)
  local removed, added = diff_entity_lists(old, new)
  for _, inserter in ipairs(removed) do
    M.sync_partner_connections(inserter)
  end
  for _, inserter in ipairs(added) do
    M.sync_partner_connections(inserter)
  end
  selections[player_index] = new
end

local function monitor_selections(event)
  if not next(selections) then
    ontick.unregister(monitor_selections)
    return
  end
  for player_index, old in pairs(selections) do
    local selected = game.players[player_index].selected
    if util.is_miniloader_inserter(selected) then
      M.sync_partner_connections(selected)
    end
    check_connected_entities(player_index, selected)
  end
end

local monitored_players = {}

local function start_monitoring_selection(player_index)
  local selected = game.players[player_index].selected
  if selected then
    selections[player_index] = find_connected_miniloader_inserters(selected)
    ontick.register(monitor_selections, POLL_INTERVAL)
    return
  end
  selections[player_index] = nil
end

local function on_selected_entity_changed(event)
  if not next(monitored_players) then
    script.on_event(defines.events.on_selected_entity_changed, nil)
    return
  end

  local player_index = event.player_index
  if not monitored_players[player_index] then
    return
  end

  if event.last_entity then
    check_connected_entities(player_index, event.last_entity)
  end

  start_monitoring_selection(player_index)
end

local function on_player_holding_wire(player_index)
  monitored_players[player_index] = true
  if selections[player_index] then
    -- already had selection, probably placed a wire
    monitor_selections()
  else
    start_monitoring_selection(player_index)
  end
  script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)
end

local function on_player_not_holding_wire(player_index)
  local selected = game.players[player_index].selected
  if selected then
    -- one last check since we will no longer be monitoring this player's selection
    check_connected_entities(player_index, selected)
  end
  monitored_players[player_index] = nil
  selections[player_index] = nil
end

local function on_player_cursor_stack_changed(event)
  local player_index = event.player_index
  local cursor_stack = game.players[player_index].cursor_stack
  if cursor_stack.valid_for_read then
    local name = cursor_stack.name
    if name == "red-wire" or name == "green-wire" then
      on_player_holding_wire(player_index)
      return
    end
  end
  on_player_not_holding_wire(player_index)
end

script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

return M