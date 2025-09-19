local ccw = village:distance_to_counter_clockwise(this, function(c) return c:seen_as_evil() end)
local cw = village:distance_to_clockwise(this, function(c) return c:seen_as_evil() end)
if direction == "Clockwise" then
    return cw < ccw
elseif direction == "Counter-clockwise" then
    return ccw < cw
end
return ccw == cw