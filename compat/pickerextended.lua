local util = require("lualib.util")

-- compatibility with PickerExtended mod
local M = {}


local function on_dolly_moved(event)
  local player = game.players[event.player_index]
  local entity = event.moved_entity
  if util.is_miniloader_inserter(entity) then
    entity.teleport(event.start_pos)
    player.print({"picker-dollies.cant-be-teleported", entity.localised_name})
  end
end

function M.on_load()
  if remote.interfaces["picker"] and remote.interfaces["picker"]["dolly_moved_entity_id"] then
    local on_dolly_moved_event = remote.call("picker", "dolly_moved_entity_id")
    script.on_event(on_dolly_moved_event, on_dolly_moved)
  end
end

return M