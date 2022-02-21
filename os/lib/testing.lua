local type = require "class"
type.classes.Test = {
    Hello="World",
    __init = function (self)
        print("initializing "..tostring(self))
    end
}

type.classes.TestInherit = {
    __inherit = type.classes.Test,
    __tostring = function (self)
        return "Hello World"
    end
}

type.classes.TestDoubleInherit = {
    __inherit = type.classes.TestInherit,
}


local test = type.classes.TestInherit()

print(type.isInstanceOf(test, type.classes.TestInherit))
print(type.isInstanceOf(test, type.classes.Test))
print(type.isInstanceOf(type.classes.Test, type))
print(type.classes.Test < type.classes.TestInherit)
print(type.classes.Test < type.classes.TestDoubleInherit)
print(not (type.classes.Test > type.classes.TestInherit))

local json = require "json"

local encoded = json.encode(test)

print(encoded)

local decoded = json.decode(encoded)

print(decoded.Hello)

type.classes.Wrapper = {
    __init = function (self, val)
        self.val = val
    end,
    __unm = function (self)
        return self.__class(-self.val)
    end,
    __tostring = function (self)
        return tostring(self.val)
    end,
    __lt = function (a, b)
        return a.val < b.val
    end
}

local postive = type.classes.Wrapper(50)

local negative = -postive

print(postive, negative)
print(negative < postive)