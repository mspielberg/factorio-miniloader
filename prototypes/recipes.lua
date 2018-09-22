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

return create_recipes