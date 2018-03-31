require "util"

local ingredients = {
  -- base
  -- 105 I, 27 C
  ["miniloader"] = {
    {"underground-belt", 1},
    {"steel-plate", 8},
    {"fast-inserter", 6},
  },
  -- 358 I, 128 C, 89 O
  ["fast-miniloader"] = {
    {"miniloader", 1},
    {"fast-underground-belt", 1},
    {"stack-inserter", 4},
  },
  -- 628 I, 384 C, 174 O
  ["express-miniloader"] = {
    {"fast-miniloader", 1},
    {"express-underground-belt", 1},
    {"stack-inserter", 2},
  },

  -- boblogistics
  ["turbo-miniloader"] = {
    {"express-miniloader", 1},
    {"turbo-underground-belt", 1},
    {"express-stack-inserter", 4},
  },
  ["ultimate-miniloader"] = {
    {"turbo-miniloader", 1},
    {"ultimate-underground-belt", 1},
    {"express-stack-inserter", 2},
  },

  -- UltimateBelts
  ["ub-ultra-fast-miniloader"] = {
    {"express-miniloader", 1},
    {"ultra-fast-underground-belt", 1},
    {"stack-inserter", 6},
  },
  ["ub-extreme-fast-miniloader"] = {
    {"ub-ultra-fast-miniloader", 1},
    {"extreme-fast-underground-belt", 1},
    {"stack-inserter", 6},
  },
  ["ub-ultra-express-miniloader"] = {
    {"ub-extreme-fast-miniloader", 1},
    {"ultra-express-underground-belt", 1},
    {"stack-inserter", 6},
  },
  ["ub-extreme-express-miniloader"] = {
    {"ub-ultra-express-miniloader", 1},
    {"extreme-express-underground-belt", 1},
    {"stack-inserter", 6},
  },
  ["ub-ultimate-miniloader"] = {
    {"ub-extreme-express-miniloader", 1},
    {"ultimate-underground-belt", 1},
    {"stack-inserter", 6},
  },
}

if data.raw["inserter"]["turbo-inserter"] then
  ingredients["miniloader"][3] = {"inserter", 8}
  ingredients["fast-miniloader"][3] = {"long-handed-inserter", 8}
  ingredients["express-miniloader"][3] = {"fast-inserter", 6}
  ingredients["turbo-miniloader"][3] = {"turbo-inserter", 6}
  ingredients["ultimate-miniloader"][3] = {"express-inserter", 6}
end

local previous_miniloader = {
  ["fast-"] = "",
  ["express-"] = "fast-",

  -- boblogistics
  ["turbo-"] = "express-",
  ["ultimate-"] = "turbo-",

  -- UltimateBelts
  ["ub-ultra-fast-"] = "express-",
  ["ub-extreme-fast-"] = "ub-ultra-fast-",
  ["ub-ultra-express-"] = "ub-extreme-fast-",
  ["ub-extreme-express-"] = "ub-ultra-express-",
  ["ub-ultimate-"] = "ub-extreme-express-",
}

local filter_inserters = {
  ["fast-inserter"] = "filter-inserter",
  ["stack-inserter"] = "stack-filter-inserter",
  ["express-stack-inserter"] = "express-stack-filter-inserter",

  -- boblogistics overhaul
  ["inserter"] = "yellow-filter-inserter",
  ["long-handed-inserter"] = "red-filter-inserter",
  ["turbo-inserter"] = "turbo-filter-inserter",
  ["express-inserter"] = "express-filter-inserter",
}

local empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 0,
  height = 0,
  frame_count = 1,
}

-- underground belt solely for the purpose of migrations from pre-1.4.0 versions
local function create_legacy_underground(prefix)
  local name = prefix .. "miniloader-legacy-underground"
  prefix = string.gsub(prefix, "^ub%-", "")

  local entity = {}
  entity.type = "underground-belt"
  entity.name = name
  entity.flags = {}
  entity.collision_box = {{-0.2, -0.1}, {0.2, 0.1}}
  entity.selection_box = {{0, 0}, {0, 0}}
  entity.belt_horizontal = empty_sheet
  entity.belt_vertical = empty_sheet
  entity.ending_top = empty_sheet
  entity.ending_side = empty_sheet
  entity.ending_bottom = empty_sheet
  entity.starting_top = empty_sheet
  entity.starting_side = empty_sheet
  entity.starting_bottom = empty_sheet
  entity.ending_patch = empty_sheet
  entity.speed = data.raw["underground-belt"][prefix .. "underground-belt"].speed
  entity.max_distance = 0
  entity.underground_sprite = empty_sheet
  entity.underground_remove_belts_sprite = empty_sheet
  entity.structure = {
    direction_in = empty_sheet,
    direction_out = empty_sheet,
  }
  data:extend{entity}
end

local function create_loaders(prefix)
  local loader_name = prefix .. "miniloader"
  local filter_loader_name = prefix .. "filter-miniloader"
  local name = loader_name .. "-loader"
  prefix = string.gsub(prefix, "^ub%-", "")

  local entity = util.table.deepcopy(data.raw["underground-belt"][prefix .. "underground-belt"])
  entity.type = "loader"
  entity.name = name
  entity.flags = {"player-creation"}
  entity.localised_name = {"entity-name." .. loader_name}
  entity.minable = { mining_time = 1, count = 0, result = "raw-wood" }
  entity.collision_box = {{-0.2, -0.1}, {0.2, 0.1}}
  entity.selection_box = {{0, 0}, {0, 0}}
  entity.belt_horizontal = empty_sheet
  entity.belt_vertical = empty_sheet
  entity.filter_count = 0
  entity.structure = {
    direction_in = {
      sheet = {
        filename = "__miniloader__/graphics/entity/" .. loader_name .. "-cutout.png",
        priority = "extra-high",
        width = 128,
        height = 128,
      }
    },
    direction_out = {
      sheet = {
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
  entity.belt_length = 0.2

  if entity.speed > 0.16 then
    -- BETA support for Ultimate Belts
    entity.container_distance = 1
  end

  local filter_entity = util.table.deepcopy(entity)
  filter_entity.name = filter_loader_name .. "-loader"
  filter_entity.structure.direction_in.sheet.filename = "__miniloader__/graphics/entity/" .. filter_loader_name .. "-cutout.png"
  filter_entity.structure.direction_out.sheet.filename = "__miniloader__/graphics/entity/" .. filter_loader_name .. "-cutout.png"

  data:extend{
    entity,
    filter_entity,
  }
end

local function create_items(prefix)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"
  prefix = string.gsub(prefix, "^ub%-", "")

  local item = util.table.deepcopy(data.raw.item[prefix .. "underground-belt"])
  item.name = name
  item.localised_name = {"entity-name." .. name}
  item.icon = "__miniloader__/graphics/item/" .. name ..".png"
  item.order, _ = string.gsub(item.order, "^b%[underground%-belt%]", "e[miniloader]", 1)
  item.place_result = name .. "-inserter"

  local filter_item = util.table.deepcopy(item)
  filter_item.name = filter_name
  filter_item.localised_name = {"entity-name." .. filter_name}
  filter_item.icon = "__miniloader__/graphics/item/" .. filter_name ..".png"
  filter_item.order, _ = string.gsub(item.order, "$", "-filter", 1)
  filter_item.place_result = filter_name .. "-inserter"

  data:extend{
    item,
    filter_item,
  }
end

local function create_recipes(prefix)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"

  local recipe = {
    type = "recipe",
    name = name,
    enabled = false,
    energy_required = 1,
    ingredients = ingredients[name],
    result = name,
  }

  local filter_recipe = util.table.deepcopy(recipe)
  filter_recipe.name = filter_name
  if previous_miniloader[prefix] then
    filter_recipe.ingredients[1][1] = previous_miniloader[prefix] .. "filter-miniloader"
  end
  filter_recipe.ingredients[3][1] = filter_inserters[recipe.ingredients[3][1]]
  filter_recipe.result = filter_name

  data:extend{
    recipe,
    filter_recipe,
  }
end

local function create_technology(prefix, tech_prereqs)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"
  prefix = string.gsub(prefix, "^ub%-", "")

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
      },
      {
        type = "unlock-recipe",
        recipe = filter_name,
      }
    },
    prerequisites = tech_prereqs,
    unit = util.table.deepcopy(main_prereq.unit),
    order = main_prereq.order
  }

  if data.raw["underground-belt"][prefix .. "underground-belt"].speed > 0.16 then
    -- BETA support for Ultimate Belts
    technology.effects[2] = nil
  end

  data:extend{technology}
end

local connector_definitions = circuit_connector_definitions.create(
  universal_connector_template,
  {
    { variation = 26, main_offset = util.by_pixel(3, 4), shadow_offset = util.by_pixel(10, -0.5), show_shadow = false },
    { variation = 18, main_offset = util.by_pixel(-10, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
    { variation = 21, main_offset = util.by_pixel(-12, -15), shadow_offset = util.by_pixel(-2.5, 6), show_shadow = false },
    { variation = 22, main_offset = util.by_pixel(10, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
  }
)

local function create_inserters(prefix)
  local loader_name = prefix .. "miniloader"
  local name = loader_name .. "-inserter"
  local filter_loader_name = prefix .. "filter-miniloader"
  local filter_name = filter_loader_name .. "-inserter"
  prefix = string.gsub(prefix, "^ub%-", "")
  local base_entity = data.raw["underground-belt"][prefix .. "underground-belt"]
  local speed = base_entity.speed * 0.4 / 0.03125

  local loader_inserter = {
    type = "inserter",
    name = name,
    -- this name and icon appear in the power usage UI
    localised_name = {"entity-name." .. loader_name},
    icon = "__miniloader__/graphics/item/" .. loader_name .. ".png",
    icon_size = 32,
    minable = { mining_time = 1, result = loader_name },
    collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    allow_custom_vectors = true,
    energy_per_movement = 2000,
    energy_per_rotation = 2000,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    extension_speed = speed,
    rotation_speed = speed,
    fast_replaceable_group = "miniloader-inserter",
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

  for _,k in ipairs{"flags", "max_health", "resistances", "vehicle_impact_sound"} do
    loader_inserter[k] = base_entity[k]
  end

  local filter_loader_inserter = util.table.deepcopy(loader_inserter)
  filter_loader_inserter.name = filter_name
  filter_loader_inserter.localised_name = {"entity-name." .. filter_loader_name}
  filter_loader_inserter.minable.result = filter_loader_name
  filter_loader_inserter.filter_count = 5

  data:extend{
    loader_inserter,
    filter_loader_inserter,
  }
end

local function create_miniloader(prefix, tech_prereqs)
  create_legacy_underground(prefix)
  create_loaders(prefix)
  create_inserters(prefix)
  create_items(prefix)
  create_recipes(prefix)
  create_technology(prefix, tech_prereqs)
end

create_miniloader("", {"logistics-2"})
create_miniloader("fast-", {"miniloader"})
create_miniloader("express-", {"logistics-3", "fast-miniloader"})

-- Bob's support
if data.raw.technology["bob-logistics-4"] then
  create_miniloader("turbo-", {"bob-logistics-4", "express-miniloader"})
  if data.raw.technology["bob-logistics-5"] then
    create_miniloader("ultimate-", {"bob-logistics-5", "turbo-miniloader"})
  end
end

-- UltimateBelts support
if data.raw.technology["ultimate-logistics"] then
  create_miniloader("ub-ultra-fast-", {"ultra-fast-logistics", "express-miniloader"})
  create_miniloader("ub-extreme-fast-", {"extreme-fast-logistics", "ub-ultra-fast-miniloader"})
  create_miniloader("ub-ultra-express-", {"ultra-express-logistics", "ub-extreme-fast-miniloader"})
  create_miniloader("ub-extreme-express-", {"extreme-express-logistics", "ub-ultra-express-miniloader"})
  create_miniloader("ub-ultimate-", {"ultimate-logistics", "ub-extreme-express-miniloader"})
end