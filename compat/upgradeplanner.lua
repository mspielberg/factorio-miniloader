local util = require "lualib.util"

local M = {}

local saved_inserter_stacks = {}
local saved_loader_contents = {{}, {}}

function M.on_pre_player_mined_item(event)
  local entity = event.entity
  if not util.is_miniloader_inserter(entity) then
    return
  end

  -- upgrade-planner is about to try to fast replace an inserter, so let's prepare the way
  local inserters = util.get_loader_inserters(entity)
  for i=1,#inserters do
    local inserter = inserters[i]
    if inserter.held_stack.valid_for_read then
      saved_inserter_stacks[i] = inserter.held_stack
      inserter.held_stack.clear()
    end
    if inserter.unit_number ~= entity.unit_number then
      inserter.destroy()
    end
  end

  local loader = util.find_miniloaders{
    surface = entity.surface,
    position = entity.position,
  }[1]
  for i=1,2 do
    local tl = loader.get_transport_line(i)
    for j=1,#tl do
      saved_loader_contents[i][j] = tl[j]
    end
    tl.clear()
  end
  loader.destroy()
end

function M.on_built_entity(event)
  local entity = event.created_entity
  if not util.is_miniloader_inserter(entity) then
    return
  end

  -- restore contents, if possible
  local inserters = util.get_loader_inserters(entity)
  local loader = util.find_miniloaders{
    surface = entity.surface,
    position = entity.position,
  }[1]

  for i=1,#inserters do
    local inserter=inserters[i]
    inserter.held_stack.set_stack(saved_inserter_stacks[i])
    saved_inserter_stacks[i] = nil
  end

  -- check for any leftovers and give them to player, or spill if no room
  local player = game.players[event.player_index]
  for _, stack in pairs(saved_inserter_stacks) do
    if stack.valid_for_read then
      local inserted = player.insert(stack)
      if inserted < stack.count then
        player.remove_item{name = stack.name, count = inserted }
        player.surface.spill_item_stack(player.position, stack)
      end
      stack.clear()
    end
  end
  saved_inserter_stacks = {}

  for i=1,2 do
    local tl = loader.get_transport_line(i)
    for j=1,#saved_loader_contents[i] do
      tl.insert_at_back(saved_loader_contents[i][j])
    end
  end
  saved_loader_contents = {{}, {}}
end

return M