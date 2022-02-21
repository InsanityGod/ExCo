_CC_MODE = fs and true or false
__OP__MODE = component and true or false

if _CC_MODE then -- CC Tweaked

    --TODO old version compatability
    package.path = package.path..";lib/?.lua;lib/cc/?.lua"
    package.loaded['filesystem'] = fs

    require "testing"

elseif __OP__MODE then -- OpenComputerMode

    require "testing"

else -- Debug Mode

    package.path = "D:\\Coding\\Lua\\ExCo\\os\\lib\\?.lua"
    require "testing"

end
