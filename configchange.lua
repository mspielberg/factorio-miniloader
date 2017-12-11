local configchange = {}

local version = require("version")

local v1_1_4_inserter_cleanup = {
    name = "v1_1_4_inserter_cleanup",
    low = {1,1,0},
    high = {1,1,4},
    task = function()
        for _, surface in pairs(game.surfaces) do
            log("searching surface "..surface.name.." for orphan miniloader-inserter entities")
            for _, inserter in ipairs(surface.find_entities_filtered{name="miniloader-inserter"}) do
                local loader = surface.find_entity("miniloader", inserter.position)
                if not loader then
                    log("destroying orphan at "..serpent.line(inserter.position))
                    inserter.destroy()
                end
            end
        end
    end,
}

local all_migrations = {v1_1_4_inserter_cleanup}

function configchange.on_mod_version_changed(old)
    old = version.parse(old)
    for _, migration in ipairs(all_migrations) do
        if version.between(old, migration.low, migration.high) then
            log("running world migration "..migration.name)
            migration.task()
        end
    end
end

return configchange