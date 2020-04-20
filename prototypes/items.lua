local function create_items(prefix, base_underground_name, tint)
  local name = prefix .. "miniloader"
  local filter_name = prefix .. "filter-miniloader"

  local item = util.table.deepcopy(data.raw.item[base_underground_name])
  item.name = name
  item.localised_name = {"entity-name." .. name}
  item.icon = nil
  item.icons = {
    {
      icon = "__miniloader__/graphics/item/icon-base.png",
      icon_size = 64,
    },
    {
      icon = "__miniloader__/graphics/item/icon-mask.png",
      icon_size = 64,
      tint = tint,
    },
  }
  item.order, _ = string.gsub(item.order, "^b%[underground%-belt%]", "e[miniloader]", 1)
  item.order, _ = string.gsub(item.order, "^c%[rapid%-transport%-belt%-to%-ground.*%]", "e[miniloader]", 1)
  item.place_result = name .. "-inserter"

  local filter_item = util.table.deepcopy(item)
  filter_item.name = filter_name
  filter_item.localised_name = {"entity-name." .. filter_name}
  filter_item.icons[1].icon = "__miniloader__/graphics/item/filter-icon-base.png"
  filter_item.order, _ = string.gsub(item.order, "e%[", "f[filter-", 1)
  filter_item.place_result = filter_name .. "-inserter"

  if settings.startup["miniloader-enable-standard"].value then
    data:extend{item}
  end
  if settings.startup["miniloader-enable-filter"].value then
    data:extend{filter_item}
  end
end

return {
  create_items = create_items,
}
