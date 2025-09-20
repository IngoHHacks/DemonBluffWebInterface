local chars = {}
local roles = {}

if char3 == nil then
    chars = {char1, char2}
    roles = {"Villager", evil}
else
    chars = {char1, char2, char3}
    roles = {"Villager", "Outcast", evil}
end
local extra_unknown = false
for _, c in ipairs(chars) do
    local type = c.character.type
    if c.character.id == "wretch" then
        type = "Minion"
    end
    if c.character.unknown then
        extra_unknown = true
        goto continue
    end
    local idx = ArrayUtils:find(roles, type)
    if idx == -1 then
        if ArrayUtils:all(chars, function(ch) return ch.character.type == "Villager" or ch.character.unknown and not ch.hidden_evil end) then
            return false
        end
        return INVALID -- A lying Bishop would must only state Villagers
    end
    table.remove(roles, idx + 1) -- Because Lua is 1-indexed
    ::continue::
end
if extra_unknown then
    if #roles == 1 and ArrayUtils:any(roles, function(r) return r == "Villager" or r == "Outcast" end) then
        return true
    end
    return UNKNOWN
end
return true
