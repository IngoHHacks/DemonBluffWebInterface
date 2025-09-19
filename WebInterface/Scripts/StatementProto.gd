'''
StatementProto.gd
This script defines a prototype for creating Statement instances with predefined character data and arguments that can be built into full Statement objects.
'''

class_name StatementProto

const Character = Characters.Character
const CharacterData = Characters.CharacterData

var char : CharacterData = null
var args : Array = []

func _init(character: CharacterData, arguments: Array) -> void:
    char = character
    args = arguments.duplicate()

func build(character : Character) -> Statement:
    var stmt = Statement.build(char.id, character)
    for i in range(args.size()):
        stmt.set_arg(i, args[i])
    return stmt
