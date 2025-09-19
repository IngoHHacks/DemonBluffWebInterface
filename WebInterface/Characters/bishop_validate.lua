local chars = {}
local roles = {}

if char3 == nil then
    chars = {char1, char2}
    roles = {"Villager", evil}
else
    chars = {char1, char2, char3}
    roles = {"Villager", "Outcast", evil}
end
for _, c in ipairs(chars) do
    local type = c.character.type
    if c.character.id == "wretch" then
        type = "Minion"
    end
    local idx = ArrayUtils:find(roles, type)
    if idx == -1 then
        if ArrayUtils:all(chars, function(ch) return ch.character.type == "Villager" end) then
            return false
        end
        return INVALID -- A lying Bishop would must only state Villagers
    end
    table.remove(roles, idx + 1) -- Because Lua is 1-indexed
end
return true
