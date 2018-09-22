local create_miniloader = require "prototypes.miniloader"
require "prototypes.signal"

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