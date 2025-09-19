extends Control

class_name VillageScene

const Character = Characters.Character
const CharacterData = Characters.CharacterData

@export var card_template : PackedScene
@export var card_holder : PackedScene

class SolutionEntry:
    var actual_role : CharacterData = null # null if same as assigned role
    var corrupted := false

    func _init(actual_role: CharacterData = null, corrupted := false):
        self.actual_role = actual_role
        self.corrupted = corrupted

class Village:
    var cards : Array[Node] = []
    var characters : Array[Character] = []
    var deck : Array[CharacterData] = []
    var num_characters : int = 0
    var num_revealed : int = 0
    var num_villagers : int = 0
    var num_outcasts : int = 0
    var num_minions : int = 1
    var num_demons : int = 0

    func _init(num_characters: int = 0):
        self.num_characters = num_characters

    func duplicate() -> Village:
        var v = Village.new(num_characters)
        v.num_villagers = num_villagers
        v.num_outcasts = num_outcasts
        v.num_minions = num_minions
        v.num_demons = num_demons
        for char in characters:
            v.characters.append(char.duplicate())
        v.num_revealed = num_revealed
        # Deck doesn't need to be copied because it's irrelevant to solving
        return v
        
    func next_reveal_order() -> int:
        num_revealed += 1
        return num_revealed

    func unreveal_character(char: Character) -> void:
        if char.reveal_order > 0:
            num_revealed -= 1
            for c in characters:
                if c.reveal_order > char.reveal_order and not c == char:
                    c.reveal_order -= 1
            char.reveal_order = 0

    func move_reveal_later(char: Character) -> void:
        if char.reveal_order < num_revealed:
            for c in characters:
                if c.reveal_order == char.reveal_order + 1:
                    c.reveal_order -= 1
            char.reveal_order += 1

    func move_reveal_earlier(char: Character) -> void:
        if char.reveal_order > 1:
            for c in characters:
                if c.reveal_order == char.reveal_order - 1:
                    c.reveal_order += 1
            char.reveal_order -= 1

    func get_adjacent_to(char : Character, distance := 1) -> Array[Character]:
        var index = char.id - 1
        if index == -1 or distance < 1:
            return []
        var adjacent : Array[Character] = []
        for i in range(index - distance, index + distance + 1):
            i = fmod(i, num_characters)
            if i != index:
                adjacent.append(characters[i])
        return adjacent

    func get_left_side() -> Array[Character]:
        var half = ceili(num_characters / 2.0 - 0.000001) - 1
        var left : Array[Character] = []
        for i in range(half, num_characters):
            left.append(characters[i])
        return left

    func get_right_side() -> Array[Character]:
        var half = floori(num_characters / 2.0 + 0.000001) - 1
        var right : Array[Character] = []
        for i in range(0, half + 1):
            right.append(characters[i])
        right.append(characters[num_characters - 1]) # Top card is part of both sides
        return right

    func get_cards_revealed_before(char: Character) -> Array[Character]:
        var revealed : Array[Character] = []
        for c in characters:
            if c.reveal_order > 0 and c.reveal_order < char.reveal_order:
                revealed.append(c)
        return revealed

    func get_cards_revealed_after(char: Character) -> Array[Character]:
        var revealed : Array[Character] = []
        for c in characters:
            if c.reveal_order > char.reveal_order:
                revealed.append(c)
        return revealed

    func get_seen_evil_count(ignore_dead := false) -> int:
        var count = 0
        for c in characters:
            if c.character.seen_alignment == "Evil" and (not ignore_dead or not c.dead):
                count += 1
        return count

    func get_actual_evil_count(ignore_dead := false) -> int:
        var count = 0
        for c in characters:
            if c.character.alignment == "Evil" and (not ignore_dead or not c.dead):	
                count += 1
        return count

    func get_deck_evil_count() -> int:
        var count = 0
        for c in deck:
            if c.alignment == "Evil":
                count += 1
        return count

    func filter_characters(condition) -> Array[Character]:
        if condition is LuaFunction:
            condition = condition.to_callable()
        var result : Array[Character] = []
        for char in characters:
            if condition.call(char):
                result.append(char)
        return result

    func num_of_type(type: String) -> int:
        return characters.reduce(func(acc: int, char: Character):
            if not char.character.unknown and (char.character.type == type and not char.character.id == "puppet") or (char.character.id == "puppet" and type == "Villager"): # Puppet counts as Villager for this purpose
                return acc + 1
            return acc
        , 0)

    func num_of_role(role: String, include_doppels := false) -> int:
        return characters.reduce(func(acc: int, char: Character):
            if not char.character.unknown and (char.character.id == role or (include_doppels and char.character.id == "doppelganger" and char.disguise != null and char.disguise.id == role)):
                return acc + 1
            return acc
        , 0)

    func num_hidden_goods() -> int:
        return characters.reduce(func(acc: int, char: Character):
            if char.character.unknown and not char.hidden_evil:
                return acc + 1
            return acc
        , 0)

    func num_hidden_evils() -> int:
        return characters.reduce(func(acc: int, char: Character):
            if char.character.unknown and char.hidden_evil:
                return acc + 1
            return acc
        , 0)

    func max_allowed_duplicates():
        return characters.reduce(func(acc: int, char: Character):
            if char.character.id == "shaman":
                return acc + 1
            return acc
        , 0)

    func current_duplicates() -> int:
        var seen = []
        for char in characters:
            if char.character.unknown or char.character.id == "baker": # Always allowed
                seen.append(null)
            elif not seen.has(char.character.id):
                seen.append(char.character.id)
        return characters.size() - seen.size()

    func too_many_duplicates_if(char: Character, role: String) -> bool:
        if current_duplicates() < max_allowed_duplicates():
            return false
        if characters.any(func(c):
            return c != char and c.character.id == role and role != "baker"
        ):
            return true
        return false

    func has_duplicate_outcasts() -> bool:
        var seen = []
        for char in characters:
            if char.character != null and char.character.type == "Outcast":
                if seen.has(char.character.id):
                    return true
                seen.append(char.character.id)
        return false

    func has_duplicate_evils() -> bool:
        var seen = []
        for char in characters:
            if char.character != null and char.character.alignment == "Evil" and not char.character.unknown:
                if seen.has(char.character.id):
                    return true
                seen.append(char.character.id)
        return false

    func distance_to_counter_clockwise(from_char: Character, condition) -> int:
        if condition is LuaFunction:
            condition = condition.to_callable()
        var index = from_char.id - 1
        if index == -1:
            return -1
        var distance = 0
        for i in range(1, num_characters):
            distance += 1
            var c = characters[fmod(index - i + num_characters, num_characters)]
            if condition.call(c):
                return distance
        return -1

    func distance_to_clockwise(from_char: Character, condition) -> int:
        if condition is LuaFunction:
            condition = condition.to_callable()
        var index = from_char.id - 1
        if index == -1:
            return -1
        var distance = 0
        for i in range(1, num_characters):
            distance += 1
            var c = characters[fmod(index + i, num_characters)]
            if condition.call(c):
                return distance
        return -1

    func get_characters_of_role(role: String) -> Array[Character]:
        var chars : Array[Character] = []
        for c in characters:
            if c.character.id == role or (c.character.id == "doppelganger" and c.disguise != null and c.disguise.id == role):
                chars.append(c)
        return chars
        
    func get_character_of_role(role: String) -> Character:
        for c in characters:
            if c.character.id == role or (c.character.id == "doppelganger" and c.disguise != null and c.disguise.id == role):
                 return c
        return null

    func has_character_of_role(role: String) -> bool:
        for c in characters:
            if c.character.id == role:
                return true
        return false

    func num_adjacent_meeting_condition(condition):
        if condition is LuaFunction:
            condition = condition.to_callable()
        var count = 0
        var _cache_skip = false
        for i in range(num_characters):
            if _cache_skip:
                _cache_skip = false
                continue
            if condition.call(characters[i]):
                if condition.call(characters[fmod(i + 1, num_characters)]):
                    count += 1
                else:
                    _cache_skip = true # Skip next because we already know it doesn't meet the condition
        return count


    func solve(scene) -> Array:
        var last_update = Time.get_ticks_msec()
        var solutions : Array = []
        var solver_village = self.duplicate()
        var unknown_disguised = deck.filter(func(c : CharacterData):
            return c.disguise != "None" and not characters.any(func(ch : Character):
                return ch.character.id == c.id and ch.disguise != null
            )
        )
        if characters.any(func(c : Character):
            return c.character.unknown
        ) and deck.any(func(c : CharacterData):
            return c.id == "plague_doctor"
        ) and not characters.any(func(c : Character):
            return c.character.id == "plague_doctor"
        ):
            unknown_disguised.append(Characters.characters["plague_doctor"])
        var undisguised_villagers := characters.filter(func(c : Character):
            return c.disguise == null and c.character.can_be_used_as_disguise and not c.never_disguised
        ).map(func(c : Character):
            return c.id
        )
        var max_disguised = unknown_disguised.size()
        var min_disguised = get_deck_evil_count() - get_actual_evil_count()
        var extra : Array[int] = []
        undisguised_villagers.resize(undisguised_villagers.size() + max_disguised - min_disguised)
        var iters = ArrayUtils.unique(ArrayUtils.permutations(undisguised_villagers, max_disguised))
        if iters == []:
            iters = [[]]
        for i in range(iters.size()):
            # Allow UI to update
            # This used to be a thread, but web is iffy with threads (Lua extension breaks if threads are enabled for the web export, plus cross-origin isolation being necessary for threads to work at all)
            # Works pretty well though, if a bit less responsive than a thread
            if Time.get_ticks_msec() - last_update > 10:
                last_update = Time.get_ticks_msec()
                scene.solve_prog = i / float(iters.size())
                await scene.get_tree().process_frame
            var iter : Array = iters[i]
            var invalid_disguise = false
            for j in range(num_characters):
                if iter.has(j + 1):
                    if characters[j].never_disguised or (characters[j].hidden_evil and not unknown_disguised[iter.find(j + 1)].alignment == "Evil") or (characters[j].dead and unknown_disguised[iter.find(j + 1)].alignment == "Evil" and not characters[j].hidden_evil) or not Characters.valid_disguise_for(unknown_disguised[iter.find(j + 1)], characters[j].character):
                        invalid_disguise = true
                        break
                    solver_village.characters[j].disguise = characters[j].character
                    solver_village.characters[j].character = unknown_disguised[iter.find(j + 1)]
                else:
                    solver_village.characters[j].character = characters[j].character
                    solver_village.characters[j].disguise = characters[j].disguise
            if invalid_disguise:
                scene.solve_prog = (i+1) / float(iters.size())
                continue
            if not _solve_is_valid_early(solver_village):
                scene.solve_prog = (i+1) / float(iters.size())
                continue
            for state in _solve_corruption_states(solver_village):
                if _solve_is_valid_late(state):
                    var sol = state.characters.map(func(c : Character):
                        return SolutionEntry.new(c._character if c.character != characters[c.id - 1].character else null, c.assumed_corrupted or (c.maybe_corrupted and c.character.unknown)
                    ))
                    solutions.append(sol)
            scene.solve_prog = (i+1) / float(iters.size())
        return solutions

    func _solve_is_valid_early(village: Village) -> bool:
        # Rule 1: The number of Villagers, Outcasts, Minions, and Demons must match the selected numbers.
        var hidden_goods = village.num_hidden_goods()
        var hidden_evils = village.num_hidden_evils()
        var villagers = village.num_of_type("Villager")
        var outcasts = village.num_of_type("Outcast")
        var minions = village.num_of_type("Minion")
        var demons = village.num_of_type("Demon")
        if village.num_of_role("counsellor") > 0 and village.num_villagers > 0: # Counsellor converts a Villager to an Outcast
            villagers += 1
            outcasts -= 1
        var good_excess = 0
        if villagers < village.num_villagers:
            good_excess += village.num_villagers - villagers
        elif villagers > village.num_villagers:
            return false
        if outcasts < village.num_outcasts:
            good_excess += village.num_outcasts - outcasts
        elif outcasts > village.num_outcasts:
            return false
        if good_excess != hidden_goods:
            return false
        var evil_excess = 0
        if minions < village.num_minions:
            evil_excess += village.num_minions - minions
        elif minions > village.num_minions:
            return false
        if demons < village.num_demons:
            evil_excess += village.num_demons - demons
        elif demons > village.num_demons:
            return false
        if evil_excess != hidden_evils:
            return false
        # Rule 2: No duplicate characters, unless allowed (e.g. Shaman).
        if village.current_duplicates() > village.max_allowed_duplicates():
            return false
        # Rule 3: No duplicate Evils or Outcasts.
        if village.has_duplicate_evils() or village.has_duplicate_outcasts():
            return false
        for char in village.characters:
            if char.hidden_evil and char.disguise == null:
                return false
        return true

    
    func _solve_is_valid_late(village: Village) -> bool:
        # Rule 4: All character-specific rules must be satisfied.
        # Rule 5: Characters' statements must be in accordance with their alignment (e.g. Uncorrupted Good characters always speak truthfully, Evil or Corrupted characters always lie).
        for char in village.characters:
            if not char.character.unknown:
                if not char.is_statement_valid(village):
                    return false
                if not char.is_character_valid(village):
                    return false
        return true

    func _solve_corruption_states(village: Village) -> Array[Village]:
        for char in village.characters:
            char.assumed_corrupted = false
            char.assumed_corrupted_by = null
            char.assumed_cured = false
            char.assumed_cured_by = null
            char.affected_by_evil = false
            char.num_cured = 0
            char.num_maybe_cured = 0
        var states : Array[Village] = [village.duplicate()]
        var pookas = village.get_characters_of_role("pooka")
        if pookas.size() > 0:
            var pooka = states[0].characters[pookas[0].id - 1]
            var adj = states[0].get_adjacent_to(pooka).filter(func(c : Character):
                return c.character.hidden and not c.hidden_evil or c.character.corruption == "Allowed" and c.character.type == "Villager"
            )
            for ac in adj:
                if ac.character.hidden and not ac.hidden_evil:
                    ac.maybe_corrupted = true
                    ac.maybe_corrupted_by = pooka
                    ac.maybe_affected_by_evil = true
                else:
                    ac.assumed_corrupted = true
                    ac.assumed_corrupted_by = pooka
                    ac.affected_by_evil = true
        var poisoners = village.get_characters_of_role("poisoner")
        if poisoners.size() > 0:
            var poisoner = states[0].characters[poisoners[0].id - 1]
            var adj = states[0].get_adjacent_to(poisoner).filter(func(c : Character):
                return c.character.hidden and not c.hidden_evil or c.character.corruption == "Allowed" and c.character.type == "Villager"
            )
            if adj.size() == 2:
                states = [states[0].duplicate(), states[0].duplicate()]
                if adj[0].character.hidden and not adj[0].hidden_evil:
                    states[0].characters[adj[0].id - 1].maybe_corrupted = true
                    states[0].characters[adj[0].id - 1].maybe_corrupted_by = poisoner
                    states[0].characters[adj[0].id - 1].maybe_affected_by_evil = true
                else:
                    states[0].characters[adj[0].id - 1].assumed_corrupted = true
                    states[0].characters[adj[0].id - 1].assumed_corrupted_by = poisoner
                    states[0].characters[adj[0].id - 1].affected_by_evil = true
                if adj[1].character.hidden and not adj[1].hidden_evil:
                    states[1].characters[adj[1].id - 1].maybe_corrupted = true
                    states[1].characters[adj[1].id - 1].maybe_corrupted_by = poisoner
                    states[1].characters[adj[1].id - 1].maybe_affected_by_evil = true
                else:
                    states[1].characters[adj[1].id - 1].assumed_corrupted = true
                    states[1].characters[adj[1].id - 1].assumed_corrupted_by = poisoner
                    states[1].characters[adj[1].id - 1].affected_by_evil = true
            else:
                for ac in adj:
                    if ac.character.hidden and not ac.hidden_evil:
                        ac.maybe_corrupted = true
                        ac.maybe_corrupted_by = poisoner
                        ac.maybe_affected_by_evil = true
                    else:
                        ac.assumed_corrupted = true
                        ac.assumed_corrupted_by = poisoner
                        ac.affected_by_evil = true
        var plague_doctors = village.get_characters_of_role("plague_doctor")
        if plague_doctors.size() > 0:
            var plague_doctor = plague_doctors[0]
            var new_states : Array[Village] = []
            for state in states:
                plague_doctor = state.characters[plague_doctor.id - 1]
                for i in range(village.num_characters):
                    if i + 1 == plague_doctor.id:
                        continue
                    var c = state.characters[i]
                    if c.character.hidden and not c.hidden_evil or c.character.corruption == "Allowed" and c.character.type == "Villager":
                        var new_state = state.duplicate()
                        if c.character.hidden and not c.hidden_evil:
                            new_state.characters[i].maybe_corrupted = true
                            new_state.characters[i].maybe_corrupted_by = plague_doctor
                        else:
                            new_state.characters[i].assumed_corrupted = true
                            new_state.characters[i].assumed_corrupted_by = plague_doctor

                        new_states.append(new_state)
            states = new_states
        var alchemists = village.get_characters_of_role("alchemist")
        alchemists.reverse() # Cure happens in counter-clockwise order starting from the topmost character
        if alchemists.size() > 0:
            for state in states:
                for alch in alchemists:
                    alch = state.characters[alch.id - 1]
                    if alch.assumed_corrupted:
                        continue # Corrupted Alchemist can't cure
                    var adj = state.get_adjacent_to(alch, 2).filter(func(c : Character):
                        return c.assumed_corrupted == true or c.maybe_corrupted == true
                    )
                    for ac in adj:
                        if ac.maybe_corrupted:
                            alch.num_maybe_cured += 1
                            ac.maybe_cured = true
                            ac.maybe_corrupted = false
                            ac.maybe_corrupted_by = null
                        else:
                            alch.num_cured += 1
                            ac.assumed_cured = true
                            ac.assumed_cured_by = alch
                            ac.assumed_corrupted = false
        var puppets = village.get_characters_of_role("puppet")
        if puppets.size() > 0:
            var p = puppets[0]
            p.affected_by_evil = true

        for state in states:
            for c in state.characters:
                if c.character.corruption == "Always":
                    c.corrupted = true
                    c.assumed_corrupted = true

        # Remove any states where a character is corrupted but not assumed corrupted
        states = states.filter(func(v : Village):
            for c in v.characters:
                if c.corrupted and not (c.assumed_corrupted or c.maybe_corrupted):
                    return false
                if (c.never_corrupted or (c.dead and not c.character.unknown)) and (not c.corrupted and (c.assumed_corrupted or c.maybe_corrupted)):
                    return false # Dead characters must be labeled corrupted if they really are and never_corrupted characters can't be corrupted
            return true
        )

        return states



var village : Village = Village.new()
var err_time := 0.0
var import_err_time := 0.0
var copied_time := 0.0
var solve_prog := 0.0

func _ready():
    init_village(10)

func _process(delta):
    handle_inputs()
    if err_time > 0.0:
        $Err.visible = true
        $Err.modulate.a = min(1.0, err_time * 2.0)
        err_time -= delta
        if err_time <= 0.0:
            err_time = 0.0
    else:
        $Err.visible = false
    if import_err_time > 0.0:
        $Dummy/ImportDisp/Panel/Err.visible = true
        $Dummy/ImportDisp/Panel/Err.modulate.a = min(1.0, import_err_time * 2.0)
        import_err_time -= delta
        if import_err_time <= 0.0:
            import_err_time = 0.0
    else:
        $Dummy/ImportDisp/Panel/Err.visible = false
    if copied_time > 0.0:
        $Dummy/ExportDisp/Panel/CopiedLabel.visible = true
        $Dummy/ExportDisp/Panel/CopiedLabel.modulate.a = min(1.0, copied_time)
        copied_time -= delta
        if copied_time <= 0.0:
            copied_time = 0.0
    else:
        $Dummy/ExportDisp/Panel/CopiedLabel.visible = false
    if $Dummy/SolveOverlay.visible:
        var ellipsis = ""
        if int(Time.get_ticks_msec() / 250) % 4 == 1:
            ellipsis = "."
        elif int(Time.get_ticks_msec() / 250) % 4 == 2:
            ellipsis = ".."
        elif int(Time.get_ticks_msec() / 250) % 4 == 3:
            ellipsis = "..."
        $Dummy/SolveOverlay/Label.text = "Solving" + ellipsis + "\n" + str(int(solve_prog * 1000)/10.0) + "%"
        $Dummy/SolveOverlay/ProgressTex.material.set_shader_parameter("fill_ratio", solve_prog)

func handle_inputs() -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        hide_solution()
    var card = closest_card()
    if Input.is_action_just_pressed("fullscreen"):
        _on_fullscreen_pressed()
    if card != null:
        if Input.is_action_just_pressed("delete"):
            card.set_character(null)
            card.unreveal()
        if Input.is_action_just_pressed("kill"):
            card._on_dead_pressed()
        for i in range(10):
            if Input.is_action_just_pressed("mark" + str(i)):
                card.set_template_marker(i)

func _on_num_characters_set_pressed() -> void:
    var count = $Dummy/VillageConfig/Ver/Hor1/NumCharacters.value
    init_village(count)

func init_village(card_count: int) -> void:
    for card in $Cards.get_children():
        card.queue_free()
    village = Village.new(card_count)
    village.num_characters = card_count
    var cards = make_cards(card_count, village)
    for card in cards:
        village.characters.append(card.data)
    $Dummy/VillageConfig/Ver/Hor2/Vils.max_value = card_count - 1
    $Dummy/VillageConfig/Ver/Hor2/Vils.value = card_count - 1
    $Dummy/VillageConfig/Ver/Hor2/Outs.max_value = card_count - 1
    $Dummy/VillageConfig/Ver/Hor2/Outs.value = 0
    $Dummy/VillageConfig/Ver/Hor2/Mins.max_value = card_count - 1
    $Dummy/VillageConfig/Ver/Hor2/Mins.value = 1
    $Dummy/VillageConfig/Ver/Hor2/Dems.max_value = card_count - 1
    $Dummy/VillageConfig/Ver/Hor2/Dems.value = 0
    village.num_villagers = card_count - 1
    clear_deck()

func commit_village(village : Village, deck : Array[CharacterData]):
    hide_solution()
    for card in self.village.cards:
        card.queue_free()
    self.village = village
    var cards = make_cards(village.num_characters, village)
    for card in cards:
        card._process(0)
        card.data = village.characters[card.id - 1]
        card.set_character(card.data.character)
        if card.data.disguise != null:
            card.set_disguise(card.data.disguise)
        if card.data.reveal_order > 0:
            card.reveal(true)
        if card.data.statement != null:
            card.set_statement(card.data.statement)
    clear_deck()
    _silent = true
    $Dummy/VillageConfig/Ver/Hor2/Vils.max_value = village.num_characters - 1
    $Dummy/VillageConfig/Ver/Hor2/Outs.max_value = village.num_characters - 1
    $Dummy/VillageConfig/Ver/Hor2/Mins.max_value = village.num_characters - 1
    $Dummy/VillageConfig/Ver/Hor2/Dems.max_value = village.num_characters - 1
    update_count_spinners()
    _silent = false
    for char in deck:
        add_to_deck(char)
    village.deck = deck.duplicate()

func make_cards(card_count: int, village : Village) -> Array[Node]:
    var scale = 0.15
    if card_count > 8:
        scale = 0.15 * (8.0 / card_count)
    var cards : Array[Node] = []
    for i in card_count:
        var card = card_template.instantiate()
        village.cards.append(card)
        card.id = i + 1
        card.village = village
        card.vscene = self
        $Cards.add_child(card)
        card.scale = Vector2(scale, scale)
        card.get_node("CardEdit/Change").pressed.connect(_on_card_clicked.bind(card))
        card.get_node("CardEdit/Speech").pressed.connect(_on_set_statement_clicked.bind(card))
        card.get_node("CardEdit/Disguise").pressed.connect(_on_disguise_clicked.bind(card))
        card.get_node("CardEdit/Marker").pressed.connect(_on_marker_clicked.bind(card))
        card.data = Character.new(i + 1)
        cards.append(card)
    return cards

func hide_solution() -> void:
    $Dummy/SolHideHint.visible = false
    for card in village.cards:
        card.hide_solution()

var current_closest_card : Node = null

func closest_card() -> Node:
    if $Dummy/CardPicker.visible or $Dummy/StatementEditor.visible or $Dummy/SolveOverlay.visible or $Dummy/ImportDisp.visible or $Dummy/ExportDisp.visible or $Dummy/MarkerEditor.visible:
        return null
    var mouse_pos = get_viewport().get_mouse_position()
    var closest_card = null
    var scale = 1
    if village != null && village.num_characters > 8:
        scale = 1 * (8.0 / village.num_characters)
    var closest_dist = 125 * scale # Ignore cards further than this
    if current_closest_card != null and current_closest_card.get_global_position().distance_to(mouse_pos) < 125 * scale:
        return current_closest_card
    for card in village.cards:
        var dist = card.get_global_position().distance_to(mouse_pos)
        if dist < closest_dist:
            closest_dist = dist
            closest_card = card
    current_closest_card = closest_card
    return closest_card

var selected_card : Node = null
var select_mode := 0

func _on_card_clicked(card: Node) -> void:
    selected_card = card
    select_mode = 0
    $Dummy/CardPicker.set_filter(null)
    $Dummy/CardPicker.set_clear_enabled(true)
    $Dummy/CardPicker.visible = true
    
func _on_set_statement_clicked(card: Node) -> void:
    selected_card = card
    $Dummy/StatementEditor.visible = true
    $Dummy/StatementEditor.init(village, card)
    
func _on_disguise_clicked(card: Node) -> void:
    selected_card = card
    select_mode = 1
    $Dummy/CardPicker.set_filter(card.data.character.disguise)
    $Dummy/CardPicker.set_clear_enabled(true)
    $Dummy/CardPicker.visible = true

func _on_marker_clicked(card: Node) -> void:
    $Dummy/MarkerEditor.set_card_ref(card)
    $Dummy/MarkerEditor.visible = true

func _on_card_picker_card_selected(character: CharacterData, include_disguise := false) -> void:
    hide_solution()
    if select_mode == 2:
        add_to_deck(character)
        village.deck.append(character)
        return
    if selected_card != null:
        if select_mode == 0:
            var old = selected_card.data.character
            selected_card.set_character(character)
            if include_disguise and Characters.valid_disguise_for(character, old) and not old.unknown:
                selected_card.set_disguise(old)
        else:
            selected_card.set_disguise(character)
        if not village.deck.has(character):
            add_to_deck(character)
            village.deck.append(character)
        selected_card.reveal()

func add_to_deck(character: CharacterData) -> void:
    hide_solution()
    var ci = card_holder.instantiate()
    ci.get_node("Card").scale = Vector2(0.1, 0.1)
    ci.custom_minimum_size *= 0.5
    ci.get_node("Card").position -= ci.custom_minimum_size * 0.5
    $Dummy/VillageConfig/Ver/ScrollContainer/Deck.add_child(ci)
    ci.get_node("Card").set_character(character)
    ci.get_node("Card").reveal()
    ci.get_node("Card").get_node("Clickable").pressed.connect(_on_remove_deck_card_pressed.bind(ci.get_node("Card")))
    var sorted = $Dummy/VillageConfig/Ver/ScrollContainer/Deck.get_children()
    sorted.sort_custom(Characters._card_order)
    for c in sorted:
        $Dummy/VillageConfig/Ver/ScrollContainer/Deck.move_child(c, $Dummy/VillageConfig/Ver/ScrollContainer/Deck.get_child_count() - 1)

func _on_remove_deck_card_pressed(card: Node) -> void:
    hide_solution()
    if village != null:
        for card2 in village.cards:
            if card.data.character == card2.data.character or card.data.character == card2.data.disguise:
                card.blink()
                card2.blink()
                return # Can't remove a card that's in the village
    village.deck.erase(card.data.character)
    card.get_parent().queue_free()
    
func _on_card_picker_card_cleared() -> void:
    hide_solution()
    selected_card.unreveal()
    if select_mode == 2:
        return
    if select_mode == 0:
        selected_card.set_character(null)
        selected_card.set_disguise(null)
    else:
        selected_card.set_disguise(null)
         
    
func _on_statement_editor_done() -> void:
    hide_solution()
    if selected_card != null:
        selected_card.set_statement($Dummy/StatementEditor.get_statement())
    
func _on_statement_editor_clear() -> void:
    hide_solution()
    if selected_card != null:
        selected_card.set_statement(null)

func _on_fullscreen_pressed() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_add_pressed() -> void:
    select_mode = 2
    $Dummy/CardPicker.visible = true
    $Dummy/CardPicker.set_filter(null, village.deck)
    $Dummy/CardPicker.set_clear_enabled(false)
    
func _on_clear_unused_pressed() -> void:
    hide_solution()
    for card in $Dummy/VillageConfig/Ver/ScrollContainer/Deck.get_children():
        var c = card.get_node("Card")
        var found = false
        for vcard in village.cards:
            if c.data.character == vcard.data.character or c.data.character == vcard.data.disguise:
                found = true
                break
        if not found:
            card.queue_free()
            village.deck.erase(c.data.character)
            
                
func clear_deck() -> void:
    hide_solution()
    for card in $Dummy/VillageConfig/Ver/ScrollContainer/Deck.get_children():
        var c = card.get_node("Card")
        card.queue_free()
        village.deck.erase(c.data.character)
        
var _silent = false # Unfortunately, set_value_no_signal doesn't update the spinbox arrow button states correctly, so we need to manually prevent recursion

func _on_vils_value_changed(value: float) -> void:
    hide_solution()
    if _silent:
        return
    village.num_villagers = int(value)
    var delta = update_counts("Villagers")
    if delta > 0:
        village.num_villagers -= delta # Shouldn't happen, but just in case
    _silent = true
    update_count_spinners()
    _silent = false
            

func _on_outs_value_changed(value: float) -> void:
    hide_solution()
    if _silent:
        return
    village.num_outcasts = int(value)
    var delta = update_counts("Outcasts")
    if delta > 0:
        village.num_outcasts -= delta # Shouldn't happen, but just in case
    _silent = true
    update_count_spinners()
    _silent = false

func _on_mins_value_changed(value: float) -> void:
    hide_solution()
    if _silent:
        return
    village.num_minions = int(value)
    var delta = update_counts("Minions")
    if delta > 0:
        village.num_minions -= delta # Shouldn't happen, but just in case
    _silent = true
    update_count_spinners()
    _silent = false

func _on_dems_value_changed(value: float) -> void:
    hide_solution()
    if _silent:
        return
    village.num_demons = int(value)
    var delta = update_counts("Demons")
    if delta > 0:
        village.num_demons -= delta # Shouldn't happen, but just in case
    _silent = true
    update_count_spinners()
    _silent = false

func update_counts(from : String) -> int:
    var sum = village.num_villagers + village.num_outcasts + village.num_minions + village.num_demons
    var demon_count = village.num_minions + village.num_demons
    var actual_demon_count = village.get_actual_evil_count(true)
    if demon_count < max(1, actual_demon_count):
        if from != "Villagers" and village.num_villagers > 0:
            village.num_villagers -= 1
            if from != "Minions":
                village.num_minions = 1
            else:
                village.num_demons = 1
        elif from != "Outcasts" and village.num_outcasts > 0:
            village.num_outcasts -= 1
            if from != "Minions":
                village.num_minions = 1
            else:
                village.num_demons = 1
        elif village.num_villagers > 0:
            village.num_villagers -= 1
            if from != "Minions":
                village.num_minions = 1
            else:
                village.num_demons = 1
        elif village.num_outcasts > 0:
            village.num_outcasts -= 1
            if from != "Minions":
                village.num_minions = 1
            else:
                village.num_demons = 1
        else:
            push_error("Impossible state: No Villagers or Outcasts to convert to Minion")
    if sum > village.num_characters:
        var delta = sum - village.num_characters
        if from != "Villagers":
            if delta > village.num_villagers:
                delta -= village.num_villagers
                village.num_villagers = 0
            else:
                village.num_villagers -= delta
                return 0
        if from != "Outcasts":
            if delta > village.num_outcasts:
                delta -= village.num_outcasts
                village.num_outcasts = 0
            else:
                village.num_outcasts -= delta
                return 0
        if from != "Minions":
            if delta > village.num_minions:
                delta -= village.num_minions
                village.num_minions = 0
            else:
                village.num_minions -= delta
                return 0
        if from != "Demons":
            if delta > village.num_demons:
                delta -= village.num_demons
                village.num_demons = 0
            else:
                village.num_demons -= delta
                return 0
        return delta
    if sum < village.num_characters:
        var delta = village.num_characters - sum
        if from != "Villagers":
            village.num_villagers += delta
            if village.num_villagers == village.num_characters:
                village.num_villagers = village.num_characters - 1
                if from != "Outcasts":
                    village.num_outcasts = 1
                else:
                    village.num_minions = 1
            return 0
        if from != "Outcasts":
            village.num_outcasts += delta
            if village.num_outcasts == village.num_characters:
                village.num_outcasts = village.num_characters - 1
                if from != "Villagers":
                    village.num_villagers = 1
                else:
                    village.num_minions = 1
    return 0

func update_count_spinners() -> void:
    $Dummy/VillageConfig/Ver/Hor2/Vils.value = village.num_villagers
    $Dummy/VillageConfig/Ver/Hor2/Outs.value = village.num_outcasts
    $Dummy/VillageConfig/Ver/Hor2/Mins.value = village.num_minions
    $Dummy/VillageConfig/Ver/Hor2/Dems.value = village.num_demons
    
func _on_solve_pressed() -> void:
    hide_solution()
    $Dummy/SolveOverlay.show()
    solve_prog = 0.0
    solve_puzzle()

func solve_puzzle():
    var solutions = await _solve()
    _done_solving(solutions)

func _solve() -> Array:
    if village.has_duplicate_evils():
        show_error("There are duplicate Evil characters in the village.")
        return [null]

    for char in village.characters:
        if char.disguise == null and char.character.disguise != "None":
            show_error("All characters with disguises must have their disguise set.")
            return [null]

    var num_minions = village.characters.reduce(func(acc: int, char: Character):
        if not char.hidden_evil and char.character.type == "Minion" and not char.character.id == "puppet": # Puppet counts as Villager for this purpose
            return acc + 1
        return acc
    , 0)
    var num_demons = village.characters.reduce(func(acc: int, char: Character):
        if not char.hidden_evil and char.character.type == "Demon":
            return acc + 1
        return acc
    , 0)
    var num_any_evil = village.characters.reduce(func(acc: int, char: Character):
        if char.hidden_evil:
            return acc + 1
        return acc
    , 0)
    var total_evil = num_minions + num_demons + num_any_evil

    var num_minions_deck = village.deck.reduce(func(acc: int, char: CharacterData):
        if char.type == "Minion" and not char.id == "puppet": # Puppet counts as Villager for this purpose
            return acc + 1
        return acc
    , 0)
    var num_demons_deck = village.deck.reduce(func(acc: int, char: CharacterData):
        if char.type == "Demon":
            return acc + 1
        return acc
    , 0)

    if num_minions > village.num_minions:
        show_error("There are too many Minions in the village for the selected number of Minions.")
        return [null]
    if num_demons > village.num_demons:
        show_error("There are too many Demons in the village for the selected number of Demons.")
        return [null]
    if total_evil > village.num_minions + village.num_demons:
        show_error("There are too many Evil characters in the village for the selected number of Minions and Demons.")
        return [null]

    if num_minions_deck > village.num_minions:
        show_error("There are too many Minions in the deck for the selected number of Minions.")
        return [null]
    if num_demons_deck > village.num_demons:
        show_error("There are too many Demons in the deck for the selected number of Demons.")
        return [null]
    if num_minions_deck < village.num_minions:
        show_error("There are too few Minions in the deck for the selected number of Minions.")
        return [null]
    if num_demons_deck < village.num_demons:
        show_error("There are too few Demons in the deck for the selected number of Demons.")
        return [null]

    var counsellor_in_deck = village.deck.any(func(c):
        return c.id == "counsellor"
    )
        
    return await village.solve(self)

func _done_solving(solutions : Array) -> void:
    if solutions.size() == 0:
        show_error("No valid solutions found.")
        $Dummy/SolveOverlay.hide()
        return
        
    if solutions.size() == 1 and solutions[0] == null:
        $Dummy/SolveOverlay.hide()
        return

    var possible_actual_roles : Array[Array] = []
    possible_actual_roles.resize(village.num_characters)
    var possible_corrupted : Array[bool] = []
    possible_corrupted.resize(village.num_characters)
    for sol in solutions:
        for i in village.num_characters:
            if sol[i].corrupted and sol[i].actual_role == null:
                possible_corrupted[i] = true
            if not sol[i].corrupted or sol[i].actual_role != null:
                if not possible_actual_roles[i].has(sol[i].actual_role):
                    possible_actual_roles[i].append(sol[i].actual_role)
    $Dummy/SolHideHint.visible = true
    for i in village.num_characters:
        var card = village.cards[i]
        card.show_solution(possible_actual_roles[i], possible_corrupted[i])
    $Dummy/SolveOverlay.hide()

func show_error(message: String) -> void:
    call_deferred("_show_error", message)
    
func _show_error(message : String) -> void:
    err_time = 5.0
    $Err/Label.text = "CAN'T SOLVE:\n" + message

func _on_import_pressed() -> void:
    $Dummy/ImportDisp.show()

func _on_text_edit_text_changed() -> void:
    $Dummy/ImportDisp/Panel/DoImport.disabled = $Dummy/ImportDisp/Panel/TextEdit.text.is_empty()

func _on_do_import_pressed() -> void:
    var result = import_village($Dummy/ImportDisp/Panel/TextEdit.text)
    if result == "OK":
        $Dummy/ImportDisp.hide()
        $Dummy/ImportDisp/Panel/TextEdit.text = ""
    else:
        import_err_time = 5.0
        $Dummy/ImportDisp/Panel/Err/Label.text = "CAN'T IMPORT:\n" + result

func import_village(text: String) -> String:
    var counts_str = null
    var deck_str = null
    var chars_strs = []
    var lines = text.split("\n", false)
    for line in lines:
        line = line.strip_edges()
        if line.to_lower().begins_with("num_chars:"):
            counts_str = line.substr("num_chars:".length()).strip_edges()
        elif line.to_lower().begins_with("deck:"):
            deck_str = line.substr("deck:".length()).strip_edges()
        elif line.split(" ")[0].ends_with(":"):
            pass # Ignore other metadata lines since we don't use them
        elif not line.begins_with("#") and line != "":
            chars_strs.append(line)
    if counts_str == null:
        return "Missing 'num_chars:' line."
    if deck_str == null:
        return "Missing 'deck:' line."
    if chars_strs.size() == 0:
        return "No character lines found."
    var counts_strs = counts_str.split(",", false)
    if counts_strs.size() != 4:
        return "Invalid 'num_chars:' line. Must have 4 comma-separated values."
    var counts = [0, 0, 0, 0]
    for i in range(4):
        counts_strs[i] = counts_strs[i].strip_edges()
        if not counts_strs[i].is_valid_int():
            return "Invalid 'num_chars:' line. All values must be integers."
        counts[i] = int(counts_strs[i])
        if counts[i] < 0:
            return "Invalid 'num_chars:' line. All values must be non-negative."
    var deck_ids = deck_str.split(",", false)
    var deck : Array[CharacterData] = []
    for i in deck_ids.size():
        deck_ids[i] = deck_ids[i].strip_edges()
        if not Characters.characters.has(deck_ids[i]):
            return "Character '" + deck_ids[i] + "' does not exist."
        if deck.has(Characters.characters[deck_ids[i]]):
            return "Character '" + deck_ids[i] + "' is duplicated in the deck."
        deck.append(Characters.characters[deck_ids[i]])
    var card_count = chars_strs.size()
    var village_builder = Village.new(card_count)
    village_builder.num_characters = card_count
    village_builder.num_villagers = counts[0]
    village_builder.num_outcasts = counts[1]
    village_builder.num_minions = counts[2]
    village_builder.num_demons = counts[3]
    var characters : Array[Character] = village_builder.characters
    for i in card_count:
        characters.append(Character.new(i + 1))
    for i in card_count:
        var line = chars_strs[i]
        var parts = Array(line.split(" ", false))
        var cur = parts.pop_front().strip_edges()
        if cur == null:
            return "Invalid character line: '" + line + "'"
        if cur == "[unknown]":
            for tag in parts:
                tag = tag.strip_edges().to_lower()
                if tag == "#dead" or tag == "#killed_by_demon":
                    characters[i].dead = true
                elif tag == "#hidden_evil":
                    characters[i].hidden_evil = true
                elif tag == "#corrupted":
                    characters[i].corrupted = true
                elif tag == "#never_disguised":
                    characters[i].never_disguised = true
                elif tag == "#never_corrupted":
                    characters[i].never_corrupted = true
                else:
                    pass # Ignore unknown tags
            continue
        if not cur.is_valid_int():
            return "Invalid character line: '" + line + "'. First part must be an integer (reveal order) or '[unknown]'."
        var reveal_order = int(cur)
        if reveal_order < 1 or reveal_order > card_count:
            return "Invalid character line: '" + line + "'. Reveal order must be between 1 and " + str(card_count) + "."
        characters[i].reveal_order = reveal_order
        if reveal_order > 0:
            village_builder.num_revealed += 1
        cur = parts.pop_front().strip_edges()
        if cur == null:
            return "Invalid character line: '" + line + "'. Must have at least a character name."
        while cur.begins_with("#"):
            var tag = cur.to_lower()
            if tag == "#hidden_evil":
                return "Invalid character line: '" + line + "'. '#hidden_evil' tag can only be used with '[unknown]' characters."
            elif tag == "#dead" or tag == "#killed_by_demon":
                characters[i].dead = true
            elif tag == "#corrupted":
                characters[i].corrupted = true
            elif tag == "#never_disguised":
                characters[i].never_disguised = true
            elif tag == "#never_corrupted":
                characters[i].never_corrupted = true
            else:
                pass # Ignore unknown tags
            cur = parts.pop_front().strip_edges()
            if cur == null:
                return "Invalid character line: '" + line + "'. Must have at least a character name."
        var char_name = cur.strip_edges()
        var disguise = null
        if char_name.contains("|"):
            var split = char_name.split("|", false)
            char_name = split[0].strip_edges()
            disguise = split[1].strip_edges()
        if not Characters.characters.has(char_name):
            return "Character '" + char_name + "' does not exist."
        var char_data = Characters.characters[char_name]
        if not deck.has(char_data):
            if char_data.id != "puppet":
                return "Character '" + char_name + "' is not in the deck."
            else:
                deck.append(char_data) # Puppet can be added even if not in deck
        characters[i].character = char_data
        if disguise != null:
            if not Characters.characters.has(disguise):
                return "Disguise character '" + disguise + "' does not exist."
            var disguise_data = Characters.characters[disguise]
            if not deck.has(disguise_data):
                if disguise_data.id != "puppet":
                    return "Disguise character '" + disguise + "' is not in the deck."
                else:
                    deck.append(disguise_data) # Puppet can be added as a disguise even if not in deck
            if char_data.disguise == "None":
                return "Character '" + char_name + "' cannot have a disguise."
            if not Characters.valid_disguise_for(char_data, disguise_data):
                return "Character '" + char_name + "' cannot have disguise '" + disguise + "'."
            characters[i].disguise = disguise_data
        if parts.size() > 0:
            var stmt = " ".join(parts).strip_edges()
            if stmt != "none" and stmt != "null":
                var statement = Characters.parse_statement_from_string(stmt)
                if statement == null:
                    return "Invalid character line: '" + line + "'. Invalid statement."
                characters[i].statement = statement.build(characters[i])
    commit_village(village_builder, deck)
    return "OK"

func export_village() -> String:
    var lines : Array[String] = ["# Village Data:"]
    lines.append("num_chars: " + str(village.num_villagers) + "," + str(village.num_outcasts) + "," + str(village.num_minions) + "," + str(village.num_demons))
    var deck_ids : Array[String] = []
    for char in village.deck:
        deck_ids.append(char.id)
    lines.append("deck: " + ",".join(deck_ids))
    for card in village.cards:
        var parts : Array[String] = []
        if card.data.reveal_order > 0:
            parts.append(str(card.data.reveal_order))
        else:
            parts.append("[unknown]")
        if card.data.dead:
            parts.append("#dead")
        if card.data.corrupted:
            parts.append("#corrupted")
        if card.data.never_disguised:
            parts.append("#never_disguised")
        if card.data.never_corrupted:
            parts.append("#never_corrupted")
        if not card.data.character.unknown:
            var char_part = card.data.character.id
            if card.data.disguise != null:
                char_part += "|" + card.data.disguise.id
            parts.append(char_part)
        if card.data.statement != null:
            parts.append(card.data.statement.get_string())
        lines.append(" ".join(parts))
    return "\n".join(lines)

func _on_cancel_pressed() -> void:
    $Dummy/ImportDisp.hide()

func _on_export_pressed() -> void:
    $Dummy/ExportDisp.show()
    $Dummy/ExportDisp/Panel/TextEdit.text = export_village()

func _on_close_pressed() -> void:
    $Dummy/ExportDisp.hide()

func _on_copy_pressed() -> void:
    DisplayServer.clipboard_set($Dummy/ExportDisp/Panel/TextEdit.text)
    copied_time = 2.0
