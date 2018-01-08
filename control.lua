local circuit = require("circuit")
local configchange = require("configchange")
local _ = require("gui")
local snapping = require("snapping")
local util = require("lualib.util")

local use_snapping = settings.global["miniloader-snapping"].value

--[[
	belt_to_ground_type = "input"
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

	belt_to_ground_type = "output"
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

	D: drop positions
	P: pickup position
]]

-- Event Handlers

local function on_configuration_changed(configuration_changed_data)
	local mod_change = configuration_changed_data.mod_changes["miniloader"]
	if mod_change and mod_change.old_version and mod_change.old_version ~= mod_change.new_version then
		configchange.on_mod_version_changed(mod_change.old_version)
	end
end

local function on_built_miniloader(entity, orientation)
	if not orientation then
		orientation = {direction = util.opposite_direction(entity.direction), type = "input"}
	end

	local surface = entity.surface

	local loader_name = string.gsub(entity.name, "inserter", "loader")
	local loader = surface.create_entity{
		name = loader_name,
		position = entity.position,
		direction = orientation.direction,
		force = entity.force,
		type = orientation.type,
	}
	entity.destructible = false

	for _ = 2, util.num_inserters(loader) do
		local inserter = surface.create_entity{
			name = entity.name,
			position = entity.position,
			direction = entity.direction,
			force = entity.force,
		}
		inserter.inserter_stack_size_override = 1
	end
	util.update_inserters(loader)

	return loader
end

local function on_player_built(event)
	local entity = event.created_entity
	if util.is_miniloader_inserter(entity) then
		local loader = on_built_miniloader(entity)
		if use_snapping then
			-- adjusts direction & belt_to_ground_type
			snapping.snap_loader(loader, event)
		end
	else
		snapping.check_for_loaders(event)
	end
end

local function on_robot_built(event)
	local entity = event.created_entity
	if util.is_miniloader_inserter(entity) then
		on_built_miniloader(entity, util.orientation_from_inserters(entity))
		circuit.sync_filters(entity)
		circuit.sync_partner_connections(entity)
	else
		circuit.update_connected_miniloader_inserters(entity)
	end
end

local function on_rotated(event)
	local entity = event.entity
	if util.is_miniloader_inserter(entity) then
		local miniloader = util.find_miniloaders{
			surface = entity.surface,
			position = entity.position,
			force = entity.force,
		}[1]
		miniloader.rotate{ by_player = game.players[event.player_index] }
		util.update_inserters(miniloader)
	elseif use_snapping then
		snapping.check_for_loaders(event)
	end
end

local function on_miniloader_mined(event)
	local entity = event.entity
	local inserters = util.get_loader_inserters(entity)
	for i=1,#inserters do
		-- return items to player / robot if mined
		if event.buffer and inserters[i] ~= entity then
			event.buffer.insert(inserters[i].held_stack)
		end
		inserters[i].destroy()
	end
end

local function on_miniloader_inserter_mined(event)
	local entity = event.entity
	local loader = entity.surface.find_entities_filtered{
		position = entity.position,
		type = "loader",
	}[1]
	if not loader then
		if event.buffer then
			event.buffer.clear()
		end
		return
	end
	if event.buffer then
		for i=1,2 do
			local tl = loader.get_transport_line(i)
			for j=1,#tl do
				event.buffer.insert(tl[j])
			end
			tl.clear()
		end
	end
	loader.destroy()

	local inserters = util.get_loader_inserters(entity)
	for i=2,#inserters do
		-- return items to player / robot if mined
		if event.buffer and inserters[i] ~= entity then
			event.buffer.insert(inserters[i].held_stack)
		end
		inserters[i].destroy()
	end
end

local function on_mined(event)
	local entity = event.entity
	if util.is_miniloader(entity) then
		on_miniloader_mined(event)
	elseif util.is_miniloader_inserter(entity) then
		on_miniloader_inserter_mined(event)
	end
end

local function on_entity_settings_pasted(event)
	local src = event.source
	local dst = event.destination
	if util.is_miniloader_inserter(src) and util.is_miniloader_inserter(dst) then
		circuit.sync_behavior(dst)
		circuit.sync_filters(dst)
		local src_loader = src.surface.find_entities_filtered{type="loader",position=src.position}[1]
		local dst_loader = dst.surface.find_entities_filtered{type="loader",position=dst.position}[1]
		if src_loader and dst_loader then
			dst_loader.loader_type = src_loader.loader_type
			util.update_inserters(dst_loader)
		end
	end
end

-- lifecycle events

script.on_configuration_changed(on_configuration_changed)

-- entity events

script.on_event(defines.events.on_built_entity, on_player_built)
script.on_event(defines.events.on_robot_built_entity, on_robot_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "miniloader-snapping" then
		use_snapping = settings.global["miniloader-snapping"].value
	end
end)