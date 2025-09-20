-- If the Baker says they were the original Baker, it's always true
if original then
    return true
end
-- If the claimed role is not original, it is false if there is not a Baker revealed before the speaker or if there are too many duplicates with this role
local before = village:get_cards_revealed_before(this)
if village:too_many_duplicates_if(this, role) then
    return false
end
-- If everything is met, we still can't be sure if they spoke the truth if there are multiple Bakers after the first one or if they claim to be a baker
if village:num_of_role("baker", true) > 1 then
    if ArrayUtils:any(before, function(c) return c.character.id == "baker" or (c.character.id == "doppelganger" and c.disguise.id == "baker") end) then
        return UNKNOWN
    end
end
if role == "baker" then
    return UNKNOWN
end
return false
