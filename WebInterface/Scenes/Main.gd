extends Node

var mute := false

func _ready():
    $BGM.play()


func _on_mute_pressed() -> void:
    mute = not mute
    AudioServer.set_bus_mute(0, mute)
    if mute:
        $Village/Dummy/VillageConfig/Mute.icon = load("res://Sprites/mute.png")
    else:
        $Village/Dummy/VillageConfig/Mute.icon = load("res://Sprites/unmute.png")
