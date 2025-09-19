if char1 == nil or char2 == nil or role == "none" then
    return village:num_of_type("Minion") == 0 -- Any parameter being nil means the Oracle claims there are no Minions in the village
end
local chars = {char1, char2}
for _, c in ipairs(chars) do
    if c.character.id == role or c.character.id == "wretch" then -- Wretch can appear as any Minion role. A lying Oracle would never point to a Wretch, so we know this must always be true
        return true
    end
end
if ArrayUtils:all(chars, function(c) return c:seen_as_good() end) then
    return false
end
return INVALID -- A lying oracle only states Good characters