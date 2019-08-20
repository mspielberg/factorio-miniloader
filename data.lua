local entities = require "prototypes.entities"
local items = require "prototypes.items"
local recipes = require "prototypes.recipes"
local technologies = require "prototypes.technologies"
local templates = require "prototypes.templates"

local function create_miniloader(prefix, next_prefix, tech_prereqs, tint, base_underground_name)
  base_underground_name = base_underground_name or (prefix .. "underground-belt")
  entities.create_loaders(prefix, base_underground_name, tint)
  entities.create_inserters(prefix, next_prefix, base_underground_name, tint)
  items.create_items(prefix, base_underground_name, tint)
  recipes.create_recipes(prefix)
  technologies.create_technology(prefix, tech_prereqs, tint)
end

for prefix, args in pairs(templates) do
  create_miniloader(prefix, args.next_prefix, args.prerequisite_techs, args.tint, args.base_underground_name)
end

-- chute
create_miniloader("chute-", "", {"logistics"}, {r=0.5,g=0.5,b=0.5}, "underground-belt")

data.raw.technology["chute-miniloader"] = nil
data.raw.recipe["chute-miniloader"].enabled = true
data.raw.loader["chute-miniloader-loader"].speed = data.raw.loader["chute-miniloader-loader"].speed / 4
data.raw.inserter["chute-miniloader-inserter"].rotation_speed = data.raw.inserter["chute-miniloader-inserter"].rotation_speed / 4
data.raw.inserter["chute-miniloader-inserter"].energy_source = {type="void"}
data.raw.inserter["chute-miniloader-inserter"].energy_per_movement = ".0000001J"
data.raw.inserter["chute-miniloader-inserter"].energy_per_rotation = ".0000001J"

data.raw.item["chute-filter-miniloader"] = nil
data.raw.recipe["chute-filter-miniloader"] = nil
data.raw.loader["chute-filter-miniloader-loader"] = nil
data.raw.inserter["chute-filter-miniloader-inserter"] = nil
