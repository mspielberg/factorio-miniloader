local circuit = require("circuit")
local configchange = require("configchange")
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
	if util.is_miniloader(entity) then
		local surface = entity.surface
		entity.destructible = false

		local proxy = surface.create_entity{
			name = entity.name .. "-circuit-proxy",
			position = entity.position,
			force = entity.force,
			direction = entity.direction,
		}
		circuit.register_proxy(proxy)

		for i = 1, util.num_inserters(entity) do
			local inserter = surface.create_entity{
				name = entity.name .. "-inserter",
				position = entity.position,
				force = entity.force,
			}
			inserter.destructible = false
			inserter.inserter_stack_size_override = 1

			for wire_type=2,3 do
				proxy.connect_neighbour{
					wire = wire_type,
					target_entity = inserter,
				}
			end
		end
		util.update_inserters(entity)

		if use_snapping then
			-- adjusts direction & belt_to_ground_type
			snapping.snap_loader(entity, event)
		end
	elseif use_snapping then
		snapping.check_for_loaders(event)
	end
end

local function on_rotated(event)
	local entity = event.entity
	if use_snapping then
		snapping.check_for_loaders(event)
	end
	if util.is_circuit_proxy(entity) then
		local miniloader = util.find_miniloaders{
			surface = entity.surface,
			position = entity.position,
			force = entity.force
		}[1]
		miniloader.rotate{ by_player = game.players[event.player_index] }
		util.update_inserters(miniloader)
		entity.direction = miniloader.direction
	end
end

local function on_mined(event)
	local entity = event.entity
	if not util.is_circuit_proxy(entity) then
		return
	end

	local inserters = util.get_loader_inserters(entity)
	for i=1, #inserters do
		-- return items to player / robot if mined
		if event.buffer then
			event.buffer.insert(inserters[i].held_stack)
		end
		inserters[i].destroy()
	end

	local loader = entity.surface.find_entities_filtered{ type = "underground-belt" }[1]
	if event.buffer then
		for i=1,2 do
			local tl = loader.get_transport_line(i)
			for j=1,#tl do
				event.buffer.insert(tl[j])
			end
		end
	end
	loader.destroy()
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

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "miniloader-snapping" then
		use_snapping = settings.global["miniloader-snapping"].value
	end
end)

script.on_event(defines.events.on_tick, circuit.on_tick)