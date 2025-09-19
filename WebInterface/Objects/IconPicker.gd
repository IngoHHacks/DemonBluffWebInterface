extends Control

@export var icon_selectable_scene : PackedScene

signal icon_selected(icon)
signal icon_cleared

var icons := []

func _ready():
    if icons == []:
        load_icons()
    for img in icons:
        var icon : ClickableTextureRect = icon_selectable_scene.instantiate()
        icon.texture = img
        icon.pressed.connect(_on_icon_picked.bind(img))
        $Panel/ScrollContainer/HFlowContainer.add_child(icon)

func load_icons():
    for file in DirAccess.open("res://Icons/").get_files():
        if file.ends_with(".png"):
            icons.append(load("res://Icons/" + file))
        

func _on_icon_picked(icon):
    icon_selected.emit(icon)
    visible = false

func _on_clear_pressed() -> void:
    icon_cleared.emit()
    visible = false

func _on_cancel_pressed() -> void:
    visible = false
