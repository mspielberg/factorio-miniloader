local circuit = require "circuit"
local ontick = require "lualib.ontick"
local util = require "lualib.util"

-- how often to poll ControlBehavior settings when a miniloader-inserter GUI is open
local POLL_INTERVAL = 15

local monitored_inserters = {}

local function monitor_open_guis(event)
  if not next(monitored_inserters) then
    ontick.unregister(monitor_open_guis)
  end
  for _, entity in pairs(monitored_inserters) do
    circuit.sync_filters(entity)
    circuit.sync_behavior(entity)
  end
end

local function on_gui_opened(event)
  local entity = event.entity
  if entity and util.is_miniloader_inserter(entity) then
    local key = util.entity_key(entity)
    monitored_inserters[key] = entity
    ontick.register(monitor_open_guis, POLL_INTERVAL)
  end
end

local function on_gui_closed(event)
  local entity = event.entity
  if entity and util.is_miniloader_inserter(entity) then
    circuit.sync_behavior(entity)
    circuit.sync_filters(entity)
    monitored_inserters[util.entity_key(entity)] = nil
  end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
