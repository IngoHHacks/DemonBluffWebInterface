class_name Truthness

# Sometimes, a statement can't simply be true or false
# For example, if the Baker says "I was a Confessor" and they are revealed after another Baker,
# we can't be sure if they are lying or telling the truth
# Additionally, some statements might be invalid due to game rules
# For example, if the Oracle says "#1 or #2 is a Poisoner" and #1 is Evil but not a Poisoner,
# the statement is invalid because it is untrue and a lying Oracle would not say it because
# a lying Oracle would state two Good characters instead

const LIE := 0 # The speaker is lying
const TRUTH := 1 # The speaker is telling the truth
const UNKNOWN := 2 # We can't be sure if the speaker is lying or telling the truth
const INVALID := 3 # The statement is invalid (e.g. contradicts game rules)
