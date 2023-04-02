local circuit = require "circuit"
local event = require "lualib.event"
local ontick = require "lualib.ontick"
local util = require "lualib.util"

-- how often to poll ControlBehavior settings when a miniloader-inserter GUI is open
local POLL_INTERVAL = 15

local function create_lane_swap_gui(parent, entity, switch_state)
  if parent.miniloader_lane_swap then
    parent.miniloader_lane_swap.destroy()
  end
  local frame = parent.add{
    type = "frame",
    name = "miniloader_lane_swap",
    direction = "horizontal",
    anchor = {
      gui = defines.relative_gui_type.inserter_gui,
      position = defines.relative_gui_position.top,
    },
  }
  local inner_frame = frame.add{
    type = "frame",
    name = "content",
    style = "inside_shallow_frame_with_padding",
  }
  inner_frame.style.horizontally_stretchable = false
  local flow = inner_frame.add{
    type = "flow",
    direction = "horizontal",
  }
  flow.style.horizontal_spacing = 20
  flow.add{
    type = "checkbox",
    name = "miniloader_split_lane_checkbox",
    caption = {"miniloader-gui.split-lane-configuration"},
    state = switch_state ~= "none",
  }
  flow.add{
    type = "switch",
    name = "miniloader_lane_switch",
    allow_none_state = true,
    left_label_caption = {"gui-splitter.left"},
    right_label_caption = {"gui-splitter.right"},
    switch_state = switch_state,
  }
  return frame
end

local monitored_entities

local function should_monitor_entity(entity)
  return util.is_miniloader_inserter(entity)
end

local function monitor_open_guis(_)
  for k, entity in pairs(monitored_entities) do
    if entity.valid then
      util.propagate_filters(entity)
      circuit.sync_behavior(entity)
    else
      monitored_entities[k] = nil
    end
  end
  if not next(monitored_entities) then
    ontick.unregister(monitor_open_guis)
  end
end

local function on_gui_opened(ev)
  local entity = ev.entity
  if not entity or not should_monitor_entity(entity) then
    return
  end
  monitored_entities[ev.player_index] = entity
  ontick.register(monitor_open_guis, POLL_INTERVAL)

  if util.is_output_miniloader_inserter(entity) then
    local player = game.get_player(ev.player_index)
    local relative = player.gui.relative
    local switch_state = "none"
    local split_cfg = util.get_split_configuration(entity)
    if split_cfg then
      local lane = util.get_inserter_lane(entity)
      if lane ~= nil then
        switch_state = lane
      elseif global.debug then
        game.print("on_gui_opened got inserter not set to lane")
      end
    end
    create_lane_swap_gui(relative, entity, switch_state)
  end
end

local function on_gui_closed(ev)
  local entity = ev.entity

  if not entity or not should_monitor_entity(entity) then
    return
  end

  circuit.sync_behavior(entity)
  util.propagate_filters(entity)
  monitored_entities[ev.player_index] = nil

  local player = game.get_player(ev.player_index)
  if player.gui.relative.miniloader_lane_swap then
    player.gui.relative.miniloader_lane_swap.destroy()
  end
end

local function on_gui_checked_state_changed(ev)
  local element = ev.element
  if element.name ~= "miniloader_split_lane_checkbox" then return end
  local player = game.get_player(ev.player_index)
  if player.opened_gui_type ~= defines.gui_type.entity then return end
  local entity = player.opened
  if not util.is_output_miniloader_inserter(entity) then return end

  local inserters = util.get_loader_inserters(entity)
  util.set_split_configuration(inserters[1], element.state and true or nil)
  element.parent.miniloader_lane_switch.switch_state = element.state and "left" or "none"
  local new_opened = inserters[1]
  for i=1,#inserters do
    if util.get_inserter_lane(inserters[i]) == "left" then
      new_opened = inserters[i]
      break
    end
  end
  player.opened = new_opened
end

local function on_gui_switch_state_changed(ev)
  local element = ev.element
  if element.name ~= "miniloader_lane_switch" then return end
  local player = game.get_player(ev.player_index)
  if player.opened_gui_type ~= defines.gui_type.entity then return end
  local entity = player.opened
  if not util.is_output_miniloader_inserter(entity) then return end

  local inserters = util.get_loader_inserters(entity)
  local main_inserter = inserters[1]
  util.set_split_configuration(entity, element.switch_state ~= "none" and true or nil)
  element.parent.miniloader_split_lane_checkbox.state = element.switch_state ~= "none"
  local lane = element.switch_state == "none" and "left" or element.switch_state
  local new_opened = main_inserter
  for i=1,#inserters do
    if util.get_inserter_lane(inserters[i]) == lane then
      new_opened = inserters[i]
      break
    end
  end
  player.opened = new_opened
end

local M = {}

function M.on_init()
  global.gui = {
    monitored_entities = {},
  }
  M.on_load()
end

function M.on_load()
  if not global.gui then
    return -- expect on_configuration_changed
  end
  monitored_entities = global.gui.monitored_entities
  if next(monitored_entities) then
    ontick.register(monitor_open_guis, POLL_INTERVAL)
  end
  event.register(defines.events.on_gui_opened, on_gui_opened)
  event.register(defines.events.on_gui_closed, on_gui_closed)
  event.register(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
  event.register(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
end

function M.on_configuration_changed()
  if not global.gui then
    global.gui = {
      monitored_entities = {},
    }
  end
  for _, player in pairs(game.players) do
    if player.gui.relative.miniloader_lane_swap then
      player.opened = nil
      player.gui.relative.miniloader_lane_swap.destroy()
    end
  end
  M.on_load()
end

return M
