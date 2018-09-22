require "util"

local create_recipes = require "prototypes.recipes"

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
          width = 106,
          height = 85,
          y = 85,
          scale = 0.5
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 106,
          height = 85,
          y = 85,
          scale = 0.5,
          tint = tint,
        },
      }
    },
    direction_out = {
      sheets = {
        {
          filename = "__miniloader__/graphics/entity/template.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 106,
          height = 85,
          scale = 0.5,
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 106,
          height = 85,
          scale = 0.5,
          tint = tint,
        },
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
    { variation = 1, main_offset = {0,-0.2}, shadow_offset = {0,0}, show_shadow = false },
    { variation = 1, main_offset = {0,-0.2}, shadow_offset = {0,0}, show_shadow = false },
    { variation = 1, main_offset = {0,-0.4}, shadow_offset = {0,0}, show_shadow = false },
    { variation = 1, main_offset = {0,-0.2}, shadow_offset = {0,0}, show_shadow = false },
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
          width = 106,
          height = 85,
          y = 85,
          scale = 0.5
        },
        {
          filename = "__miniloader__/graphics/entity/mask.png",
          priority = "extra-high",
          shift = {0.15625, 0.0703125},
          width = 106,
          height = 85,
          y = 85,
          scale = 0.5,
          tint = tint,
        },
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

return create_miniloader