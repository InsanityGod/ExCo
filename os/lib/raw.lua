local next = next

local function iter (a, i)
    i = i + 1
    local v = a[i]
    if v then
        return i, v
    end
end

local raw = {
    next = next,
    ipairs = function (t)
        return iter, t, 0
    end,
    pairs = function (t)
        return next, t, nil
    end
}

return setmetatable({
    ensureRaw = function (k, v)
        if raw[k] ~= nil then
            return raw[k]
        end
        raw[k] = v
        return v
    end
},{
    __index = raw,
    __newindex = function (self, k, v)
        if raw[k] == nil then
            raw[k] = v
        end
    end
})