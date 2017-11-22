require "util"

local empty_sheet = {
	filename = "__core__/graphics/empty.png",
	priority = "very-low",
	width = 0,
	height = 0,
}
local loader_inserter = {
	type = "inserter",
	name = "loader-inserter",
	flags = {"placeable-off-grid"},
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

data.raw["underground-belt"]["railloader"] = util.table.deepcopy(data.raw["underground-belt"]["underground-belt"])
data.raw["underground-belt"]["railloader"].name = "railloader"
data.raw["underground-belt"]["railloader"].minable.result = "railloader"
data.raw["underground-belt"]["railloader"].max_distance=0
data.raw.item["railloader"] = util.table.deepcopy(data.raw.item["underground-belt"])
data.raw.item["railloader"].name = "railloader"
data.raw.item["railloader"].place_result = "railloader"
data.raw.recipe["railloader"] = util.table.deepcopy(data.raw.recipe["underground-belt"])
data.raw.recipe["railloader"].name = "railloader"
data.raw.recipe["railloader"].result = "railloader"
data.raw.recipe["railloader"].enabled = true
data.raw.recipe["railloader"].result_count = nil

--[[{
	type = "underground-belt",
	name = "railloader",
	icon = "__base__/graphics/icons/underground-belt.png",
	flags = {"placeable-neutral", "player-creation"},
	minable = {hardness = 0.2, mining_time = 0.5, result = "underground-belt"},
	max_health = 150,
	corpse = "small-remnants",
	max_distance = 5,
	underground_sprite =
	{
		filename = "__core__/graphics/arrows/underground-lines.png",
		priority = "high",
		width = 64,
		height = 64,
		x = 64,
		scale = 0.5
	},
	resistances =
	{
		{
			type = "fire",
			percent = 60
		},
		{
			type = "impact",
			percent = 30
		}
	},
	collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	animation_speed_coefficient = 32,
	belt_horizontal = basic_belt_horizontal,
	belt_vertical = basic_belt_vertical,
	ending_top = basic_belt_ending_top,
	ending_bottom = basic_belt_ending_bottom,
	ending_side = basic_belt_ending_side,
	starting_top = basic_belt_starting_top,
	starting_bottom = basic_belt_starting_bottom,
	starting_side = basic_belt_starting_side,
	fast_replaceable_group = "underground-belt",
	speed = 0.03125,
	structure =
	{
		direction_in =
		{
			sheet =
			{
				filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
				priority = "extra-high",
				shift = {0.25, 0},
				width = 57,
				height = 43,
				y = 43,
				hr_version =
				{
					filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
					priority = "extra-high",
					shift = {0.15625, 0.0703125},
					width = 106,
					height = 85,
					y = 85,
					scale = 0.5
				}
			}
		},
		direction_out =
		{
			sheet =
			{
				filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
				priority = "extra-high",
				shift = {0.25, 0},
				width = 57,
				height = 43,
				hr_version =
				{
					filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
					priority = "extra-high",
					shift = {0.15625, 0.0703125},
					width = 106,
					height = 85,
					scale = 0.5
				}

			}

		}
	},
	ending_patch = ending_patch_prototype
}
]]