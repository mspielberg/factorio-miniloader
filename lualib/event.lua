local M = {}

--[[
  handlers[event_id] = { handler1, handler2, ... }
]]
local handlers_for = {}

function M.dispatch(event)
  local handlers = handlers_for[event.name]
  if not handlers[1] then
    script.on_event(event.name, nil)
  end
  for i=1,#handlers do
    handlers[i](event)
  end
end

local function contains(list, elem)
  for i=1,#list do
    if list[i] == elem then
      return true
    end
  end
  return false
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

    if not handlers[1] then
      script.on_event(event_id, M.dispatch)
    end

    if not contains(handlers, handler) then
      handlers[#handlers+1] = handler
    end
  end
end

function M.unregister(events, handler)
  if type(events) ~= "table" then
    events = {events}
  end

  for _, event_id in ipairs(events) do
    local handlers = handlers_for[event_id]
    for i=1,#handlers do
      if handlers[i] == handler then
        table.remove(handlers, i)
      end
    end
  end
end

return M