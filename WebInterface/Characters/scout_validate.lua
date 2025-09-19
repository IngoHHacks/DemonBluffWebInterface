-- role == "none" means the Scout claims there is only 1 Evil in the village
if role == "none" then
    return village:get_seen_evil_count() == 1
end
local match = village:get_character_of_role(role)
if match == nil then
    return false -- If no such role exists, it is a lie (though this should never happen in practice)
end
-- If distance is 0, no character should be Evil
if distance == 0 then
    return ArrayUtils:none(village.characters, function(c) return c:seen_as_evil() and c ~= match end)
end
local check = village:get_adjacent_to(match, distance - 1)
-- If anyone within distance - 1 is Evil, it is a lie
if ArrayUtils:any(check, function(c) return c:seen_as_evil() end) then
    return false
end
-- If anyone exactly at distance is Evil, it is the truth
if ArrayUtils:any(village:get_adjacent_to(match, distance), function(c) return c:seen_as_evil() end) then
    return true
end
-- Otherwise, it is a lie
return false