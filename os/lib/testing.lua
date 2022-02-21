local class = require "class"

class.classes.Test = {
    Hello="World",
    __init = function (self)
        print("initializing "..tostring(self))
    end
}

class.classes.TestInherit = {
    __inherit = class.classes.Test,
    __tostring = function (self)
        return "Hello World"
    end,
    Hello="A new World"
}

class.classes.TestDoubleInherit = {
    __inherit = class.classes.TestInherit,
}


local test = class.classes.TestInherit()

print(test.Hello)

print(class.isInstanceOf(test, class.classes.TestInherit))
print(class.isInstanceOf(test, class.classes.Test))
print(class.isInstanceOf(class.classes.Test, class))
print(class.classes.Test < class.classes.TestInherit)
print(class.classes.Test < class.classes.TestDoubleInherit)
print(not (class.classes.Test > class.classes.TestInherit))

local json = require "json"

local encoded = json.encode(test)

print(encoded)

local decoded = json.decode(encoded)

print(decoded.Hello)

class.classes.Wrapper = {
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

local postive = class.classes.Wrapper(50)

local negative = -postive

print(postive, negative)
print(negative < postive)

class.classes.ReverseKey = {

    __init = function (self, val)
        self.val = val
    end,
    __index = function (self, key)
        print(self, self.val)
        return key:reverse()
    end
}

class.classes.InheritedReverseKey = {
    __inherit = class.classes.ReverseKey,
}

local reverser = class.classes.ReverseKey "Instance"
print(reverser.HelloWorld)

local reverser2 = class.classes.InheritedReverseKey "Instance 2"
print(reverser2.HelloWorld)
print(class.classes.InheritedReverseKey.val == nil and class.classes.ReverseKey.val == nil)

if _CC_MODE or __OP__MODE then
    local storage = require "storage"

    local container = storage "container.json"

    print(container.index.settings, container.index.settings.index.testVar)

    local settings = storage "settings.json"
    print(settings.index.testVar)
    settings.index.testVar = (settings.index.testVar or 0) + 1
    settings:save()

    container.index.settings = settings
    container:save()
end
