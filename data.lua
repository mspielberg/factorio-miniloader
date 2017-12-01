require "util"

local empty_sheet = {
	filename = "__core__/graphics/empty.png",
	priority = "very-low",
	width = 0,
	height = 0,
}

local function num_inserters(base_entity)
end

local function create_inserter(base_entity)
	local name = base_entity.name .. "-miniloader-inserter"
	local loader_inserter = {
		type = "inserter",
		name = name,
		-- this icon appears in the power usage UI
		icon = base_entity.icon,
		flags = {"placeable-off-grid"},
		max_health = base_entity.max_health,
		allow_custom_vectors = true,
		energy_per_movement = 2000,
		energy_per_rotation = 2000,
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
		},
		extension_speed = 20.0,
		rotation_speed = 20.0,
		collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
		selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
		pickup_position = {0, 0},
		insert_position = {0, 1.0},
		platform_picture = { sheet = empty_sheet },
		hand_base_picture = empty_sheet,
		hand_open_picture = empty_sheet,
		hand_closed_picture = empty_sheet,
	}
	data.raw.inserter[name] = loader_inserter
end

local function create_miniloader(base_entity, tech_prereqs)
	local name = base_entity.name .. "-miniloader"
	local entity = util.table.deepcopy(base_entity)
	entity.name = name
	entity.minable.result = name
	entity.max_distance = 0
	data.raw["underground-belt"][name] = entity

	local item = util.table.deepcopy(data.raw.item[base_entity.name])
	item.name = name
	item.place_result = name
	data.raw["item"][name] = item

	local recipe = {
		type = "recipe",
		name = name,
		enabled = false,
		energy_required = 1,
		ingredients =
		{
			{base_entity.name, 2},
			{"steel-plate", 8},
			{"stack-inserter", 2},
		},
		result = name
	}
	data.raw["recipe"][name] = recipe

	local main_prereq = data.raw["technology"][tech_prereqs[1]]
	local technology = {
		type = "technology",
		name = name,
		-- TODO technology icons
		icon = "__base__/graphics/technology/logistics.png",
		effects =
		{
			{
				type = "unlock-recipe",
				recipe = name
			}
		},
		prerequisites = tech_prereqs,
		unit = main_prereq.unit,
		order = main_prereq.order
	}
	data.raw["technology"][name] = technology

	create_inserter(base_entity)
end

create_miniloader(data.raw["underground-belt"]["underground-belt"], {"stack-inserter"})
create_miniloader(data.raw["underground-belt"]["fast-underground-belt"], {"underground-belt-miniloader"})
create_miniloader(data.raw["underground-belt"]["express-underground-belt"], {"logistics-3", "fast-underground-belt-miniloader"})

-- Bob's support
if data.raw.technology["bob-logistics-5"] then
	create_miniloader(data.raw["underground-belt"]["green-underground-belt"], {"bob-logistics-4", "express-underground-belt-miniloader"})
	create_miniloader(data.raw["underground-belt"]["purple-underground-belt"], {"bob-logistics-5", "green-underground-belt-miniloader"})
end