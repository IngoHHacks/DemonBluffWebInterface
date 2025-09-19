if killed then
    return char:seen_as_evil() -- The Slayer should only be able to slay if the target is Evil and they are not corrupted, so this should normally always be true, but just in case
end
if char:seen_as_evil() then
    return false -- Slayer should've been able to slay them if they were Evil
end
return UNKNOWN -- If the target is not Evil, we can't be sure if the Slayer is lying because they couldn't slay them regardless