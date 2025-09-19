if char2 == nil then
    return not char1.assumed_corrupted
end
if char1.maybe_corrupted and char2:seen_as_evil() then
    return UNKNOWN
end
return char1.assumed_corrupted and char2:seen_as_evil()