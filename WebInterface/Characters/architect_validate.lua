local left = village:get_left_side()
local right = village:get_right_side()
local left_evil = ArrayUtils:count(left, function(c) return c:seen_as_evil() end)
local right_evil = ArrayUtils:count(right, function(c) return c:seen_as_evil() end)
if side == "Left" then
    return left_evil > right_evil
elseif side == "Right" then
    return right_evil > left_evil
else
    return left_evil == right_evil
end