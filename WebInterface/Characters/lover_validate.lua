local check = village:get_adjacent_to(this)
return ArrayUtils:count(check, function(c) return c:seen_as_evil() end) == num_adjacent_evils