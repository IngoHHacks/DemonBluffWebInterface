local min = village:num_adjacent_meeting_condition(function(c) return c:seen_as_evil() end)
local unknown_wretch = ArrayUtils:none(village.characters, function(c) return c.character.id == "wretch" end) and ArrayUtils:any(village.characters, function(c) return c.character.unknown end) and ArrayUtils:any(village.deck, function(c) return c.id == "wretch" end)
if unknown_wretch then
    if min == num_adjacent_evils or min + 1 == num_adjacent_evils then
        return UNKNOWN
    end
    return false
end
return min == num_adjacent_evils