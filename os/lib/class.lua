local raw = require "raw"
local _type = raw.ensureRaw("type", type)
local type

local rawequal = rawequal
local rawget = rawget


local classes = {}

local function isClass(class)
    return rawequal(classes[class.__name], class)
end

local function isInstanceOf(obj, class)
    local obj_class = obj.__class
    if isClass(obj_class) then
        return obj_class:__extends(class) -- TODO interfaces
    end
    return false
end

local function sameClass(a, b)
    local a_class = a.__class
    if a_class and isClass(a_class) then
        return rawequal(a_class, b.__class)
    end
    return false
end

local function relay(name)
    return function (self, ...)
        local func = self.__class[name]
        if func then
            return func(self, ...)
        end
    end
end

local function relay_comp(name)
    return function (a, b)
        if sameClass(a, b) then
            local func = a.__class[name]
            if func ~= nil then
                return func(a, b)
            end
        end
        error "not supported"
    end
end

local function relay_math(name)
    return function (instance, o)
        local func = instance.__class[name]
        if func then
            return func(instance, o)
        end

        error "not supported"
    end
end

local type_instance_meta = {
    __index = function (self, k)
        local result
        if self.__class == type then
            if self.__inherit then
                result = self.__inherit[k]
                if result ~= nil then return result end
            end
        end

        result = self.__class[k]

        if result ~= nil then return result end

        local index = self.__class.__index

        if index ~= nil then
            return index(self, k)
        end
    end,
    __tostring = relay "__tostring",
    __call = relay "__call",

    __eq = relay_comp "__eq",
    __lt = relay_comp "__lt",
    __le = relay_comp "__le",

    --TODO test below

    __unm = relay_math "__unm",

    __add = relay_math "__add",
    __sub = relay_math "__sub",
    __mul = relay_math "__mul",
    __div = relay_math "__div",
    __mod = relay_math "__mod",
    __pow = relay_math "__pow",
    __concat = relay_math "__concat",

    __idiv = relay_math "__idiv" , -- lua 5.3
}

local function create_type(name, table)
    table.__class = type
    table.__name = name
    table.__inherit = table.__inherit or type
    return setmetatable(table, type_instance_meta)
end

type = setmetatable({
    classes = setmetatable({},{
        __index = classes,
        __newindex = function (self, k, v)
            if _type(k) ~= "string" then error("key should be string but "..type(k).." was given") end
            if classes[k] ~= nil then error(k.." is already defined") end
            if _type(v) == "table" then v = create_type(k, v) end
            if type(v) ~= type then error("type was expected but "..type(v).." was given") end
            classes[k] = v
        end,
    }),
    __new = function (cls, ...)
        return setmetatable({
            __class=cls
        }, type_instance_meta)
    end,
    __init = function ()
        --Empty Stump
    end,
    __call = function (cls, ...)
        if cls.__class ~= type then error(cls.." is not callable") end
        local instance = cls:__new(...)
        instance:__init(...)

        return instance
    end,
    __tostring = function (self)
        return self.__class.__name
    end,
    __extends = function (self, class)
        if rawequal(self, class) then
            return true
        end
        if self.__inherit and not rawequal(self.__inherit, type) then
            return self.__inherit:__extends(class)
        end

        return false
    end,
    __eq = function ()
        return false -- Two different types are not allowed to be the same
    end,
    __lt = function (a, b)
        if isClass(a) then
            return b:__extends(a)
        end
        error "not supported"
    end,
    __le = function (a,b)
        if isClass(a) then
            return b:__extends(a) -- Two different types are not allowed to be the same
        end
        error "not supported"
    end,
    __name="type",
    isInstanceOf = isInstanceOf,
    isClass=isClass,
    sameClass=sameClass,
},{
    __call = function (self, v)
        local real_type = _type(v)
        if real_type == "table" then
            local class = v.__class
            if class and isClass(class) then
                return class
            end
        end
        return real_type
    end
})

classes["type"] = type

--JSON
package.loaded["class"] = type
local json = require "json"

 function type.__fromJSON(cls, v)
    v.__class = cls
    setmetatable(v, type_instance_meta)
    return v
end

type.__jsonIgnore = {}

function type.__toJSON(self, pretty, tabLevel, tTracking)
    if isClass(self) then
        return json.encoders.string(self.__name)
    end
    return json.encoders.table(self, pretty, tabLevel, tTracking, false, self.__class.__jsonIgnore)
end

json.commonEncoders[#json.commonEncoders+1] = function (valType, val, pretty, tabLevel, tTracking)
    if _type(val) == "table" then
        local class = val.__class
        if isClass(class) then
            return class.__toJSON(val, pretty, tabLevel, tTracking)
        end
    end
end

json.commonDecoders[#json.commonDecoders+1] = function (v)
    local class = classes[v.__class]

    if class then
        return class:__fromJSON(v)
    end
end

return type
