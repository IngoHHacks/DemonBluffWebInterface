local chars = {char1, char2, char3}
local num_evils = ArrayUtils:count(chars, function(c) return c:seen_as_evil() end)
if num_evils == 0 then
    return false -- Lying Empress states all Good
end
if num_evils == 1 then
    return true -- Truthful Empress states exactly one Evil
end
return INVALID -- No Empress would state two or more Evil, regardless of truthfulness