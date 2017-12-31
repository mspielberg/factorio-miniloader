local util = require "lualib.util"

local M = {}

local behavior_cache
local proxy_iter

local function proxy_behavior(proxy)
    local behavior = proxy.get_control_behavior()
    if not behavior then
        return false
    end
    return {
        circuit = behavior.circuit_condition,
        logistic = behavior.logistic_condition,
        logistic_connected = behavior.connect_to_logistic_network,
    }
end

local function signals_match(s1, s2)
    if s1 == s2 then
        return true
    end
    if not s1 or not s2 then
        return false
    end
    return s1.type == s2.type and s1.name == s2.name
end

local function conditions_match(c1, c2)
    return c1.comparator == c2.comparator and
        signals_match(c1.first_signal, c2.first_signal) and
        signals_match(c1.second_signal, c2.second_signal) and
        c1.constant == c2.constant
end

local function behaviors_match(b1, b2)
    if b1 == b2 then
        return true
    end
    if not b1 or not b2 then
        return false
    end
    local result = conditions_match(b1.circuit.condition, b2.circuit.condition) and
        conditions_match(b1.logistic.condition, b2.logistic.condition) and
        b1.logistic_connected == b2.logistic_connected
    log(serpent.line(result))
    return result
end

local function cache_up_to_date(proxy)
    return behaviors_match(proxy_behavior(proxy), proxy_behavior(behavior_cache[proxy]))
end

local function update_inserters(proxy, proxy_behavior)
    for _, inserter in ipairs(util.get_loader_inserters(proxy)) do
        local inserter_behavior = inserter.get_or_create_control_behavior()
        inserter_behavior.circuit_condition = proxy_behavior.circuit
        inserter_behavior.logistic_condition = proxy_behavior.logistic
        inserter_behavior.connect_to_logistic_network = proxy_behavior.logistic_connected
    end
end

local function initialize_cache()
    behavior_cache = {}
    for _, s in pairs(game.surfaces) do
        for _, entity in ipairs(s.find_entities_filtered{ type="pump" }) do
            if util.is_circuit_proxy(entity) then
                M.register_proxy(entity)
            end
        end
    end
end

function M.on_tick(event)
    if not behavior_cache then
        initialize_cache()
    end

    if event.tick % 60 ~= 0 then
        return
    end

    local cached_behavior
    proxy_iter, cached_behavior = next(behavior_cache, proxy_iter)
    if not proxy_iter then
        return
    end
    local current_behavior = proxy_behavior(proxy_iter)
    if not behaviors_match(current_behavior, cached_behavior) then
        behavior_cache[proxy_iter] = current_behavior
        update_inserters(proxy_iter, current_behavior)
    end
end

function M.register_proxy(proxy)
    behavior_cache[proxy] = proxy_behavior(proxy)
    proxy_iter = nil
end

function M.unregister_proxy(proxy)
    behavior_cache[proxy] = nil
end

return M