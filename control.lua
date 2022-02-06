local blueprint = require("lualib.blueprint")
local circuit = require("circuit")
local configchange = require("configchange")
local event = require("lualib.event")
local miniloader = require("lualib.miniloader")
local gui = require("gui")
local snapping = require("snapping")
local util = require("lualib.util")

local compat_pickerextended = require("compat.pickerextended")

local use_snapping = settings.global["miniloader-snapping"].value

--[[
  loader_type = "input"
  +------------------+
  |                  |
  |        P         |
  |                  |
  |                  |    |
  |                  |    | chest dir
  |                  |    |
  |                  |    v
  |                  |
  +------------------+
     D            D
--
  loader_type = "output"
  +------------------+
  |                  |
  |  D            D  |
  |                  |
  |                  |    |
  |                  |    | chest dir
  |                  |    |
  |                  |    v
  |                  |
  +------------------+
           P
--
  D: drop positions
  P: pickup position
]]

local function register_bobs_blacklist()
  for _, interface_name in ipairs{"bobinserters", "boblogistics"} do
    local interface = remote.interfaces[interface_name]
    if interface and interface["blacklist_inserter"] then
      for entity_name in pairs(game.entity_prototypes) do
        if util.is_miniloader_inserter_name(entity_name) then
          remote.call(interface_name, "blacklist_inserter", entity_name)
        end
      end
    end
  end
end

-- Event Handlers

local function on_init()
  global.player_placed_blueprint = {}
  global.previous_opened_blueprint_for = {}
  circuit.on_init()
  compat_pickerextended.on_load()
  gui.on_init()
  register_bobs_blacklist()
end

local function on_load()
  circuit.on_load()
  compat_pickerextended.on_load()
  gui.on_load()
end

local function on_configuration_changed(configuration_changed_data)
  local mod_change = configuration_changed_data.mod_changes["miniloader"]
  if mod_change and mod_change.old_version and mod_change.old_version ~= mod_change.new_version then
    configchange.on_mod_version_changed(mod_change.old_version)
    circuit.on_configuration_changed()
    gui.on_configuration_changed()
  end
  register_bobs_blacklist()
  configchange.fix_inserter_counts()
end


local function on_built_miniloader(entity, orientation)
  if not orientation then
    orientation = {direction = util.opposite_direction(entity.direction), type = "input"}
  end
  return miniloader.fixup(entity, orientation)
end

local function on_robot_built(ev)
  local entity = ev.created_entity
  if util.is_miniloader_inserter(entity) then
    on_built_miniloader(entity, util.orientation_from_inserters(entity))
  end
end

local function on_script_built(ev)
  local entity = ev.entity
  if entity and util.is_miniloader_inserter(entity) then
    on_built_miniloader(entity, util.orientation_from_inserters(entity))
  end
end

local function on_script_revive(ev)
  local entity = ev.entity
  if entity and util.is_miniloader_inserter(entity) then
    on_built_miniloader(entity, util.orientation_from_inserters(entity))
  end
end

local function on_player_built(ev)
  local entity = ev.created_entity

  if util.is_miniloader_inserter(entity) then
    local orientation = util.orientation_from_inserters(entity)
    local loader = on_built_miniloader(entity, orientation)
    if use_snapping and not orientation then
      -- adjusts direction & loader_type
      snapping.snap_loader(loader)
    end
  elseif use_snapping
  and entity.type == "entity-ghost"
  and util.is_miniloader_inserter_name(entity.ghost_name) then
    -- remove duplicate ghosts
    local colocated_ghosts = entity.surface.find_entities_filtered{
      position = entity.position,
      ghost_name = entity.ghost_name,
    }
    for i=1,#colocated_ghosts-1 do
      colocated_ghosts[i].destroy()
    end
    if util.orientation_from_inserters(entity) == nil then
      snapping.snap_loader(entity)
    end
  elseif use_snapping then
    snapping.check_for_loaders(ev)
  end
end

local function on_rotated(ev)
  local entity = ev.entity
  if util.is_miniloader_inserter(entity) then
    local miniloader = util.find_miniloaders{
      surface = entity.surface,
      position = entity.position,
      force = entity.force,
    }[1]
    miniloader.rotate{ by_player = game.players[ev.player_index] }
    util.update_inserters(miniloader)
  elseif util.is_miniloader(entity) then
    util.update_inserters(entity)
  elseif use_snapping then
    snapping.check_for_loaders(ev)
  end
end

local function on_miniloader_mined(ev)
  local entity = ev.entity
  local buffer = ev.buffer and ev.buffer.valid and ev.buffer
  local inserters = util.get_loader_inserters(entity)
  if buffer and inserters[1] then
    local _, item_to_place = next(inserters[1].prototype.items_to_place_this)
    buffer.insert{desired_count=1, name=item_to_place.name}
  end
  for i=1,#inserters do
    -- return items to player / robot if mined
    if buffer and inserters[i] ~= entity and inserters[i].held_stack.valid_for_read then
      buffer.insert(inserters[i].held_stack)
    end
    inserters[i].destroy()
  end
  local chest = entity.surface.find_entity("miniloader-target-chest", entity.position)
  if chest then
    chest.destroy()
  end
end

local function on_miniloader_inserter_mined(ev)
  local entity = ev.entity
  local buffer = ev.buffer and ev.buffer.valid and ev.buffer
  local loader = entity.surface.find_entities_filtered{
    position = entity.position,
    type = "loader-1x1",
  }[1]
  if loader then
    if buffer then
      for i=1,2 do
        local tl = loader.get_transport_line(i)
        for j=1,math.min(#tl, 256) do
          buffer.insert(tl[j])
        end
        tl.clear()
      end
    end
    loader.destroy()
  end

  local inserters = util.get_loader_inserters(entity)
  for i=1,#inserters do
    if inserters[i] ~= entity then
      -- return items in inserter hand to player / robot if mined
      if buffer and inserters[i].held_stack.valid_for_read then
        buffer.insert(inserters[i].held_stack)
      end
      inserters[i].destroy()
    end
  end

  local chest = entity.surface.find_entity("miniloader-target-chest", entity.position)
  if chest then
    chest.destroy()
  end
end

local function on_mined(ev)
  local entity = ev.entity
  if util.is_miniloader(entity) then
    on_miniloader_mined(ev)
  elseif util.is_miniloader_inserter(entity) then
    on_miniloader_inserter_mined(ev)
  end
end

local function on_placed_blueprint(ev, player, bp_entities)
  if not next(bp_entities) then return end

  global.player_placed_blueprint[ev.player_index] = ev.tick

  local surface = player.surface
  local bp_area = blueprint.bounding_box(bp_entities)
  local surface_area = util.move_box(
    util.rotate_box(bp_area, ev.direction),
    ev.position
  )

  local blueprint_contained_miniloader = false
  for _, bp_entity in pairs(bp_entities) do
    if util.is_miniloader_inserter_name(bp_entity.name) then
      blueprint_contained_miniloader = true
      break
    end
  end

  if blueprint_contained_miniloader then
    -- remember where we have placed a blueprint so we can check for changes next tick
    if not global.placed_blueprint_areas then global.placed_blueprint_areas = {} end
    global.placed_blueprint_areas[#global.placed_blueprint_areas+1] = {
      surface = surface,
      area = surface_area,
    }
  end
end

-- A blueprint placed over existing miniloaders in the previous tick
-- may have changed their orientation.
local function check_placed_blueprints_for_miniloaders()
  if not global.placed_blueprint_areas or not next(global.placed_blueprint_areas) then return end
  for _, data in ipairs(global.placed_blueprint_areas) do
    local surface = data.surface
    local area = data.area
    if surface.valid then
      local inserter_entities = surface.find_entities_filtered{
        area = area,
        type = "inserter",
      }
      for _, e in pairs(inserter_entities) do
        if util.is_miniloader_inserter(e) then
          miniloader.fixup(e, util.orientation_from_inserters(e))
        end
      end
    end
  end

  global.placed_blueprint_areas = {}
end

local function on_pre_build(ev)
  local player_index = ev.player_index
  local player = game.players[player_index]
  local bp_entities = player.get_blueprint_entities()
  if bp_entities then
    return on_placed_blueprint(ev, player, bp_entities)
  end
end

local function on_player_mined_entity(ev)
  on_mined(ev)
end

local function on_entity_settings_pasted(ev)
  local src = ev.source
  local dst = ev.destination
  if util.is_miniloader_inserter(src) and util.is_miniloader_inserter(dst)
  or util.is_miniloader(src) and util.is_miniloader(dst) then
    local src_loader = src.surface.find_entities_filtered{type="loader-1x1",position=src.position}[1]
    local dst_loader = dst.surface.find_entities_filtered{type="loader-1x1",position=dst.position}[1]
    if src_loader and dst_loader then
      dst_loader.loader_type = src_loader.loader_type
      util.update_inserters(dst_loader)
    end
    if util.is_output_filter_miniloader_inserter(src) then
      local right_src = util.get_loader_inserters(src)[2]
      local right_dst = util.get_loader_inserters(dst)[2]
      if right_src and right_dst then
        circuit.copy_inserter_settings(right_src, right_dst)
      end
    end
    circuit.sync_behavior(dst)
    circuit.sync_filters(dst)
  end
end

local function on_gui_closed(event)
  local player = game.get_player(event.player_index)
  if event.gui_type == defines.gui_type.item
  and event.item
  and event.item.is_blueprint
  and event.item.is_blueprint_setup()
  and player.cursor_stack
  and player.cursor_stack.valid_for_read
  and player.cursor_stack.is_blueprint
  and not player.cursor_stack.is_blueprint_setup()
  then
    global.previous_opened_blueprint_for[event.player_index] = {
      blueprint = event.item,
      tick = event.tick,
    }
  else
    global.previous_opened_blueprint_for[event.player_index] = nil
  end
end

local function on_setup_blueprint(ev)
  local bp = blueprint.get_blueprint_to_setup(ev.player_index)
  if not (bp and bp.valid_for_read) then return end
  blueprint.filter_miniloaders(bp)
end

local function on_marked_for_deconstruction(ev)
  local entity = ev.entity
  if not (util.is_miniloader(entity) or util.is_miniloader_inserter(entity)) then return end
  for _, ent in ipairs(entity.surface.find_entities_filtered{position=entity.position}) do
    -- order_deconstruction() causes event handlers to be fired which may invalidate entities
    if ent.valid and (util.is_miniloader(ent) or util.is_miniloader_inserter(ent)) then
      if not ent.to_be_deconstructed(ent.force) then
        ent.order_deconstruction(ent.force)
      end
    end
  end
end

local function on_canceled_deconstruction(ev)
  local entity = ev.entity
  for _, ent in ipairs(entity.surface.find_entities_filtered{position=entity.position}) do
    if util.is_miniloader(ent) or util.is_miniloader_inserter(ent) then
      if ent.to_be_deconstructed(ent.force) then
        ent.cancel_deconstruction(ent.force)
      end
    end
  end
end

local function on_marked_for_upgrade(ev)
  local entity = ev.entity
  if not util.is_miniloader_inserter(entity) then return end
  local main_inserter = entity.surface.find_entity(entity.name, entity.position)
  if entity == main_inserter then return end
  local force = ev.player_index and game.get_player(ev.player_index).force or entity.force
  entity.cancel_upgrade(force)
end

-- lifecycle events

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

-- entity events

event.register(defines.events.on_built_entity, on_player_built)
event.register(defines.events.on_robot_built_entity, on_robot_built)
event.register(defines.events.on_player_rotated_entity, on_rotated)

event.register(defines.events.on_player_mined_entity, on_player_mined_entity)
event.register(defines.events.on_robot_mined_entity, on_mined)
event.register(defines.events.on_entity_died, on_mined)
event.register(defines.events.script_raised_built, on_script_built)
event.register(defines.events.script_raised_revive, on_script_revive)
event.register(defines.events.script_raised_destroy, on_mined)

event.register(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
event.register(defines.events.on_pre_build, on_pre_build)

event.register(defines.events.on_player_setup_blueprint, on_setup_blueprint)
event.register(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.register(defines.events.on_canceled_deconstruction, on_canceled_deconstruction)

event.register(defines.events.on_marked_for_upgrade, on_marked_for_upgrade)

event.register(defines.events.on_gui_closed, on_gui_closed)

event.register(defines.events.on_runtime_mod_setting_changed, function(ev)
  if ev.setting == "miniloader-snapping" then
    use_snapping = settings.global["miniloader-snapping"].value
  elseif ev.setting == "miniloader-lock-stack-sizes" then
    local size = settings.global["miniloader-lock-stack-sizes"].value and 1 or 0
    miniloader.forall(function(surface, miniloader)
      for _, inserter in pairs(util.get_loader_inserters(miniloader)) do
        inserter.inserter_stack_size_override = size
      end
    end)
  end
end)

event.register(defines.events.on_tick, check_placed_blueprints_for_miniloaders)
