-- Converts hex code values to rgb values, alpha is an optional parameter
local function tint_from_hex(hex, alpha)
  hex = hex:gsub("#","")
  tint = {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}

  -- Masks require an alpha to look correct, but it may be desirable not to use an 
  -- alpha value in some cases (e.g. explosion particles).
  if alpha then
    table.insert(tint, alpha*255)
  end

  return tint
end

local templates = {
  [""] = {
    next_prefix = "fast-",
    prerequisite_techs = {"logistics", "fast-inserter"},
    tint = tint_from_hex("ffc340", 0.82),
  },
  ["fast-"] = {
    next_prefix = "express-",
    prerequisite_techs = {"logistics-2", "miniloader"},
    tint = tint_from_hex("e31717", 0.82),
  },
  ["express-"] = {
    prerequisite_techs = {"logistics-3", "fast-miniloader"},
    tint = tint_from_hex("43c0fa", 0.82),
  }
}

-- Bob's support
if data.raw.item["basic-transport-belt"] then
  local hex, alpha
  if mods["boblogistics-belt-reskin"] then
    hex = "000000"
    alpha = 0
  else
    hex = "7d7d7d"
    alpha = 0.82
  end
  templates["basic-"] = {
    next_prefix = "",
    prerequisite_techs = {"logistics-0"},
    tint = tint_from_hex(hex, alpha), 
  }
  templates[""].prerequisite_techs = {"logistics", "basic-miniloader"}
end

if data.raw.item["turbo-transport-belt"] then
  local turbo_hex
  if mods["boblogistics-belt-reskin"] then
    turbo_hex = "df1ee5"
  else
    turbo_hex = "a510e5"
  end
  templates["express-"].next_prefix = "turbo-"
  templates["turbo-"] = {
    next_prefix = "ultimate-",
    prerequisite_techs = {"logistics-4", "express-miniloader"},
    tint = tint_from_hex(turbo_hex, 0.82),
  }
  templates["ultimate-"] = {
    prerequisite_techs = {"logistics-5", "turbo-miniloader"},
    tint = tint_from_hex("16f263", 0.82),
  }
end

-- FactorioExtended-Plus-Transport support
if data.raw.item["rapid-transport-belt-mk2"] then
  templates["express-"].next_prefix = "rapid-mk1-"
  templates["rapid-mk1-"] = {
    next_prefix = "rapid-mk2-",
    prerequisite_techs = {"logistics-4", "express-miniloader"},
    tint = tint_from_hex("2cd529", 0.82),
    base_underground_name = "rapid-transport-belt-to-ground-mk1",
  }
  templates["rapid-mk2-"] = {
    prerequisite_techs = {"logistics-5", "rapid-mk1-miniloader"},
    tint = tint_from_hex("9a2cc9", 0.82),
    base_underground_name = "rapid-transport-belt-to-ground-mk2",
  }
end

-- Krastorio support
-- Note: Krastorio Legacy is deprecated, and additionally due to changes to Character 
-- Logistics slots is now non-functional for Factorio > 0.18.18
if data.raw.item["k-transport-belt"] then
  templates["express-"].next_prefix = "k-"
  templates["k-"] = {
    prerequisite_techs = {"k-advanced-logistics", "express-miniloader"},
    tint = tint_from_hex("971dc6", 0.86),
    base_underground_name = "k-underground-belt",
  }
end

-- Krastorio2 support
if data.raw.item["kr-superior-transport-belt"] then
  templates["express-"].next_prefix = "kr-advanced-"
  templates["kr-advanced-"] = {
    prerequisite_techs = {"kr-logistic-4", "express-miniloader"},
    tint = tint_from_hex("3ade21", 0.82),
  }
  templates["kr-superior-"] = {
    prerequisite_techs = {"kr-logistic-5", "kr-advanced-miniloader"},
    tint = tint_from_hex("a30bd6", 0.82),
  }
end

-- UltimateBelts support
if data.raw.technology["ultimate-logistics"] then
  -- Support both sets of Ultimate Belt colors
  local ub_hexes = {}  
  if mods["UltimateBelts_Owoshima_And_Pankeko-Mod"] then
    -- Pankeko UB colors
    ub_hexes.ultra_fast      = {"2bc24b", 0.86}
    ub_hexes.extreme_fast    = {"c4632f", 0.86}
    ub_hexes.ultra_express   = {"6f2de0", 0.82}
    ub_hexes.extreme_express = {"3d3af0", 0.86}
    ub_hexes.ultimate        = {"999999", 0.82}
  else
    -- Standard UB colors
    ub_hexes.ultra_fast      = {"00b30c", 1}
    ub_hexes.extreme_fast    = {"e00000", 1}
    ub_hexes.ultra_express   = {"3604b5", 0.91}
    ub_hexes.extreme_express = {"002bff", 1}
    ub_hexes.ultimate        = {"00ffdd", 0.82}
  end

  -- Setup miniloaders
  templates["ub-ultra-fast-"] = {
    next_prefix = "ub-extreme-fast-",
    prerequisite_techs = {"ultra-fast-logistics",      "express-miniloader"},
    tint = tint_from_hex(ub_hexes.ultra_fast[1], ub_hexes.ultra_fast[2]),
    base_underground_name = "ultra-fast-underground-belt",
  }
  templates["ub-extreme-fast-"] = {
    next_prefix = "ub-ultra-express-",
    prerequisite_techs = {"extreme-fast-logistics",    "ub-ultra-fast-miniloader"},
    tint = tint_from_hex(ub_hexes.extreme_fast[1], ub_hexes.extreme_fast[2]),
    base_underground_name = "extreme-fast-underground-belt",
  }
  templates["ub-ultra-express-"] = {
    next_prefix = "ub-extreme-express-",
    prerequisite_techs = {"ultra-express-logistics",   "ub-extreme-fast-miniloader"},
    tint = tint_from_hex(ub_hexes.ultra_express[1], ub_hexes.ultra_express[2]),
    base_underground_name = "ultra-express-underground-belt",
  }
  templates["ub-extreme-express-"] = {
    next_prefix = "ub-ultimate-",
    prerequisite_techs = {"extreme-express-logistics", "ub-ultra-express-miniloader"},
    tint = tint_from_hex(ub_hexes.extreme_express[1], ub_hexes.extreme_express[2]),
    base_underground_name = "extreme-express-underground-belt",
  }
  templates["ub-ultimate-"] = {
    prerequisite_techs = {"ultimate-logistics",        "ub-extreme-express-miniloader"},
    tint = tint_from_hex(ub_hexes.ultimate[1], ub_hexes.ultimate[2]),
    base_underground_name = "original-ultimate-underground-belt",
  }
end

-- xander-mod support
-- Note: Xander mod no longer appears to have an expedited transport belt. 
-- It does have a low-level Crude belt.
if data.raw.item["expedited-transport-belt"] then
  templates["fast-"].next_prefix = "expedited-"
  templates["expedited-"] = {
    next_prefix = "express-",
    prerequisite_techs = {"logistics-3", "fast-miniloader"},
    tint = {r=0.40, g=0.70, b=0.40},
  }
  templates["express-"].prerequisite_techs = {"logistics-4", "expedited-miniloader"}
end

-- space-exploration support
if data.raw.item["se-space-transport-belt"] then
  templates["space-"] = {
    prerequisite_techs = {"se-space-platform-scaffold"},
    base_underground_name = "se-space-underground-belt",
  }
end

return templates
