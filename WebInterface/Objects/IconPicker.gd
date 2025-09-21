'''
IconPicker.gd
This script provides a UI for selecting an icon from a predefined set of images.
'''

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
        # Web exports are a bit weird and only include .import files, but the PNGs can still be loaded via load()
        if file.ends_with(".import"):
            icons.append(load("res://Icons/" + file.substr(0, file.length() - ".import".length())))
        

func _on_icon_picked(icon):
    icon_selected.emit(icon)
    visible = false

func _on_clear_pressed() -> void:
    icon_cleared.emit()
    visible = false

func _on_cancel_pressed() -> void:
    visible = false
