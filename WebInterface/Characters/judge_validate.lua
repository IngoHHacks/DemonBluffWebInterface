if char.character.unknown then
    return UNKNOWN
end
return char:should_lie() == not truthful