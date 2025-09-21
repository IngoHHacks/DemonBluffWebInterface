extends Node

const START_PUZZLE = "1"
const SOLVE_ONLY_ONE = false
var i = 0
var c = 0
var solve_prog = 0.0
var good := 0
var bad := 0
var done := false

func _ready():
    var fl = Array(DirAccess.open("user://pzl1000").get_files())
    fl = fl.filter(func(file): return file.ends_with(".pzl"))
    if SOLVE_ONLY_ONE:
        fl = fl.filter(func(file): return file == START_PUZZLE + ".pzl")
    c = fl.size()
    for file in fl:
        i += 1
        if file.substr(0, file.length() - 4) < START_PUZZLE:
            continue
        var puzzle_str = FileAccess.open("user://pzl1000/" + file, FileAccess.READ).get_as_text()
        var solution_str = FileAccess.open("user://pzl1000/" + file.substr(0, file.length() - 4) + ".sol", FileAccess.READ).get_as_text()
        var village = VillageScene.import_village(puzzle_str)
        var solutions = await village.solve(self)
        var ok = false
        for solution in solutions:
            var sol_str = solution.get_string(village)
            if matches(sol_str, solution_str):
                print("Puzzle " + file + " validated successfully.")
                ok = true
                break
        if not ok:
            bad += 1
            push_error("Puzzle " + file + " validation failed.")
        else:
            good += 1
    print("Validation complete: " + str(good) + " correct, " + str(bad) + " incorrect.")
    done = true

func _process(_delta: float) -> void:
    if done:
        $Label.text = "DONE!\n" + str(good) + " correct, " + str(bad) + " incorrect. (" + str(int((good / (good + bad)) * 1000)/10.0) + "%)"
    else:
        $Label.text = "PUZZLE " + str(i) + "/" + str(c) + "\n" + str(int(solve_prog * 1000)/10.0) + "%"

func matches(sol1: String, sol2: String) -> bool:
    var lines1 = Array(sol1.split("\n", false))
    var lines2 = Array(sol2.split("\n", false))
    while lines1.size() > 0 and lines2.size() > 0:
        var l1 : String = lines1.pop_front().strip_edges()
        while l1 == "" or l1.begins_with("#"):
            if lines1.size() == 0:
                break
            l1 = lines1.pop_front().strip_edges()
        var l2 : String = lines2.pop_front().strip_edges()
        while l2 == "" or l2.begins_with("#"):
            if lines2.size() == 0:
                break
            l2 = lines2.pop_front().strip_edges()
        if l1.contains( "#maybe_corrupted"):
            l1 = l1.replace(" #maybe_corrupted", "")
            l2 = l2.replace(" #corrupted", "")
        if l2.contains(" #maybe_corrupted"):
            l2 = l2.replace(" #maybe_corrupted", "")
            l1 = l1.replace(" #corrupted", "")
        if l1 != l2:
            return false
    return lines1.size() == 0 and lines2.size() == 0
