local M = {}

--[[
  handlers[event_id] = { handler1, handler2, ... }
]]
local handlers_for = {}

function M.dispatch(event)
  local handlers = handlers_for[event.name]
  if not next(handlers) then
    script.on_event(event.name, nil)
    return
  end

  -- make copy since handlers may deregister themselves or other handlers
  for handler in pairs(handlers) do
    handler(event)
  end
end

function M.register(events, handler)
  if type(events) ~= "table" then
    events = {events}
  end

  for _, event_id in ipairs(events) do
    local handlers = handlers_for[event_id]
    if not handlers then
      handlers = {}
      handlers_for[event_id] = handlers
    end

    if not next(handlers) then
      script.on_event(event_id, M.dispatch)
    end

    handlers[handler] = true
  end
end

function M.unregister(events, handler)
  if type(events) ~= "table" then
    events = {events}
  end

  for _, event_id in ipairs(events) do
    local handlers = handlers_for[event_id]
    handlers[handler] = nil
  end
end

return M