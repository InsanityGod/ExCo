local raw = require "raw"
local fs = require "filesystem"
local type = require "class"
local json = {}

------------------------------------------------------------------ utils
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}

local function isArray(t)
	local max = 0
	for k,v in raw.pairs(t) do
		if type(k) ~= "number" then
			return false
		elseif k > max then
			max = k
		end
	end
	return max == #t
end

local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
local function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

------------------------------------------------------------------ encoding

json.encoders = {}
json.commonEncoders = {}
local encoders, commenEncoders = json.encoders, json.commonEncoders
local encodeCommon

local function tab(str, tabLevel, s)
    return str .. ("\t"):rep(tabLevel) .. s
end
json.tab = tab

local function arrEncoding(val, pretty, tabLevel, tTracking, isarray, ignoreKeys)
    local str = isarray and "[" or "{"

    if pretty then
        str = str .. "\n"
        tabLevel = tabLevel + 1
    end
    local iterator = isarray and raw.ipairs or raw.pairs
    for k, v in iterator(val) do -- TODO
		if not ignoreKeys or not ignoreKeys[k] then
    	    assert(type(k) == "string", "JSON object keys must be strings")
	        str = tab(str, tabLevel, (isarray and encodeCommon(v, pretty, tabLevel, tTracking) or encodeCommon(k, pretty, tabLevel, tTracking)..(pretty and ": " or ":")..encodeCommon(v, pretty, tabLevel, tTracking))..(pretty and ",\n" or ","))
		end
    end

    if pretty then
        tabLevel = tabLevel - 1
    end

    if str:sub(-2) == ",\n" then
        str = str:sub(1, -3) .. "\n"
    elseif str:sub(-1) == "," then
        str = str:sub(1, -2)
    end

    return tab(str, tabLevel, isarray and "]" or "}")
end
json.arrEncoding = arrEncoding

function encoders.table(val, pretty, tabLevel, tTracking, isarray, ignoreKey)
    assert(not tTracking[val], "Cannot encode a table holding itself recursively")
	tTracking[val] = true
    local array
	if isarray ~= nil then
		array = isarray
	else
		array = isArray(val)
	end
	return arrEncoding(val, pretty, tabLevel, tTracking, array, ignoreKey)
end

function encoders.string(val)
    return '"'..val:gsub("[%c\"\\]", controls)..'"'
end

function encoders.number(val)
    return tostring(val)
end
encoders.boolean = encoders.number

function encodeCommon(val, pretty, tabLevel, tTracking)
	local str = ""

    local valType = type(val)
    local encoder = encoders[valType]
    if encoder then
        return str..encoder(val, pretty, tabLevel, tTracking)
    end
    for i, cEncoder in raw.ipairs(commenEncoders) do
        local encoded = cEncoder(valType, val, pretty, tabLevel, tTracking)
        if encoded then
            return str..encoded
        end
    end
    error("No JSON support for type '"..tostring(valType).."'")
end
json.encodeCommon = encodeCommon
function json.encode(val)
	return encodeCommon(val, false, 0, {})
end

function json.encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

------------------------------------------------------------------ decoding

local decodeControls = {}
for k,v in raw.pairs(controls) do
	decodeControls[v] = k
end
local parseValue, parseMember

json.commonDecoders = {}
local commonDecoders = json.commonDecoders

local function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

local function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
local function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

local function parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1,1) ~= "\"" do
		local next = str:sub(1,1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")

		if next == "\\" then
			local escape = str:sub(1,1)
			str = str:sub(2)

			next = assert(decodeControls[next..escape], "Invalid escape character")
		end

		s = s .. next
	end
	return s, removeWhite(str:sub(2))
end

local function parseArray(str)
	str = removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = parseValue(str)
		val[i] = v
		i = i + 1
		str = removeWhite(str)
	end
	return val, removeWhite(str:sub(2))
end

local function parseObject(str)
	str = removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))

	for _, commonDecoder in ipairs(commonDecoders) do
		local alt = commonDecoder(val)
		if alt then
			return alt, str
		end
	end

	return val, str
end

function parseMember(str)
	local k = nil
	k, str = parseValue(str)
	local val = nil
	val, str = parseValue(str)
	return k, val, str
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

function json.decode(str)
	str = removeWhite(str)
	t = parseValue(str)
	return t
end

function json.decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = json.decode(file.readAll())
	file.close()
	return decoded
end

return json
