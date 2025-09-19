'''
Clickable.gd
This script makes a UI element clickable and emits a signal when clicked.
'''

extends Control

signal pressed

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit()
