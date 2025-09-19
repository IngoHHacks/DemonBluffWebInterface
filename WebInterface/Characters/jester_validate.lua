local chars = {char1, char2, char3}
return ArrayUtils:count(chars, function(c) return c:seen_as_evil() end) == num_evils