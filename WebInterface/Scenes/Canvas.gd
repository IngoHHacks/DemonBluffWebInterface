extends Control

var showing := true
var tweening := false
var paths := []
var path_colors := []
var path_widths := []

func _draw():
    for i in range(paths.size()):
        var path = paths[i]
        var color = path_colors[i]
        var width = path_widths[i]
        if path.size() > 1:
            draw_polyline(path, color, width)
        else:
            draw_circle(path[0], width / 2, color)

func appear(show: bool) -> void:
    if tweening:
        return
    tweening = true
    var tween = create_tween()
    if show:
        visible = true
        $Border.visible = true
        tween.tween_property(self, "scale", Vector2(1, 1), 0.5)
        tween.tween_callback(_on_appeared)
    else:
        $Border.visible = true
        tween.tween_property(self, "scale", Vector2(0, 0), 0.5)
        tween.tween_callback(_on_disappeared)
    showing = show

func _on_appeared() -> void:
    $Border.visible = false
    tweening = false

func _on_disappeared() -> void:
    visible = false
    $Border.visible = false
    tweening = false
