extends Control

var card_ref : Node = null

func _process(_delta):
    for i in range(4):
        var node = $Panel/Sep.get_node("Marker" + str(i + 1))
        var check = node.get_node("On") as CheckButton
        var color = node.get_node("Color") as ColorPickerButton
        var icon = node.get_node("IconDisp") as TextureRect
        $Panel/Sep/CardHolder/Card.set_marker(i, check.button_pressed)
        $Panel/Sep/CardHolder/Card.set_marker_data(i, color.color, icon.texture)
        if card_ref != null:
            card_ref.set_marker(i, check.button_pressed)
            card_ref.set_marker_data(i, color.color, icon.texture)

func set_card_ref(card_ref) -> void:
    self.card_ref = card_ref
    $Panel/Sep/CardHolder/Card.set_character(card_ref.data.get_visible_character())
    if not card_ref.data.get_visible_character().unknown:
        $Panel/Sep/CardHolder/Card.reveal()
    else:
        $Panel/Sep/CardHolder/Card.unreveal()
    for i in range(4):
        var node = $Panel/Sep.get_node("Marker" + str(i + 1))
        var check = node.get_node("On") as CheckButton
        var color = node.get_node("Color") as ColorPickerButton
        var icon = node.get_node("IconDisp") as TextureRect
        var on = card_ref.get_marker(i)
        check.button_pressed = on
        var marker_color = card_ref.get_marker_color(i)
        if marker_color != null:
            color.color = marker_color
        else:
            color.color = Color(0.45, 1, 0)
        var marker_icon = card_ref.get_marker_icon(i)
        icon.texture = marker_icon

var current_icon_marker := -1

func _on_icon_pressed(id: int) -> void:
    current_icon_marker = id
    $IconPicker.visible = true

func _on_icon_picker_icon_selected(icon: Variant) -> void:
    if current_icon_marker != -1:
        var node = $Panel/Sep.get_node("Marker" + str(current_icon_marker))
        var icon_disp = node.get_node("IconDisp") as TextureRect
        icon_disp.texture = icon
        
func _on_icon_picker_icon_cleared() -> void:
    if current_icon_marker != -1:
        var node = $Panel/Sep.get_node("Marker" + str(current_icon_marker))
        var icon_disp = node.get_node("IconDisp") as TextureRect
        icon_disp.texture = null

func _on_done_pressed() -> void:
    card_ref = null
    visible = false
