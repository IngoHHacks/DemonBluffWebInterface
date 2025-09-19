'''
StatementEditor.gd
This script provides a UI for selecting and configuring character statements for a card in the interface.
'''

extends Control

const Village = VillageScene.Village
const Character = Characters.Character
const CharacterData = Characters.CharacterData

var village : Village = null
var character : Character = null
var statement : Statement = null
var settings : Array = []
var string_to_id = {}
var tree_items = {}

signal done
signal clear

func _ready() -> void:
    var tree = $SearchPreset
    var root = tree.create_item()
    var sorted_chars = Characters.characters.values().filter(func(c):
        return c.category != null and c.category.size() > 0
    )
    sorted_chars.sort_custom(func(a, b):
        for i in range(min(a.category.size(), b.category.size())):
            if a.category[i] != b.category[i]:
                return a.category[i] < b.category[i]
        return a.category.size() < b.category.size()
    )
    for char in sorted_chars:
        var cur : TreeItem = root
        for i in range(char.category.size()):
            var node = char.category[i]
            if i == 0:
                node = "• " + node 
            var children = cur.get_children()
            var child = children.find_custom(func(it : TreeItem): return it.get_text(0) == node)
            if child != -1:
                cur = children[child]
                if i == char.category.size() - 1:
                    push_error("Duplicate final category node: " + node + " for character " + char.id)
            else:
                var new_child = tree.create_item(cur)
                new_child.set_text(0, node)
                cur = new_child
            if i < char.category.size() - 1:
                cur.set_collapsed(true)
                cur.set_selectable(0, false)
            else:
                cur.set_icon(0, char.portrait)
                cur.set_selectable(0, true)
                cur.set_metadata(0, char.id)
                tree_items[char.id] = cur
    merge_singles(root)
    _on_preset_select_item_selected($Panel/PresetSelect.selected)
    for item in range($Panel/PresetSelect.item_count):
        var name = $Panel/PresetSelect.get_item_text(item).to_lower().replace(" ", "_")
        string_to_id[name] = item
    string_to_id["poet"] = string_to_id["special_(poet)"]

func merge_singles(item: TreeItem) -> void:
    var children = item.get_children()
    if children == null or children.size() == 0:
        return
    if children.size() == 1:
        var child = children[0]
        item.set_text(0, item.get_text(0) + " " + child.get_text(0))
        item.set_icon(0, child.get_icon(0))
        item.set_metadata(0, child.get_metadata(0))
        item.set_selectable(0, child.is_selectable(0))
        if item.get_metadata(0) != null:
            tree_items[item.get_metadata(0)] = item
        item.remove_child(child)
        for grandchild in child.get_children():
            grandchild.set_parent(item)
        children = item.get_children()
    for child in children:
        merge_singles(child)
    
func init(village : Village, card : Card):
    character = card.data
    self.village = village
    var char = card.data.character if card.data.disguise == null else card.data.disguise
    var statement = card.data.statement
    if statement == null:
        if char != null and char.id in string_to_id:
            $Panel/PresetSelect.selected = string_to_id[char.id]
        else:
            $Panel/PresetSelect.selected = 0
        _on_preset_select_item_selected($Panel/PresetSelect.selected)
    else:
        $Panel/PresetSelect.selected = string_to_id[statement.character.id]
        set_setting_values(statement.args)

func _on_preset_select_item_selected(index: int) -> void:
    settings.clear()
    statement = Statement.build($Panel/PresetSelect.get_item_text(index).to_lower().replace(" ", "_"), character)
    for child in $Panel/ScrollContainer/VFlowContainer.get_children():
        child.queue_free()
    var selected = $Panel/PresetSelect.get_item_text(index).to_lower().replace(" ", "_")
    if selected.to_lower() == "special_(poet)":
        selected = "poet"
    var char = Characters.characters[selected]
    for i in range(0, char.parameters.size()):
        var param = char.parameters[i].to_lower()
        var param_name = char.parameter_names[i] if i < char.parameter_names.size() else ""
        var split = param.split("|")
        var type = split[0]
        var args = split.slice(1, split.size())
        create_setting(type, args, param_name, char)
    _no_signal = true
    uncollapse_parents(tree_items[selected] if selected in tree_items else null)
    $SearchPreset.set_selected(tree_items[selected] if selected in tree_items else null, 0)
    $SearchPreset.scroll_to_item(tree_items[selected] if selected in tree_items else null)
    $SearchPreset.queue_redraw()
    _no_signal = false
    update_preview()

func uncollapse_parents(item: TreeItem) -> void:
    if item == null:
        return
    var parent = item.get_parent()
    if parent != null:
        parent.set_collapsed(false)
        uncollapse_parents(parent)

func get_setting_values() -> Array:
    var values = []
    for i in range(0, settings.size()):
        var obj = settings[i]
        var value = ""
        if obj.has_node("OptionButton"):
            value = obj.get_node("OptionButton").get_item_text(obj.get_node("OptionButton").selected)
        elif obj.has_node("SpinBox"):
            value = str(int(obj.get_node("SpinBox").value))
        values.append(value)
    return values

func set_setting_values(values: Array) -> void:
    for i in range(0, min(values.size(), settings.size())):
        var obj = settings[i]
        var value = values[i]
        if obj.has_node("OptionButton"):
            var ob = obj.get_node("OptionButton")
            for j in range(ob.get_item_count()):
                if ob.get_item_text(j).to_lower() == str(value).to_lower():
                    ob.selected = j
                    break
        elif obj.has_node("SpinBox"):
            var sb = obj.get_node("SpinBox")
            if value is float or value is int or value is String and value.is_valid_int():
                sb.value = int(value)
    update_preview()

func create_setting(param_type: String, options: Array, param_name: String, char : CharacterData) -> void:
    var optional = false
    if param_type.begins_with("optional_"):
        optional = true
        param_type = param_type.substr("optional_".length(), -1)
    var scene = load("res://Objects/arg_" + param_type + ".tscn") as PackedScene
    if scene == null:
        push_error("Unknown parameter type: " + param_type)
        return
    var node = scene.instantiate()
    settings.append(node)
    if node == null:
        push_error("Failed to instantiate parameter type: " + param_type)
        return
    if param_name != null and param_name != "":
        node.get_node("Label").text = param_name + (":" if not param_type == "character" else " #")
    if char.id == "dreamer" and param_type == "evil_role":
        node.get_node("OptionButton").add_item("Cabbage")
    if optional:
        if node.has_node("OptionButton"):
            node.get_node("OptionButton").add_item("None")
        if node.has_node("SpinBox"):
            node.get_node("SpinBox").min_value = 0
            node.get_node("SpinBox").value = 0
    if node.has_node("SpinBox") and options.size() >= 1:
        if options[0].is_valid_int():
            node.get_node("SpinBox").min_value = int(options[0])
            node.get_node("SpinBox").value = int(options[0])
        if options.size() >= 2 and options[1].is_valid_int():
            node.get_node("SpinBox").max_value = int(options[1])
    if node.has_node("OptionButton"):
        node.get_node("OptionButton").item_selected.connect(_on_setting_changed)
    if node.has_node("SpinBox"):
        node.get_node("SpinBox").value_changed.connect(_on_setting_changed)
    if param_type == "character":
        var spin = node.get_node("SpinBox")
        spin.max_value = village.num_characters
    $Panel/ScrollContainer/VFlowContainer.add_child(node)

func get_statement() -> Statement:
    return statement

func _on_setting_changed(_val) -> void:
    update_preview()
    
func update_preview():
    var values = get_setting_values()
    for i in range(0, values.size()):
        statement.set_arg(i, values[i])
    var stmt = statement.get_string().replace("could be: Cabbage", "could be:\na Cabbage")
    $Panel/Preview.text = stmt.replace("\n", " ")

func _on_confirm_pressed() -> void:
    done.emit()
    visible = false

func _on_clear_pressed() -> void:
    clear.emit()
    visible = false

func _on_cancel_pressed() -> void:
    visible = false

func _on_search_toggled(toggled_on: bool) -> void:
    $SearchPreset.visible = toggled_on

var _no_signal = false

func _on_search_preset_item_selected() -> void:
    if _no_signal:
        return
    var item = $SearchPreset.get_selected()
    if item != null:
        var id = item.get_metadata(0)
        if id != null and id in string_to_id:
            $Panel/PresetSelect.selected = string_to_id[id]
            _on_preset_select_item_selected($Panel/PresetSelect.selected)

func _on_manual_entry_text_changed() -> void:
    var sp = Characters.parse_statement_from_string($Panel/ManualEntry.text)
    if sp == null:
        $Panel/ManualDesc.text = "Not valid!"
        $Panel/Label2/Set.disabled = true
        return
    else:
        $Panel/ManualDesc.text = sp.char.name + " (" + ", ".join(sp.args) + ")"
        $Panel/Label2/Set.disabled = false

func _on_set_pressed() -> void:
    var sp = Characters.parse_statement_from_string($Panel/ManualEntry.text)
    if sp == null:
        return
    $Panel/PresetSelect.selected = string_to_id[sp.char.id]
    _on_preset_select_item_selected($Panel/PresetSelect.selected)
    set_setting_values(sp.args)
