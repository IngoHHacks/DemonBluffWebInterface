'''
LuaBridge.gd
This script provides a bridge between Godot and Lua, allowing Lua scripts to be executed within the Godot environment.
'''

extends Node

const Character = Characters.Character
const CharacterData = Characters.CharacterData
const Village = VillageScene.Village

var _lua : LuaState = null

var lua : LuaState:
    get:
        if _lua == null:
            _lua = LuaState.new()
            _lua.open_libraries()
            _set_globals()
        return _lua

func _set_globals() -> void:
    lua.globals["TRUTH"] = Truthness.TRUTH
    lua.globals["LIE"] = Truthness.LIE
    lua.globals["UNKNOWN"] = Truthness.UNKNOWN
    lua.globals["INVALID"] = Truthness.INVALID
    lua.globals["ArrayUtils"] = ArrayUtils

func set_global(name: String, value: Variant) -> void:
    lua.globals[name] = value

func run_file(path: String, args) -> Variant:
    set_global("args", args)
    if args is Dictionary:
        for key in args.keys():
            set_global(key, args[key])
    var result = lua.do_file(path)
    if result is LuaError:
        var desc = "Error"
        if result.status == LuaError.Status.FILE:
            desc = "Invalid file"
        elif result.status == LuaError.Status.RUNTIME:
            desc = "Runtime error"
        elif result.status == LuaError.Status.SYNTAX:
            desc = "Syntax error"
        elif result.status == LuaError.Status.MEMORY:
            desc = "Memory allocation error"
        elif result.status == LuaError.Status.GC:
            desc = "Garbage collector error"
        elif result.status == LuaError.Status.HANDLER:
            desc = "Error in error handler"
        push_error("Failed to run Lua file '%s': %s: %s" % [path, desc, result.message])
        return null
    if result is LuaTable:
        if result.get(1, null) != null:
            result = result.to_array()
        else:
            result = result.to_dictionary()
    return result

func run_statement_validation_logic(cd: CharacterData, char: Character, village: Village, args) -> int:
    set_global("this", char)
    set_global("village", village)
    var result = run_file("res://Characters/" + cd.id + "_validate.lua", args)
    return result if result != null else Truthness.INVALID
