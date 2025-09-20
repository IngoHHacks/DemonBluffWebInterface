extends Node

const START_PUZZLE = "1"
var i = 0
var c = 0
var solve_prog = 0.0

func _ready():
    var fl = Array(DirAccess.open("user://pzl1000").get_files())
    fl = fl.filter(func(file): return file.ends_with(".pzl"))
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
            if sol_str == solution_str.replace("# Solution:\n", ""):
                print("Puzzle " + file + " validated successfully.")
                ok = true
                break
        if not ok:
            push_error("Puzzle " + file + " validation failed.")
            for sol in solutions:
                print("INVALID:\n")
                print(sol.get_string(village))

func _process(_delta: float) -> void:
    $Label.text = "PUZZLE " + str(i) + "/" + str(c) + "\n" + str(int(solve_prog * 1000)/10.0) + "%"
