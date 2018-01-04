require "util"

local ingredients = {
	-- 52 I
	["bulk-miniloader"] = {
		{"underground-belt", 2},
		{"iron-plate", 16},
		{"engine-unit", 2},
	},
	-- 105 I, 27 C
	["miniloader"] = {
		{"underground-belt", 2},
		{"steel-plate", 8},
		{"fast-inserter", 6},
	},
	-- 174 I
	["fast-bulk-miniloader"] = {
		{"fast-underground-belt", 2},
		{"steel-plate", 8},
		{"engine-unit", 4},
	},
	-- 358 I, 128 C, 89 O
	["fast-miniloader"] = {
		{"fast-underground-belt", 2},
		{"steel-plate", 8},
		{"stack-inserter", 4},
	},
	-- 342 I, 12 C, 333 O
	["express-bulk-miniloader"] = {
		{"express-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	-- 628 I, 384 C, 174 O
	["express-miniloader"] = {
		{"express-underground-belt", 2},
		{"steel-plate", 8},
		{"stack-inserter", 6},
	},

	["green-bulk-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	["green-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"express-stack-inserter", 4},
	},
	["purple-bulk-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	["purple-miniloader"] = {
		{"purple-underground-belt", 2},
		{"steel-plate", 8},
		{"express-stack-inserter", 6},
	},
}

local empty_sheet = {
	filename = "__core__/graphics/empty.png",
	priority = "very-low",
	width = 0,
	height = 0,
	frame_count = 1,
}

local function create_loader(prefix)
	local loader_name = prefix .. "miniloader"
	local name = loader_name .. "-loader"

	local entity = util.table.deepcopy(data.raw["underground-belt"][prefix .. "underground-belt"])
	entity.type = "loader"
	entity.name = name
	entity.flags = {}
	entity.localised_name = {"entity-name." .. loader_name}
	entity.minable = nil
	entity.collision_box = {{-0.2, -0.1}, {0.2, 0.1}}
	entity.selection_box = {{0, 0}, {0, 0}}
	entity.belt_horizontal = empty_sheet
	entity.belt_vertical = empty_sheet
	entity.filter_count = 0
	entity.structure = {
		direction_in = {
			sheet = empty_sheet,
			_ = {
				filename = "__miniloader__/graphics/entity/" .. loader_name .. "-cutout.png",
				priority = "extra-high",
				width = 128,
				height = 128,
			}
		},
		direction_out = {
			sheet = empty_sheet,
			_ = {
				filename = "__miniloader__/graphics/entity/" .. loader_name .. "-cutout.png",
				priority = "extra-high",
				width = 128,
				height = 128,
				y = 128,
			}
		},
	}
	entity.belt_distance = 0
	entity.container_distance = 0
	entity.belt_length = 0.1
	data:extend{entity}
end

local function create_item(prefix)
	local name = prefix .. "miniloader"

	local item = util.table.deepcopy(data.raw.item[prefix .. "underground-belt"])
	item.name = name
	item.icon = "__miniloader__/graphics/item/" .. name ..".png"
	item.order, _ = string.gsub(item.order, "^b%[underground%-belt%]", "e[miniloader]", 1)
	item.place_result = name .. "-inserter"

	data.raw["item"][name] = item
end

local function create_recipe(prefix)
	local name = prefix .. "miniloader"

	local recipe = {
		type = "recipe",
		name = name,
		enabled = false,
		energy_required = 1,
		ingredients = ingredients[name],
		result = name,
	}

	data:extend{recipe}
end

local function create_technology(prefix, tech_prereqs)
	local name = prefix .. "miniloader"

	local main_prereq = data.raw["technology"][tech_prereqs[1]]
	local technology = {
		type = "technology",
		name = name,
		icon = "__miniloader__/graphics/technology/" .. name .. ".png",
		icon_size = 128,
		effects =
		{
			{
				type = "unlock-recipe",
				recipe = name,
			}
		},
		prerequisites = tech_prereqs,
		unit = main_prereq.unit,
		order = main_prereq.order
	}

	data:extend{technology}
end

local connector_definitions = circuit_connector_definitions.create(
	universal_connector_template,
	{
		{ variation = 26, main_offset = util.by_pixel(3, 4), shadow_offset = util.by_pixel(10, -0.5), show_shadow = false },
		{ variation = 22, main_offset = util.by_pixel(-10, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
		{ variation = 21, main_offset = util.by_pixel(-12, -15), shadow_offset = util.by_pixel(-2.5, 6), show_shadow = false },
		{ variation = 18, main_offset = util.by_pixel(10, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
	}
)

local function create_inserter(prefix)
	local base_entity = data.raw["underground-belt"][prefix .. "underground-belt"]
	local loader_name = prefix .. "miniloader"
	local name = loader_name .. "-inserter"

	local loader_inserter = {
		type = "inserter",
		name = name,
		-- this name and icon appear in the power usage UI
		localised_name = {"entity-name." .. loader_name},
		icon = "__miniloader__/graphics/item/" .. loader_name .. ".png",
		icon_size = 32,
		minable = { mining_time = 1, result = loader_name },
		allow_custom_vectors = true,
		energy_per_movement = 2000,
		energy_per_rotation = 2000,
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
		},
		extension_speed = 1.0,
		rotation_speed = 1.0,
		pickup_position = {0, -0.2},
		insert_position = {0, 0.8},
		draw_held_item = false,
		platform_picture = {
			sheet = {
				filename = "__miniloader__/graphics/entity/" .. loader_name .. ".png",
				priority = "extra-high",
				width = 128,
				height = 128,
			}
		},
		hand_base_picture = empty_sheet,
		hand_open_picture = empty_sheet,
		hand_closed_picture = empty_sheet,
		circuit_wire_connection_points = connector_definitions.points,
		circuit_connector_sprites = connector_definitions.sprites,
		circuit_wire_max_distance = default_circuit_wire_max_distance,
	}

	for _,k in ipairs{"flags", "max_health", "collision_box", "selection_box", "resistances", "vehicle_impact_sound"} do
		loader_inserter[k] = base_entity[k]
	end
	data:extend{loader_inserter}
end

local function create_miniloader(prefix, tech_prereqs)
	create_loader(prefix)
	create_inserter(prefix)
	create_item(prefix)
	create_recipe(prefix)
	create_technology(prefix, tech_prereqs)
end

create_miniloader("", {"logistics-2", "engine"})
create_miniloader("fast-", {"miniloader", "stack-inserter"})
create_miniloader("express-", {"logistics-3", "fast-miniloader"})

-- Bob's support
if data.raw.technology["bob-logistics-4"] then
	create_miniloader("green-", {"bob-logistics-4", "express-miniloader"})
	if data.raw.technology["bob-logistics-5"] then
		create_miniloader("purple-", {"bob-logistics-5", "green-miniloader"})
	end
end
