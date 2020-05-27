-- boblogistics does some late changes in the data-updates phase, so we need to react to them here

local function update(prefix)
  local loader = data.raw["loader-1x1"][prefix .. "miniloader-loader"]
  local loader_item = data.raw["item"][prefix .. "miniloader"]
  local filter_loader = data.raw["loader-1x1"][prefix .. "filter-miniloader-loader"]
  local filter_loader_item = data.raw["item"][prefix .. "filter-miniloader"]
  prefix = string.gsub(prefix, "^ub%-", "")
  local base_underground = data.raw["underground-belt"][prefix .. "underground-belt"]
  local base_underground_item = data.raw["item"][prefix .. "underground-belt"]

  if loader then loader.speed = base_underground.speed end
  if loader_item then loader_item.subgroup = base_underground_item.subgroup end
  if filter_loader then filter_loader.speed = base_underground.speed end
  if filter_loader_item then filter_loader_item.subgroup = base_underground_item.subgroup end
end

update("basic-")
update("")
update("fast-")
update("express-")

if data.raw["item"]["turbo-miniloader"] then
  update("turbo-")
end
if data.raw["item"]["ultimate-miniloader"] then
  update("ultimate-")
end

if mods["boblogistics"] then
  bobmods.lib.tech.remove_science_pack("express-miniloader", "production-science-pack")
  if data.raw.tool["advanced-logistic-science-pack"] then
    bobmods.lib.tech.replace_science_pack("turbo-miniloader", "production-science-pack", "advanced-logistic-science-pack")
    bobmods.lib.tech.replace_science_pack("ultimate-miniloader", "production-science-pack", "advanced-logistic-science-pack")
    if settings.startup["followBobTiers"].value == true then
      bobmods.lib.tech.add_science_pack("ub-ultra-fast-miniloader", "advanced-logistic-science-pack", 1)
      bobmods.lib.tech.add_science_pack("ub-ultra-fast-miniloader", "utility-science-pack", 1)
      bobmods.lib.tech.replace_science_pack("ub-extreme-fast-miniloader", "production-science-pack", "advanced-logistic-science-pack")
      bobmods.lib.tech.add_science_pack("ub-extreme-fast-miniloader", "utility-science-pack", 1)
      bobmods.lib.tech.replace_science_pack("ub-ultra-express-miniloader", "production-science-pack", "advanced-logistic-science-pack")
      bobmods.lib.tech.add_science_pack("ub-ultra-express-miniloader", "utility-science-pack", 1)
      bobmods.lib.tech.replace_science_pack("ub-extreme-express-miniloader", "production-science-pack", "advanced-logistic-science-pack")
      bobmods.lib.tech.replace_science_pack("ub-ultimate-miniloader", "production-science-pack", "advanced-logistic-science-pack")
      bobmods.lib.tech.add_science_pack("ub-ultimate-miniloader", "space-science-pack", 1)
    end
  end
end

-- catch belt speed changes made by other mods in data stage
for name, ug in pairs(data.raw["underground-belt"]) do
  local prefix = name:match("(.*)%-underground%-belt")
  local miniloader = prefix and data.raw["loader-1x1"][prefix .. "-miniloader"]
  if miniloader then
    miniloader.speed = ug.speed
  end
end
