-- boblogistics does some late changes in the data-updates phase, so we need to react to them here

local function update(prefix)
  local loader = data.raw["loader"][prefix .. "miniloader-loader"]
  local loader_item = data.raw["item"][prefix .. "miniloader"]
  local filter_loader = data.raw["loader"][prefix .. "filter-miniloader-loader"]
  local filter_loader_item = data.raw["item"][prefix .. "filter-miniloader"]
  prefix = string.gsub(prefix, "^ub%-", "")
  local base_underground = data.raw["underground-belt"][prefix .. "underground-belt"]
  local base_underground_item = data.raw["item"][prefix .. "underground-belt"]

  loader.speed = base_underground.speed
  loader_item.subgroup = base_underground_item.subgroup
  filter_loader.speed = base_underground.speed
  filter_loader_item.subgroup = base_underground_item.subgroup
end

update("")
update("fast-")
update("express-")

if data.raw["underground-belt"]["turbo-underground-belt"] then
  update("turbo-")
end
if data.raw["underground-belt"]["ultimate-underground-belt"] then
  update("ultimate-")
end