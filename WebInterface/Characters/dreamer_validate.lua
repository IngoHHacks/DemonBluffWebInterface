if char.character.id == "wretch" then
    return role == "cabbage" -- Dreamer sees Wretch as Cabbage
end
if not char:seen_as_evil() then
    return UNKNOWN -- Dreamer only gives correct info on Evil characters
end
if char.hidden_evil then
    return UNKNOWN -- Could be correct, but we can't be sure
end
return char.character.id == role