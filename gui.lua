local circuit = require "circuit"
local event = require "lualib.event"
local ontick = require "lualib.ontick"
local util = require "lualib.util"

-- how often to poll ControlBehavior settings when a miniloader-inserter GUI is open
local POLL_INTERVAL = 15

local function create_filter_miniloader_gui(parent, entity)
  local inserters = util.get_loader_inserters(entity)
  local frame = parent.add{
    type = "frame",
    name = "filter-miniloader-config",
    caption = entity.localised_name,
  }
  frame.auto_center = true
  local inner_frame = frame.add{
    type = "frame",
    name = "content",
    style = "entity_frame",
    direction = "vertical",
  }

  local preview_frame = inner_frame.add{
    type = "frame",
    style = "entity_button_frame",
  }
  local preview = preview_frame.add{
    type = "entity-preview",
    style = "wide_entity_button",
  }
  preview.entity = entity

  local columns = inner_frame.add{
    type = "flow",
  }

  local inserter = inserters[1]
  local left_column = columns.add{
    type = "flow",
    name = "filter-miniloader-config-left",
    direction = "vertical",
    style = "vertical_flow",
  }
  left_column.add{
    type = "label",
    caption = {"gui-splitter.left"},
  }
  local switch = left_column.add{
    type = "switch",
    name = "filter-miniloader-config-left-filter-mode-switch",
    left_label_caption = {"gui-inserter.whitelist"},
    right_label_caption = {"gui-inserter.blacklist"},
  }
  local filters = left_column.add{
    type = "frame",
    name = "filters",
    style = "slot_container_frame",
  }
  for i = 1, inserter.prototype.filter_count do
    filters.add{
      type = "choose-elem-button",
      name = "filter-miniloader-config-left-filter-button-" .. i,
      tags = { index = i },
      elem_type = "item",
      item = inserter.get_filter(i),
      style = "slot_button",
    }
  end

  inserter = inserters[2]
  local right_column = columns.add{
    type = "flow",
    name = "filter-miniloader-config-right",
    direction = "vertical",
    style = "vertical_flow",
  }
  right_column.add{
    type = "label",
    caption = {"gui-splitter.right"},
  }
  local switch = right_column.add{
    type = "switch",
    name = "filter-miniloader-config-right-filter-mode-switch",
    left_label_caption = {"gui-inserter.whitelist"},
    right_label_caption = {"gui-inserter.blacklist"},
  }
  local filters = right_column.add{
    type = "frame",
    name = "filters",
    style = "slot_container_frame",
  }
  for i = 1, inserter.prototype.filter_count do
    filters.add{
      type = "choose-elem-button",
      name = "filter-miniloader-config-right-filter-button-" .. i,
      tags = { index = i },
      elem_type = "item",
      item = inserter.get_filter(i),
      style = "slot_button",
    }
  end

  return frame
end

local monitored_entities

local function should_monitor_entity(entity)
  return util.is_miniloader_inserter(entity)
end

local function monitor_open_guis(_)
  for k, entity in pairs(monitored_entities) do
    if entity.valid then
      circuit.sync_filters(entity)
      circuit.sync_behavior(entity)
    else
      monitored_entities[k] = nil
    end
  end
  if not next(monitored_entities) then
    ontick.unregister(monitor_open_guis)
  end
end

local opening_filter_gui = false

local function on_gui_opened(ev)
  local entity = ev.entity
  if not entity or not should_monitor_entity(entity) then
    return
  end
  monitored_entities[ev.player_index] = entity
  ontick.register(monitor_open_guis, POLL_INTERVAL)

  if util.is_filter_miniloader_inserter(entity) then
    local miniloader = (util.find_miniloaders{surface = entity.surface, position = entity.position})[1]
    if miniloader and miniloader.loader_type == "output" then
      local player = game.get_player(ev.player_index)
      local screen = player.gui.screen
      opening_filter_gui = true
      player.opened = create_filter_miniloader_gui(screen, entity)
      opening_filter_gui = false
    end
  end
end

local function on_gui_closed(ev)
  local entity = ev.entity

  if ev.element and ev.element.name == "filter-miniloader-config" then
    ev.element.destroy()
    entity = monitored_entities[ev.player_index]
  end

  if not entity or not should_monitor_entity(entity) then
    return
  end

  if not opening_filter_gui then
    circuit.sync_behavior(entity)
    circuit.sync_filters(entity)
    monitored_entities[ev.player_index] = nil
  end
end

local function on_switch_state_changed(ev)
  local element = ev.element
  local player_index = ev.player_index
  local player = game.get_player(player_index)
  local entity = monitored_entities[player_index]
  local inserters = util.get_loader_inserters(entity)
  if element.name == "filter-miniloader-config-left-filter-mode-switch" then
    inserters[1].inserter_filter_mode = element.switch_state == "left" and "whitelist" or "blacklist"
  elseif element.name == "filter-miniloader-config-right-filter-mode-switch" then
    inserters[2].inserter_filter_mode = element.switch_state == "left" and "whitelist" or "blacklist"
  end
end

local function on_elem_changed(ev)
  local element = ev.element
  local element_name = element.name
  if not element_name:find("^filter%-miniloader%-config") then
    return
  end
  local inserter_index = element_name:find("left") and 1 or 2
  local entity = monitored_entities[ev.player_index]
  local inserters = util.get_loader_inserters(entity)
  inserters[inserter_index].set_filter(element.tags.index, element.elem_value)
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
  event.register(defines.events.on_gui_switch_state_changed, on_switch_state_changed)
  event.register(defines.events.on_gui_elem_changed, on_elem_changed)
end

function M.on_configuration_changed()
  if not global.gui then
    global.gui = {
      monitored_entities = {},
    }
  end
  M.on_load()
end

return M
