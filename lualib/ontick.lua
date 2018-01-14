--[[
    Utilities for managing the on_tick event, periodically invoking
    handlers.
]]

local M = {}

local on_tick_handlers = {}
local function on_tick_meta_handler(event)
  if not next(on_tick_handlers) then
    script.on_event(defines.events.on_tick, nil)
    return
  end
  for handler, config in pairs(on_tick_handlers) do
    if (event.tick - config[2]) % config[1] == 0 then
      handler(event)
    end
  end
end

function M.register(f, interval)
  if not interval then
    interval = 12
  end
  if interval < 0 then
    error("invalid interval")
  end
  math.randomseed(game.tick)
  local offset = math.random(interval) - 1
  on_tick_handlers[f] = { interval, offset }
  script.on_event(defines.events.on_tick, on_tick_meta_handler)
end

function M.unregister(f)
  on_tick_handlers[f] = nil
end

return M