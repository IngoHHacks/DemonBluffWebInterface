if char == nil then
    if village:current_duplicates() > 0 and village:has_character_of_role("shaman") then
        return false -- The character duplicated by Shaman should've been witnessed
    end
    if ArrayUtils:any(village.characters, function(c) return c.affected_by_evil end) then
        return false -- Characters affected by evil should've been witnessed
    end
    if this.reveal_order > 4 and ArrayUtils:any(village.characters, function(c) return c.dead and c.killed_by_demon end) then
        return false -- A character killed by demon should've been witnessed (unless the Witness is revealed before night)
    end
    return true
end
if char.affected_by_evil then
    return true
end
if char.dead and char.killed_by_demon then
    return UNKNOWN -- Killed by demon MAY have been witnessed (depending on reveal order)
end
if char.character.type == "Outcast" and char:adjacent_to_role(village, "counsellor") then
    return UNKNOWN -- May have been created by the Counsellor
end
if village:num_of_role(char.character.id, false) > 1 and village:has_character_of_role("shaman") or ArrayUtils:any(village.characters, function(c) return c.character.unknown and not c.hidden_evil end) then
    return UNKNOWN -- May have been duplicated by the Shaman
end
return false