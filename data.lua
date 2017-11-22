data.raw.recipe["loader"].enabled = true
--[[local loader_inserter = util.table.deepcopy(data.raw.inserter["stack-inserter"])
loader_inserter.name = "loader-inserter"
loader_inserter.flags = {}
loader_inserter.allow_custom_vectors = true
loader_inserter.minable = nil
loader_inserter.corpse = nil
loader_inserter.resistances = nil
loader_inserter.energy_per_movement = 0.1
loader_inserter.energy_per_rotation = 0.1
loader_inserter.energy_source.drain = "0kW"
loader_inserter.extension_speed = 0.5
]]
local empty_sheet = {
	filename = "__core__/graphics/empty.png",
	priority = "very-low",
	width = 0,
	height = 0,
}
local loader_inserter = {
	type = "inserter",
	name = "loader-inserter",
	stack = true,
	allow_custom_vectors = true,
	energy_per_movement = 1,
	energy_per_rotation = 1,
	extension_speed = 0.2,
	rotation_speed = 0.1,
	collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
	selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
	pickup_position = {0, 1.0},
	insert_position = {0, 2.0},
	platform_picture = { sheet = empty_sheet },
	hand_base_picture = empty_sheet,
	hand_open_picture = empty_sheet,
	hand_closed_picture = empty_sheet,
	energy_source = {
		type = "electric",
		usage_priority = "secondary-input",
	}
}
data.raw.inserter["loader-inserter"] = loader_inserter

local loader_chest = {
	type = "container",
	name = "loader-chest",
	collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	inventory_size = 1,
	picture =
	{
		filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
		priority = "extra-high",
		width = 48,
		height = 34,
		shift = {0.1875, 0}
	},
}
data.raw.container["loader-chest"] = loader_chest