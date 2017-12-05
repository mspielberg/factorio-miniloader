local util = require("util")

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

-- Constants

-- Utility Functions

-- Event Handlers

local snapping = require("snapping")

local function on_init()
	local force = game.create_force("miniloader")
	-- allow miniloader force to access chests belonging to players
	game.forces["player"].set_friend(force, true)
	-- allow players to see power icons on miniloader inserters
	force.set_friend(game.forces["player"], true)
end

local function on_built(event)
	local entity = event.created_entity
	if util.is_miniloader(entity) then
		local surface = entity.surface
		for i = 1, util.num_inserters(entity) do
			local inserter = surface.create_entity{
				name = entity.name .. "-inserter",
				position = entity.position,
				force = "miniloader",
			}
			inserter.destructible = false
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
	if util.is_miniloader(entity) then
		util.update_inserters(entity)
	end
end

local function on_mined(event)
	local entity = event.entity
	if not util.is_miniloader(entity) then
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
end

script.on_init(on_init)
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