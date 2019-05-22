local empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 1,
  height = 1,
  frame_count = 1,
}

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
  entity.minable = { mining_time = 0.1, count = 0, result = "wood" }
  entity.collision_box = {{-0.2, -0.1}, {0.2, 0.1}}
  entity.collision_mask = {}
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
  entity.next_upgrade = nil

  if entity.speed > 0.16 then
    -- BETA support for Ultimate Belts
    entity.container_distance = 1
    entity.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
    entity.selection_priority = 100
  end

  local filter_entity = util.table.deepcopy(entity)
  filter_entity.name = filter_loader_name .. "-loader"
  filter_entity.structure.direction_in.sheets[1].filename = "__miniloader__/graphics/entity/filter-template.png"
  filter_entity.structure.direction_in.sheets[1].hr_version.filename = "__miniloader__/graphics/entity/hr-filter-template.png"
  filter_entity.structure.direction_out.sheets[1].filename = "__miniloader__/graphics/entity/filter-template.png"
  filter_entity.structure.direction_out.sheets[1].hr_version.filename = "__miniloader__/graphics/entity/hr-filter-template.png"
  filter_entity.filter_count = 5

  data:extend{
    entity,
    filter_entity,
  }
end

local connector_definitions = circuit_connector_definitions.create(
  universal_connector_template,
  {
    { variation = 24, main_offset = util.by_pixel(-17, 0), shadow_offset = util.by_pixel(10, -0.5), show_shadow = false },
    { variation = 24, main_offset = util.by_pixel(-14, 0), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
    { variation = 24, main_offset = util.by_pixel(-17, 0), shadow_offset = util.by_pixel(-2.5, 6), show_shadow = false },
    { variation = 31, main_offset = util.by_pixel(14, 0), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
  }
)

local function create_inserters(prefix, next_prefix, base_underground_name, tint)
  local loader_name = prefix .. "miniloader"
  local name = loader_name .. "-inserter"
  local next_upgrade = next_prefix and next_prefix .. "miniloader-inserter"
  local filter_loader_name = prefix .. "filter-miniloader"
  local filter_name = filter_loader_name .. "-inserter"
  local filter_next_upgrade = next_prefix and next_prefix .. "filter-miniloader-inserter"
  local base_entity = data.raw["underground-belt"][base_underground_name]
  local speed = base_entity.speed * 0.65 / 0.03125

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
    minable = { mining_time = 0.1, result = loader_name },
    collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    selection_priority = 50,
    allow_custom_vectors = true,
    energy_per_movement = ".0000001J",
    energy_per_rotation = ".0000001J",
    energy_source = {
      type = "void",
    },
    extension_speed = 1,
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
    next_upgrade = next_upgrade,
  }

  if settings.startup["miniloader-energy-usage"].value then
    loader_inserter.energy_per_movement = "2kJ"
    loader_inserter.energy_per_rotation = "2kJ"
    loader_inserter.energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    }
  end

  for _,k in ipairs{"flags", "max_health", "resistances", "vehicle_impact_sound"} do
    loader_inserter[k] = base_entity[k]
  end

  local filter_loader_inserter = util.table.deepcopy(loader_inserter)
  filter_loader_inserter.name = filter_name
  filter_loader_inserter.localised_name = {"entity-name." .. filter_loader_name}
  filter_loader_inserter.icons[1].icon = "__miniloader__/graphics/item/filter-template.png"
  filter_loader_inserter.platform_picture.sheets[1].filename = "__miniloader__/graphics/entity/filter-template.png"
  filter_loader_inserter.platform_picture.sheets[1].hr_version.filename = "__miniloader__/graphics/entity/hr-filter-template.png"
  filter_loader_inserter.minable.result = filter_loader_name
  filter_loader_inserter.filter_count = 5
  filter_loader_inserter.next_upgrade = filter_next_upgrade

  data:extend{
    loader_inserter,
    filter_loader_inserter,
  }
end

return {
  create_loaders = create_loaders,
  create_inserters = create_inserters,
}