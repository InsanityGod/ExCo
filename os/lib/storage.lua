
local class = require "class"
local json = require "json"
local fs = require "filesystem"

local cache = setmetatable({},{__mode="v"})

class.classes.Storage = {
    __init = function (self, path)
        --TODO type check
        self.path = path
        cache[path] = self
        self:load()
    end,
    __call = function (cls, path)
        return cache[path] or class.__call(cls, path)
    end,
    load = function (self)
        self.index = self.index or (fs.exists(self.path) and json.decodeFromFile(self.path) or {})
    end,
    save = function (self)
        local f = fs.open(self.path, "w")
        f.write(json.encode(self.index))
        f.flush()
        f.close()
    end,
    __fromJSON = function (cls, self)
        self = cache[self.path] or class.__fromJSON(cls, self)
        cache[self.path] = self
        self:load()
        return self
    end,
    __jsonIgnore = {index = true},
    --__toJSON = function (self, pretty, tabLevel, tTracking)
    --    return json.encoders.table(self, pretty, tabLevel, tTracking, false, jsonIgnore)
    --end
}
return class.classes.Storage
