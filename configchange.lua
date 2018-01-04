local circuit = require "circuit"
local util = require "lualib.util"

local configchange = {}

local version = require("version")

local all_migrations = {}

local function add_migration(migration)
	all_migrations[#all_migrations+1] = migration
end

add_migration{
	name = "v1_1_4_inserter_cleanup",
	low = {1,1,0},
	high = {1,1,4},
	task = function()
		for _, surface in pairs(game.surfaces) do
			for _, inserter in ipairs(surface.find_entities_filtered{name="miniloader-inserter"}) do
				local loader = surface.find_entity("miniloader-loader", inserter.position)
				if not loader then
					inserter.destroy()
				end
			end
		end
	end,
}

add_migration{
	name = "v1_1_5_miniloader_force_removal",
	low = {1,0,0},
	high = {1,1,5},
	task = function()
		game.merge_forces(game.forces["miniloader"], game.forces["player"])
	end
}

add_migration{
	name = "v1_4_0_reattach_loaders",
	low = {1,0,0},
	high = {1,4,0},
	task = function()
		for _, surface in pairs(game.surfaces) do
			for _, entity in ipairs(surface.find_entities_filtered{type="loader"}) do
				if util.is_miniloader(entity) then
					local orientation = util.orientation_from_inserters(entity)
					local name = entity.name
					local position = entity.position
					local force = entity.force

					-- clear transport lines to prevent spill during replacement
					local from_tl = {}
					for i=1,2 do
						local tl = entity.get_transport_line(i)
						from_tl[i] = tl.get_contents()
						tl.clear()
					end

					entity.destroy()

					local new = surface.create_entity{
						name = name,
						position = position,
						direction = orientation.direction,
						force = force,
						type = orientation.type,
					}
					util.update_inserters(new)

					for i=1,2 do
						local tl = new.get_transport_line(i)
						for name, count in pairs(from_tl[i]) do
							tl.insert_at_back({name=name, count=count})
						end
					end
				end
			end
		end
	end
}

add_migration{
	name = "v1_4_0_expose_inserters",
	low = {1,0,0},
	high = {1,4,0},
	task = function()
		for _, surface in pairs(game.surfaces) do
			for _, entity in ipairs(surface.find_entities_filtered{type="loader"}) do
				if util.is_miniloader(entity) then
					local inserters = util.get_loader_inserters(entity)
					for i=1,#inserters do
						inserters[i].destructible = true
						inserters[i].health = entity.health
						inserters[i].inserter_stack_size_override = 1
					end
					entity.destructible = false
					util.update_inserters(entity)
				end
			end
		end
	end,
}

function configchange.on_mod_version_changed(old)
	old = version.parse(old)
	for _, migration in ipairs(all_migrations) do
		if version.between(old, migration.low, migration.high) then
			log("running world migration "..migration.name)
			migration.task()
		end
	end
end

return configchange