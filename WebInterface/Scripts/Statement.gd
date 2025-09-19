class_name Statement

const Character = Characters.Character
const CharacterData = Characters.CharacterData
const Village = VillageScene.Village

var character : CharacterData = null
var speaker : Character = null
var arg_names : Array = []
var args : Array = []

static func build(string: String, character : Character) -> Statement:
    if string.to_lower() == "special_(poet)":
        string = "poet"
    var c = Characters.characters[string]
    var stmt = Statement.new(c)
    stmt.speaker = character
    stmt.arg_names = c.arg_names
    stmt.args = build_defaults(c.parameters)
    return stmt

static func build_defaults(params: Array) -> Array:
    var defaults = []
    for param in params:
        var split = param.split("|")
        var type = split[0]
        if type.begins_with("optional_"):
            type = type.substr("optional_".length(), -1)
        var args = split.slice(1, split.size())
        match type:
            "number", "character":
                defaults.append(0)
            "boolean":
                defaults.append(false)
            _:
                defaults.append("")
    return defaults

func _init(character: CharacterData = null) -> void:
    self.character = character

func copy() -> Statement:
    var stmt = Statement.new(character)
    stmt.speaker = speaker
    stmt.arg_names = arg_names # Names are immutable
    stmt.args = args.duplicate()
    return stmt

func is_true(village : Village) -> int:
    return LuaBridge.run_statement_validation_logic(character, speaker, village, get_args_dict(village))

func get_args() -> Array:
    return args

func get_args_dict(village : Village) -> Dictionary:
    var dict = {}
    for i in range(arg_names.size()):
        if i >= args.size():
            continue
        if arg_names[i].begins_with("role") and args[i] is String:
            dict[arg_names[i]] = args[i].to_lower().replace(" ", "_")
        elif arg_names[i].begins_with("char") and args[i] is int:
            if args[i] == 0:
                dict[arg_names[i]] = null
            else:
                dict[arg_names[i]] = village.characters[args[i] - 1]
        else:
            dict[arg_names[i]] = args[i]
    return dict

func get_string() -> String:
    if character == null:
        return "[Default Statement]"
    var stmt = character.statement
    for pair in stmt:
        var cond = pair[0].split(" ")
        if cond.size() == 3:
            var left = cond[0]
            var cmp = cond[1]
            var right = cond[2]
            if not compare(left, cmp, right):
                continue
        return replace_vars(pair[1])
    return "[No Valid Statement]"

func set_arg(index: int, value) -> void:
    if index >= 0 and index < args.size():
        args[index] = TypeUtils.cast_to_type_of(args[index], value)

func compare(left, cmp: String, right) -> bool:
    var mode = "string" if cmp in ["==", "!="] else "int"
    if left.begins_with("$"):
        var var_name = left.substr(1, -1)
        left = str(get_args()[int(var_name) - 1])
    if left.is_valid_int():
        left = int(left)
        mode = "int"
    elif left.is_valid_float():
        left = float(left)
        mode = "float"
    elif left.begins_with("'") and left.ends_with("'"):
        left = left.substr(1, left.length() - 2)
    if right.begins_with("$"):
        var var_name = right.substr(1, -1)
        right = str(get_args()[int(var_name) - 1])
    if right.is_valid_int():
        right = int(right)
        if mode != "float":
            mode = "int"
    elif right.is_valid_float():
        right = float(right)
        mode = "float"
    elif right.begins_with("'") and right.ends_with("'"):
        right = right.substr(1, right.length() - 2)
    if mode == "int":
        left = int(left)
        right = int(right)
    elif mode == "float":
        left = float(left)
        right = float(right)
    else:
        left = str(left).to_lower()
        right = str(right).to_lower()
    match cmp:
        "==":
            return left == right
        "!=":
            return left != right
        ">":
            return left > right
        "<":
            return left < right
        ">=":
            return left >= right
        "<=":
            return left <= right
    return false

func replace_vars(text: String) -> String:
    var result = text
    var args = get_args()
    for i in range(args.size()):
        var value = str(args[i])
        if value == "true":
            value = "True"
        elif value == "false":
            value = "False"
        if value != "":
            result = result.replace("$" + str(i + 1), value)
            var article = "an" if value[0].to_lower() in ["a", "e", "i", "o", "u"] else "a"
            result = result.replace("@" + str(i + 1), article + " " + value)
    return result
