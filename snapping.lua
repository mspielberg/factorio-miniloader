local snapping = {}

local util = require("lualib.util")

local belt_types = {
  ["loader"] = true,
  ["loader-1x1"] = true,
  ["splitter"] = true,
  ["underground-belt"] = true,
  ["transport-belt"] = true
}

local function is_belt(entity)
  return belt_types[entity.type] or entity.type == "entity-ghost" and belt_types[entity.ghost_type]
end

-- set loader direction according to adjacent belts
-- returns true if the loader and entity are directionally aligned
local function snap_loader_to_target(loader, entity)
  local lx = loader.position.x
  local ly = loader.position.y
  local ldir = loader.direction

  local ex = entity.position.x
  local ey = entity.position.y
  local edir = entity.direction

  local direction
  local type
  if util.is_ns(ldir) and lx >= ex-0.6 and lx <= ex+0.6 then
    -- loader and entity are aligned vertically
    if ly > ey then -- entity to north
      if edir == 4 then
        direction = 4
        type = "input"
      else
        direction = 0
        type = "output"
      end
    else -- entity to south
      if edir == 0 then
        direction = 0
        type = "input"
      else
        direction = 4
        type = "output"
      end
    end
  elseif util.is_ew(ldir) and ly >= ey-0.6 and ly <= ey+0.6 then
    -- loader and entity are aligned horizontally
    if lx > ex then -- entity to west
      if edir == 2 then
        direction = 2
        type = "input"
      else
        direction = 6
        type = "output"
      end
    else -- entity to east
      if edir == 6 then
        direction = 6
        type = "input"
      else
        direction = 2
        type = "output"
      end
    end
  end

  if not type then
    -- loader and entity are not aligned
    return false
  end

  if direction ~= ldir or loader.type == "entity-ghost" or loader.loader_type ~= type then
    util.update_miniloader(loader, direction, type)
  end
  return true
end

-- returns distance between p1 and p2 projected along half-axis identified by dir
local function axis_distance(p1, p2, dir)
  if dir == 0 then
    return p1.y - p2.y
  elseif dir == 2 then
    return p2.x - p1.x
  elseif dir == 4 then
    return p2.y - p1.y
  elseif dir == 6 then
    return p1.x - p2.x
  end
end

local function is_source_dir(ent1, ent2)
  local e1dir = ent1.direction
  local e1p = ent1.position
  local e2p = ent2.position
  local distance = axis_distance(e2p, e1p, e1dir)
  local opp_distance = axis_distance(e2p, e1p, util.opposite_direction(e1dir))
  if  opp_distance > distance then
    return false
  else
    return true
  end
end

-- Face away from non belt entities and set to output
local function snap_loader_to_entities(loader, entities)
  local direction = loader.direction
  local source_dir_filled = false
  local dest_dir_filled = false
  for _, ent in ipairs(entities) do
    if not is_belt(ent) then
      if is_source_dir(loader, ent) then
        source_dir_filled = true
        if dest_dir_filled then
          break
        end
      else
        dest_dir_filled = true
        if source_dir_filled then
          break
        end
      end
    end
  end
  if source_dir_filled and dest_dir_filled then
    if loader.type ~= "entity-ghost" and loader.loader_type ~= "output" then
      direction = util.opposite_direction(direction)
    end
  elseif dest_dir_filled then
    direction = util.opposite_direction(direction)
  end
  if source_dir_filled or dest_dir_filled then
    util.update_miniloader(loader, direction, "output")
  end
end

-- returns loaders next to a given entity
local function find_loader_by_entity(entity)
  local position = entity.position
  local box = entity.prototype.selection_box
  local area = {
    {position.x + box.left_top.x - 1, position.y + box.left_top.y - 1},
    {position.x + box.right_bottom.x + 1, position.y + box.right_bottom.y + 1}
  }
  local loaders = util.find_miniloaders{
    surface = entity.surface,
    area=area,
    force=entity.force,
  }
  local out = {}
  for _, loader in ipairs(loaders) do
    local lpos = loader.position
    if lpos.x ~= position.x or lpos.y ~= position.y then
      out[#out+1] = loader
    end
  end
  return out
end

-- returns the miniloader connected to the belt of `entity`, if it exists
local function find_loader_by_underground_belt(ug_belt)
  local ug_dir = util.belt_side(ug_belt)
  local loader = util.find_miniloaders{
    surface = ug_belt.surface,
    position = util.moveposition(ug_belt.position, util.offset(ug_dir, 1, 0)),
  }[1]
  if loader and util.hood_side(loader) == ug_dir then
    return loader
  end
  return nil
end

local function is_snapping_target(entity)
  local prototype = entity.type == "entity-ghost" and entity.ghost_prototype or entity.prototype
  return prototype.has_flag("player-creation") and not prototype.has_flag("placeable-off-grid")
end

-- returns entities in front and behind a given loader
local function find_entity_by_loader(loader)
  local positions = {
    util.moveposition(loader.position, util.offset(loader.direction, 1, 0)),
    util.moveposition(loader.position, util.offset(loader.direction, -1, 0)),
  }

  local out = {}
  for i = 1, #positions do
    local neighbors = loader.surface.find_entities_filtered{
      position=positions[i],
      force=loader.force,
    }
    for _, ent in ipairs(neighbors) do
      if is_snapping_target(ent) then
        out[#out+1] = ent
      end
    end
  end
  return out
end

-- called when entity was rotated or non loader was built
function snapping.check_for_loaders(event)
  local entity = event.created_entity or event.entity
  if not is_belt(entity) then
    return
  end

  local loaders = find_loader_by_entity(entity)
  for _, loader in ipairs(loaders) do
    snap_loader_to_target(loader, entity)
  end

  -- also scan other exit of underground belt
  if entity.type == "underground-belt" then
    local partner = entity.neighbours
    if partner then
      local loader = find_loader_by_underground_belt(partner)
      if loader then
        snap_loader_to_target(loader, partner)
      end
    end
  end
end

-- called when loader was built
function snapping.snap_loader(loader)
  local entities = find_entity_by_loader(loader)
  for _, ent in ipairs(entities) do
    if is_belt(ent) and snap_loader_to_target(loader, ent) then
      return
    end
  end
  snap_loader_to_entities(loader, entities)
end

return snapping
