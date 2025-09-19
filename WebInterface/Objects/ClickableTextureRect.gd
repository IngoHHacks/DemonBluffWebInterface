'''
ClickableTextureRect.gd
This script extends TextureRect to make it clickable and change its color on mouse hover.
'''

extends TextureRect

class_name ClickableTextureRect

signal pressed

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit()

func _on_mouse_entered() -> void:
    self_modulate = Color(0.5, 1, 0.5)

func _on_mouse_exited() -> void:
    self_modulate = Color(1, 1, 1)
    
