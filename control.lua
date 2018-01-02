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

local function on_built(event)
	local entity = event.created_entity
	if util.is_miniloader_inserter(entity) then
		local surface = entity.surface

		local underground_name = string.gsub(entity.name, "inserter", "underground-belt")
		local underground = surface.create_entity{
			name = underground_name,
			position = entity.position,
			direction = util.opposite_direction(entity.direction),
			force = entity.force,
			type = "input",
		}
		entity.destructible = false

		for i = 2, util.num_inserters(underground) do
			local inserter = surface.create_entity{
				name = entity.name,
				position = entity.position,
				direction = entity.direction,
				force = entity.force,
			}
			inserter.inserter_stack_size_override = 1
		end
		util.update_inserters(underground)

		if use_snapping then
			-- adjusts direction & belt_to_ground_type
			snapping.snap_loader(underground, event)
		end
	elseif use_snapping then
		snapping.check_for_loaders(event)
	end
end

local function on_rotated(event)
	local entity = event.entity
	game.print(serpent.line({ev=event, ent=entity.name}))
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
		type = "underground-belt",
	}[1]
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

local function on_player_pipette(event)
	local item_proto = event.item
	if not util.is_miniloader_inserter(item_proto) then
		return
	end
	local inserter_name = item_proto.name
	log(inserter_name)
	local loader_name = string.gsub(item_proto.name, "%-inserter$", "")
	log(loader_name)
	local player = game.players[event.player_index]
	local selected = player.selected
	local count = math.min(player.get_item_count(loader_name), item_proto.stack_size)
	log(count)
	if count > 0 then
		player.cursor_stack.set_stack{ name = loader_name, count = count }
		player.remove_item{ name = loader_name, count = count }
	end
end

-- lifecycle events

script.on_configuration_changed(on_configuration_changed)

-- entity events

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_rotated_entity, on_rotated)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)
-- script.on_event(defines.events.on_player_pipette, on_player_pipette)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "miniloader-snapping" then
		use_snapping = settings.global["miniloader-snapping"].value
	end
end)