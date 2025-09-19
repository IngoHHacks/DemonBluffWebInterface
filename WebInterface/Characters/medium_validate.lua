if char.character.unknown then
    return not char.hidden_evil -- It is assumed that Medium always gives the correct role for Good characters
end
return char.character.id == role or char.character.id == "baker"
