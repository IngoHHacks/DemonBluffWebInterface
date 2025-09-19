if char == nil then
    if village:current_duplicates() > 0 and village:has_character_of_role("shaman") then
        return false -- The character duplicated by Shaman should've been witnessed
    end
    return ArrayUtils:none(village.characters, function(c) return c.affected_by_evil end) -- Characters affected by evil should've been witnessed
end
if char.affected_by_evil then
    return true
end
if char.character.type == "Outcast" and char:adjacent_to_role(village, "counsellor") then
    return UNKNOWN -- May have been created by the Counsellor
end
if village:num_of_role(char.character.id, false) > 1 and village:has_character_of_role("shaman") then
    return UNKNOWN -- May have been duplicated by the Shaman
end
return false