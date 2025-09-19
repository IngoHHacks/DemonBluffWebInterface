-- If distance is 0, no character should be Corrupted
if distance == 0 then
    return ArrayUtils:none(village.characters, function(c) return c.assumed_corrupted and c ~= this end)
end
local check = village:get_adjacent_to(this, distance - 1)
local maybe_false = false
local maybe_true = false
-- If anyone within distance - 1 is Corrupted, it is a lie
if ArrayUtils:any(check, function(c) return c.assumed_corrupted end) then
    return false
end
if ArrayUtils:any(check, function(c) return c.maybe_corrupted end) then
    maybe_false = true
end
-- If anyone exactly at distance is Corrupted, it is the truth (or UNKNOWN if there were maybe_corrupted in the check before)
if ArrayUtils:any(village:get_adjacent_to(this, distance), function(c) return c.assumed_corrupted end) then
    if maybe_false then
        return UNKNOWN
    end
    return true
end
if ArrayUtils:any(village:get_adjacent_to(this, distance), function(c) return c.maybe_corrupted end) then
    maybe_true = true
end
-- Otherwise, it is a lie (or UNKNOWN if there were maybe_corrupted in the check before)
if maybe_true then
    return UNKNOWN
end
return false