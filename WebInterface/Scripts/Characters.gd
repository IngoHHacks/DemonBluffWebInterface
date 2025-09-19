extends Node

const Village = VillageScene.Village

const StartGameActOrder = [
    "baa",
    "counsellor",
    "pooka",
    "poisoner",
    "witch",
    "marionette",
    "puppeteer",
    "plague_doctor",
    "shaman",
    "alchemist",
    "bounty_hunter",
    "puppet",
    "lilis"
]

class Character:
    var id := 0
    var _character : CharacterData
    var character : CharacterData:
        get:
            if _character != null:
                return _character
            return CharacterData.make_unknown(hidden_evil)
        set(value):
            _character = value
            
    var disguise : CharacterData = null
    var dead := false
    var corrupted := false
    var never_disguised := false
    var never_corrupted := false
    var hidden_evil := false
    var statement : Statement = null
    var reveal_order := 0

    var affected_by_evil := false
    var assumed_corrupted := false
    var assumed_cured := false
    var assumed_cured_by : Character = null
    var assumed_corrupted_by : Character = null
    var maybe_affected_by_evil := false
    var maybe_corrupted := false
    var maybe_cured := false
    var maybe_cured_by : Character = null
    var maybe_corrupted_by : Character = null
    var num_cured := 0
    var num_maybe_cured := 0

    func _init(id: int = 0):
        self.id = id

    func duplicate() -> Character:
        var c = Character.new(id)
        c._character = _character
        c.disguise = disguise
        c.dead = dead
        c.corrupted = corrupted
        c.never_disguised = never_disguised
        c.never_corrupted = never_corrupted
        c.hidden_evil = hidden_evil
        if statement != null:
            c.statement = statement.copy()
            c.statement.speaker = c
        c.reveal_order = reveal_order
        c.affected_by_evil = affected_by_evil
        c.assumed_corrupted = assumed_corrupted
        c.assumed_cured = assumed_cured
        c.assumed_cured_by = assumed_cured_by
        c.assumed_corrupted_by = assumed_corrupted_by
        return c

    func get_effective_character() -> CharacterData:
        if disguise != null:
            return disguise
        return character

    func get_visible_character() -> CharacterData:
        if disguise != null and not dead:
            return disguise
        return character
    
    func alignment() -> String:
        return character.alignment

    func seen_alignment() -> String:
        return character.seen_alignment

    func is_evil() -> bool:
        return character.alignment == "Evil"

    func seen_as_evil() -> bool:
        return character.seen_alignment == "Evil"

    func is_good() -> bool:
        return character.alignment == "Good"

    func seen_as_good() -> bool:
        return character.seen_alignment == "Good"

    func should_lie(include_disguise := true) -> bool:
        if character.lying == "Never" or (include_disguise and disguise != null and disguise.lying == "Never"): # disguise for confessor
            return false
        if character.lying == "Always":
            return true
        return assumed_corrupted

    func is_statement_valid(village: Village) -> bool:
        if statement == null:
            return true
        if statement.character.id == "confessor":
            var is_dizzy = statement.args[0]
            if is_dizzy and not (is_evil() or assumed_corrupted or maybe_corrupted):
                return false
            if not is_dizzy and not (is_good() and not assumed_corrupted and not maybe_corrupted):
                return false
            return true
        var truth = statement.is_true(village)
        if truth == Truthness.TRUTH:
            return not should_lie()
        elif truth == Truthness.LIE:
            return should_lie()
        elif truth == Truthness.UNKNOWN:
            return true
        elif truth == Truthness.INVALID:
            return false
        push_error("Statement returned invalid truth value")
        return false

    func is_character_valid(village: Village) -> bool:
        # Confessor may only say "I am Good" if they are actually Good and
        # may only say "I am Dizzy" if they are Evil or Corrupted
        if character.id == "confessor" and statement != null:
            var is_dizzy = statement.args[0]
            return is_evil() or assumed_corrupted == is_dizzy
        # Counsellor must sit next to at least one Outcast
        if character.id == "counsellor":
            var unknown_outcasts := village.num_outcasts > village.num_of_type("Outcast")
            return village.get_adjacent_to(self).filter(func(c):
                return c.character.type == "Outcast" or c.character.unknown and not c.hidden_evil and unknown_outcasts
            ).size() > 0
        # Puppeteer must sit next to Puppet (or two unconvertable characters)
        if character.id == "puppeteer":
            return village.get_adjacent_to(self).filter(func(c):
                return c.character.id == "puppet" or c.character.unknown and c.hidden_evil
            ).size() > 0 or village.get_adjacent_to(self).filter(func(c):
                return c.character.type != "Villager"
            ).size() == 2
        # Conversely, Puppet must sit next to Puppeteer
        if character.id == "puppet":
            return village.get_adjacent_to(self).filter(func(c):
                return c.character.id == "puppeteer" or c.character.unknown and c.hidden_evil
            ).size() > 0
        # Doppelganger must copy the role of another character
        if character.id == "doppelganger":
            return village.characters.filter(func(c):
                return c.id != id and c.character.id == disguise.id or c.character.unknown and not c.hidden_evil or c.character.id == "baker"
            ).size() > 0
        return true

    func adjacent_to_role(village : Village, role: String) -> bool:
        return village.get_adjacent_to(self).any(func(c):
            return c.character.id == role
        )

class CharacterData:
    var id : String
    var name: String
    var portrait: Texture2D
    var alt_portraits: Dictionary[int, Texture2D] = {}
    var hidden := false
    var type := "None"
    var alignment := "Good"
    var seen_alignment := "Good"
    var corruption := "Allowed"
    var lying := "Allowed"
    var disguise := "None"
    var registeras := "None"
    var description:= ""
    var hints := []
    var parameters := []
    var parameter_names := [] # Displayed names
    var arg_names := [] # Internal names (for Lua)
    var statement := []
    var unknown := false
    var category := []
    var statement_regex = ""
    var regex_transforms = {}
    var regex_arg_map = {}
    var can_be_used_as_disguise := true

    func _init(id: String):
        self.id = id


    static var _good_dummy : CharacterData = null
    static var _evil_dummy : CharacterData = null
    static func make_unknown(hidden_evil: bool) -> CharacterData:
        if hidden_evil and _evil_dummy != null:
            return _evil_dummy
        if not hidden_evil and _good_dummy != null:
            return _good_dummy
        var unknown = CharacterData.new("unknown_" + ("evil" if hidden_evil else "good"))
        unknown.name = "Unknown " + ("Evil" if hidden_evil else "Good")
        unknown.portrait = load("res://Characters/missing_" + ("evil" if hidden_evil else "good") + ".png")
        unknown.hidden = true
        unknown.type = "Villager" if not hidden_evil else "Minion"
        unknown.alignment = "Evil" if hidden_evil else "Good"
        unknown.seen_alignment = "Evil" if hidden_evil else "Good"
        unknown.corruption = "Allowed" if not hidden_evil else "Never"
        unknown.lying = "Allowed" if not hidden_evil else "Always"
        unknown.disguise = "None"
        unknown.registeras = "None"
        unknown.description = "[Unknown Character]"
        unknown.unknown = true
        if hidden_evil:
            _evil_dummy = unknown
        else:
            _good_dummy = unknown
        return unknown


var characters : Dictionary[String, CharacterData] = {}

func _ready():
    for file in DirAccess.open("res://Characters/").get_files():
        if file.ends_with(".json"):
            var content = FileAccess.open("res://Characters/" + file, FileAccess.READ).get_as_text()
            var json = JSON.parse_string(content)
            var img = load("res://Characters/" + json["id"] + ".png")
            var name = json["id"]
            var alt_id = 0
            if name.find("-") != -1:
                alt_id = int(name.split("-")[1]) - 1
                name = name.split("-")[0]
            if not name in Characters:
                characters[name] = CharacterData.new(name)
            if alt_id == 0:
                characters[name].portrait = img
            else:
                characters[name].alt_portraits[alt_id] = img
            characters[name].name = json["name"]
            characters[name].hidden = json.get("hidden", false)
            characters[name].type = json.get("type", "Villager")
            characters[name].alignment = json.get("alignment", "Good")
            characters[name].seen_alignment = json.get("seen_alignment", characters[name].alignment)
            characters[name].corruption = json.get("corruption", "Allowed")
            characters[name].lying = json.get("lying", "Allowed")
            characters[name].disguise = json.get("disguise", "None")
            characters[name].registeras = json.get("registeras", "None")
            characters[name].description = json.get("description", "")
            if json.has("hints") and json["hints"] is String:
                characters[name].hints = json["hints"].split("\n")
            elif json.has("hints") and json["hints"] is Array:
                characters[name].hints = json["hints"]
            else:
                characters[name].hints = []
            characters[name].parameters = json.get("parameters", [])
            characters[name].parameter_names = json.get("parameter_names", [])
            characters[name].arg_names = json.get("arg_names", [])
            characters[name].statement = json.get("statement", [])
            var cat = json.get("category", null)
            if cat != null and cat is String and cat != "":
                characters[name].category = cat.split("\\")
            characters[name].statement_regex = json.get("statement_regex", null)
            characters[name].regex_transforms = json.get("regex_transforms", {})
            characters[name].regex_arg_map = json.get("regex_arg_map", {})
            characters[name].can_be_used_as_disguise = json.get("can_be_used_as_disguise", true)
            
func _card_order(a: Node, b: Node) -> bool:
    var char1 : CharacterData = a.get_node("Card").data.character
    var char2 : CharacterData = b.get_node("Card").data.character
    if char1.type != char2.type:
        return type_id(char1.type) < type_id(char2.type)
    return char1.id < char2.id

func type_id(t: String) -> int:
    match t:
        "Villager":
            return 0
        "Outcast":
            return 1
        "Minion":
            return 2
        "Demon":
            return 3
    return 4

func valid_disguise_for(char : CharacterData, disguise : CharacterData) -> bool:
    if char.disguise == "None" and not disguise.unknown:
        return false
    if not disguise.can_be_used_as_disguise and not disguise.unknown:
        return false
    if disguise.id == char.id:
        return false
    if "#Good" in char.disguise and disguise.alignment != "Good" and not disguise.unknown:
        return false
    if "#Evil" in char.disguise and disguise.alignment != "Evil" and not disguise.unknown:
        return false
    if "#Villager" in char.disguise and disguise.type != "Villager" and not disguise.unknown:
        return false
    if "#Outcast" in char.disguise and disguise.type != "Outcast" and not disguise.unknown:
        return false
    if "#Minion" in char.disguise and disguise.type != "Minion" and not disguise.unknown:
        return false
    if "#Demon" in char.disguise and disguise.type != "Demon" and not disguise.unknown:
        return false
    return true

func parse_statement_from_string(string : String) -> StatementProto:
    string = string.strip_edges()
    while string.contains("  "):
        string = string.replace("  ", " ")
    for char : CharacterData in characters.values():
        if char.statement_regex == null or char.statement_regex.is_empty():
            continue
        var regex = RegEx.new()
        var err = regex.compile("(?i)" + char.statement_regex)
        if err != OK:
            push_error("Failed to compile regex for " + char.id)
            continue
        var result = regex.search(string)
        if result == null:
            continue
        var args = Array(result.strings.slice(1, result.strings.size()))
        args = args.filter(func(s):
            return s != null and s != ""
        )
        if char.regex_transforms.size() > 0:
            var transforms = char.regex_transforms.keys().map(func(k): return k.to_lower())
            var vals = char.regex_transforms.values()
            for i in range(args.size()):
                if args[i].to_lower() in transforms: 
                    args[i] = vals[transforms.find(args[i].to_lower())]
        args = args.filter(func(s):
            return s != null
        )
        var mapped_args = Statement.build_defaults(char.parameters)
        if char.regex_arg_map.size() > 0:
            var num_groups = str(args.size())
            if not char.regex_arg_map.has(num_groups):
                push_error("No regex_arg_map for " + char.id + " with " + num_groups + " groups")
                mapped_args = args
            else:
                var map = char.regex_arg_map[num_groups]
                for i in range(args.size()):
                    mapped_args[map[i]] = TypeUtils.cast_to_type_of(mapped_args[map[i]], args[i])
        else:
            for i in range(args.size()):
                mapped_args[i] = TypeUtils.cast_to_type_of(mapped_args[i], args[i])
        return StatementProto.new(char, mapped_args)
    return null
                    
