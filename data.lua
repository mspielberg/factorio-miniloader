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
    {"original-ultimate-underground-belt", 1},
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
local function create_legacy_underground(prefix, base_underground_name)
  local name = prefix .. "miniloader-legacy-underground"

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
  entity.speed = data.raw["underground-belt"][base_underground_name].speed
  entity.max_distance = 0
  entity.underground_sprite = empty_sheet
  entity.underground_remove_belts_sprite = empty_sheet
  entity.structure = {
    direction_in = empty_sheet,
    direction_out = empty_sheet,
  }
  data:extend{entity}
end

local function create_loaders(prefix, base_underground_name, tint)
  local loader_name = prefix .. "miniloader"
  local filter_loader_name = prefix .. "filter-miniloader"
  local name = loader_name .. "-loader"

  local entity = util.table.deepcopy(data.raw["underground-belt"][base_underground_name])
  entity.type = "loader"
  entity.name = name
  entity.icons = nil
  entity.flags = {"player-creation"}
  entity.localised_name = {"entity-name." .. loader_name}
  entity.minable = { mining_time = 1, count = 0, result = "raw-wood" }
  entity.collision_box = {{-0.2, -0.1}, {0.2, 0.1}}
  entity.selection_box = {{0, 0}, {0, 0}}
  entity.filter_count = 0
  entity.structure = {
    direction_in = {
      sheets = {
        {
          filename = "__miniloader__/graphics/entity/template.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          y = 43,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-template.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            y = 85,
            scale = 0.5
          }
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          y = 43,
          tint = tint,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-mask.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            y = 85,
            scale = 0.5,
            tint = tint,
          },
        }
      }
    },
    direction_out = {
      sheets = {
        {
          filename = "__miniloader__/graphics/entity/template.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-template.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            scale = 0.5
          }
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          tint = tint,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-mask.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            scale = 0.5,
            tint = tint,
          },
        }
      }
    },
  }
  entity.belt_distance = 0
  entity.container_distance = 0
  entity.belt_length = 0.5

  if entity.speed > 0.16 then
    -- BETA support for Ultimate Belts
    entity.container_distance = 1
    entity.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
    entity.selection_priority = 100
  end

  local filter_entity = util.table.deepcopy(entity)
  filter_entity.name = filter_loader_name .. "-loader"
  filter_entity.structure.direction_in.sheets[1].filename = "__miniloader__/graphics/entity/filter-template.png"
  filter_entity.structure.direction_out.sheets[1].filename = "__miniloader__/graphics/entity/filter-template.png"
  filter_entity.filter_count = 5

  data:extend{
    entity,
    filter_entity,
  }
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

local function create_inserters(prefix, base_underground_name, tint)
  local loader_name = prefix .. "miniloader"
  local name = loader_name .. "-inserter"
  local filter_loader_name = prefix .. "filter-miniloader"
  local filter_name = filter_loader_name .. "-inserter"
  local base_entity = data.raw["underground-belt"][base_underground_name]
  local speed = base_entity.speed * 0.5 / 0.03125

  local loader_inserter = {
    type = "inserter",
    name = name,
    -- this name and icon appear in the power usage UI
    localised_name = {"entity-name." .. loader_name},
    icons = {
      {
        icon = "__miniloader__/graphics/item/template.png",
        icon_size = 32,
      },
      {
        icon = "__miniloader__/graphics/item/mask.png",
        icon_size = 32,
        tint = tint,
      },
    },
    minable = { mining_time = 1, result = loader_name },
    collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    selection_priority = 50,
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
      sheets = {
        {
          filename = "__miniloader__/graphics/entity/template.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-template.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            y = 85,
            scale = 0.5
          }
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 53,
          height = 43,
          tint = tint,
          hr_version = {
            filename = "__miniloader__/graphics/entity/hr-mask.png",
            priority = "extra-high",
            shift = {0.15625, 0.0703125},
            width = 106,
            height = 85,
            y = 85,
            scale = 0.5,
            tint = tint,
          },
        }
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
  table.insert(loader_inserter.flags, "hide-alt-info")

  local filter_loader_inserter = util.table.deepcopy(loader_inserter)
  filter_loader_inserter.name = filter_name
  filter_loader_inserter.localised_name = {"entity-name." .. filter_loader_name}
  filter_loader_inserter.icons[1].icon = "__miniloader__/graphics/item/filter-template.png"
  filter_loader_inserter.minable.result = filter_loader_name
  filter_loader_inserter.filter_count = 5

  data:extend{
    loader_inserter,
    filter_loader_inserter,
  }
end

local function create_items(prefix, base_underground_name, tint)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"

  local item = util.table.deepcopy(data.raw.item[base_underground_name])
  item.name = name
  item.localised_name = {"entity-name." .. name}
  item.icon = nil
  item.icons = {
    {
      icon = "__miniloader__/graphics/item/template.png",
      icon_size = 32,
    },
    {
      icon = "__miniloader__/graphics/item/mask.png",
      icon_size = 32,
      tint = tint,
    },
  }
  item.order, _ = string.gsub(item.order, "^b%[underground%-belt%]", "e[miniloader]", 1)
  item.place_result = name .. "-inserter"

  local filter_item = util.table.deepcopy(item)
  filter_item.name = filter_name
  filter_item.localised_name = {"entity-name." .. filter_name}
  filter_item.icons[1].icon = "__miniloader__/graphics/item/filter-template.png"
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

local function create_technology(prefix, tech_prereqs, base_underground_name, tint)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"

  local main_prereq = data.raw["technology"][tech_prereqs[1]]
  local technology = {
    type = "technology",
    name = name,
    icons = {
      {
        icon = "__miniloader__/graphics/technology/template.png",
        icon_size = 128,
      },
      {
        icon = "__miniloader__/graphics/technology/mask.png",
        icon_size = 128,
        tint = tint,
      },
    },
    effects = {
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

  data:extend{technology}
end

local function create_miniloader(prefix, tech_prereqs, tint, base_underground_name)
  base_underground_name = base_underground_name or (prefix .. "underground-belt")
  create_legacy_underground(prefix, base_underground_name)
  create_loaders(prefix, base_underground_name, tint)
  create_inserters(prefix, base_underground_name, tint)
  create_items(prefix, base_underground_name, tint)
  create_recipes(prefix)
  create_technology(prefix, tech_prereqs, base_underground_name, tint)
end

create_miniloader("",         {"logistics-2"},                    {r=0.8,  g=0.6,  b=0.05})
create_miniloader("fast-",    {"miniloader"},                     {r=0.75, g=0.07, b=0.07})
create_miniloader("express-", {"logistics-3", "fast-miniloader"}, {r=0.25, g=0.65, b=0.82})

-- Bob's support
if data.raw.technology["bob-logistics-4"] then
  create_miniloader("turbo-", {"bob-logistics-4", "express-miniloader"}, {r=0.38, b=0.09, g=0.57})
  if data.raw.technology["bob-logistics-5"] then
    create_miniloader("ultimate-", {"bob-logistics-5", "turbo-miniloader"}, {r=0.08, b=0.625, g=0.2})
  end
end

-- UltimateBelts support
if data.raw.technology["ultimate-logistics"] then
  create_miniloader("ub-ultra-fast-",      {"ultra-fast-logistics",      "express-miniloader"},            {r=0,    g=0.7, b=0.29},  "ultra-fast-underground-belt")
  create_miniloader("ub-extreme-fast-",    {"extreme-fast-logistics",    "ub-ultra-fast-miniloader"},      {r=0.7,  g=0,    b=0.06}, "extreme-fast-underground-belt")
  create_miniloader("ub-ultra-express-",   {"ultra-express-logistics",   "ub-extreme-fast-miniloader"},    {r=0.29, g=0,    b=0.7},  "ultra-express-underground-belt")
  create_miniloader("ub-extreme-express-", {"extreme-express-logistics", "ub-ultra-express-miniloader"},   {r=0,    g=0.06, b=0.7},  "extreme-express-underground-belt")
  create_miniloader("ub-ultimate-",        {"ultimate-logistics",        "ub-extreme-express-miniloader"}, {r=0,    g=0.42, b=0.7},  "original-ultimate-underground-belt")
end