local chars = {char1, char2, char3}
for _, c in ipairs(chars) do
    if c.character.id == role then
        return true -- Found a match
    end
    if role == "none" and c.character.type == "Outcast" then
        return false -- Found an Outcast when none was claimed
    end
end
return role == "none" -- No Outcast found when none was claimed, or no match found for the claimed Outcast