local chars = {char1, char2, char3}
if role == "wretch" then
    return false -- Druid cannot claim Wretch unless Evil
end
for _, c in ipairs(chars) do
    if c.character.id == role then
        return true -- Found a match
    end
    if role == "none" and c.character.type == "Outcast" and not c:seen_as_evil() then -- Wretch is not seen as Outcast
        return false -- Found an Outcast when none was claimed
    end
end
return role == "none" -- No Outcast found when none was claimed, or no match found for the claimed Outcast