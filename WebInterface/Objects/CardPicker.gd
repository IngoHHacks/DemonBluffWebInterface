extends Control

const CharacterData = Characters.CharacterData

@export var card_holder : PackedScene

signal card_selected(character, keep_old_as_disguise)
signal card_cleared

func _ready():
    for name in Characters.characters:
        var ch = Characters.characters[name]
        var holder = card_holder.instantiate()
        var card = holder.get_node("Card")
        card.set_character(ch)
        card.reveal()
        card.get_node("Clickable").pressed.connect(_on_card_picked.bind(card))
        $Panel/ScrollContainer/HFlowContainer.add_child(holder)
    var sorted = $Panel/ScrollContainer/HFlowContainer.get_children()
    sorted.sort_custom(Characters._card_order)
    for c in sorted:
        $Panel/ScrollContainer/HFlowContainer.move_child(c, $Panel/ScrollContainer/HFlowContainer.get_child_count() - 1)

func set_filter(filter, exclude := []) -> void:
    if filter == null:
        for holder in $Panel/ScrollContainer/HFlowContainer.get_children():
            holder.visible = true
    else:
        for holder in $Panel/ScrollContainer/HFlowContainer.get_children():
            var card = holder.get_node("Card")
            holder.visible = matches_filter(card.data.character, filter)
    for ex in exclude:
        for holder in $Panel/ScrollContainer/HFlowContainer.get_children():
            var card = holder.get_node("Card")
            if card.data.character.id == ex.id:
                holder.visible = false

func matches_filter(character: CharacterData, filter: String) -> bool:
    if "RandomRole" in filter and not character.can_be_used_as_disguise:
        return false
    if "#Good" in filter and character.alignment != "Good":
        return false
    if "#Evil" in filter and character.alignment != "Evil":
        return false
    if "#Villager" in filter and character.type != "Villager":
        return false
    if "#Outcast" in filter and character.type != "Outcast":
        return false
    if "#Minion" in filter and character.type != "Minion":
        return false
    if "#Demon" in filter and character.type != "Demon":
        return false
    return true

func set_clear_enabled(enabled: bool) -> void:
    $Panel/Clear.visible = enabled
    $Panel/KeepOldAsDisguise.visible = enabled

func _on_card_picked(card):
    card_selected.emit(card.data.character, $Panel/KeepOldAsDisguise.button_pressed)
    visible = false

func _on_clear_pressed() -> void:
    card_cleared.emit()
    visible = false

func _on_cancel_pressed() -> void:
    visible = false
