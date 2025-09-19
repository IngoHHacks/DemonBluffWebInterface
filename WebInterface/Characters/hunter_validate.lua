-- If distance is 0, no character should be Evil
if distance == 0 then
    return ArrayUtils:none(village.characters, function(c) return c:seen_as_evil() and c ~= this end)
end
local check = village:get_adjacent_to(this, distance - 1)
-- If anyone within distance - 1 is Evil, it is a lie
if ArrayUtils:any(check, function(c) return c:seen_as_evil() end) then
    return false
end
-- If anyone exactly at distance is Evil, it is the truth
if ArrayUtils:any(village:get_adjacent_to(this, distance), function(c) return c:seen_as_evil() end) then
    return true
end
-- Otherwise, it is a lie
return false