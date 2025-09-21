extends Control

var drawing := false
var last_pos := Vector2(-1, -1)
var paths := []
var path_colors := []
var path_widths := []
var canvas_enabled := false

var opt_color := Color(1, 0, 0, 0.5)
var opt_stroke_width := 4
var opt_shape_recognition := true

func _process(delta):
    $Canvas.paths = paths
    $Canvas.path_colors = path_colors
    $Canvas.path_widths = path_widths
    $Canvas.queue_redraw()
    if canvas_enabled:
        $Paint.self_modulate = Color(1, 0.5, 0.5)
    else:
        $Paint.self_modulate = Color(1, 1, 1)
    if $Canvas.showing:
        $Paint.visible = true
        $Hide.position.x = 170
        $PaintOpts.visible = true
        if paths.size() > 0:
            $Undo.visible = true
            $Clear.visible = true
        else:
            $Undo.visible = false
            $Clear.visible = false
    else:
        $Paint.visible = false
        $Hide.position.x = 10
        $PaintOpts.visible = false
        $Undo.visible = false
        $Clear.visible = false

func enable_canvas(enable: bool) -> void:
    canvas_enabled = enable
    $Canvas.mouse_filter = Control.MOUSE_FILTER_PASS if enable else Control.MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                $PaintOpts/PaintOptsPopup.visible = false
                drawing = true
                last_pos = event.position
                paths.append([event.position])
                path_colors.append(opt_color)
                path_widths.append(opt_stroke_width)
            else:
                drawing = false
                last_pos = Vector2(-1, -1)
                try_transform_into_shape(paths[-1])
    elif event is InputEventMouseMotion:
        var mouse_pos = get_local_mouse_position()
        if drawing and mouse_pos != last_pos:
            paths[-1].append(mouse_pos)
            last_pos = mouse_pos

func try_transform_into_shape(path):
    if path.size() < 3:
        return
    var first_point = path[0]
    var last_point = path[-1]
    if first_point.distance_to(last_point) < 20:
        path.append(first_point)
    var roundness = roundness(path)
    var rectangleness = rectangleness(path)
    var linearity = linearity(path)
    var max_of_metrics = max(roundness, rectangleness, linearity)
    if max_of_metrics < 0.75:
        if polygonness(path) > 0.75:
            transform_into_polygon(path)
        return
    if max_of_metrics == roundness:
        transform_into_circle(path)
    elif max_of_metrics == rectangleness:
        transform_into_rectangle(path)
    elif max_of_metrics == linearity:
        transform_into_line(path)
        
func roundness(path, tolerance=0.8):
    var area = polygon_area(path)
    var perimeter = polygon_perimeter(path)
    if perimeter == 0:
        return 0
    var roundness_value = (4 * PI * area) / (perimeter * perimeter)
    return clamp(1 - abs(1 - roundness_value) / tolerance, 0, 1)

func rectangleness(path, tolerance=0.7):
    var bbox = bounding_box(path)
    var bbox_area = bbox.size.x * bbox.size.y
    var area = polygon_area(path)
    if bbox_area == 0:
        return 0
    var rectangleness_value = area / bbox_area
    return clamp(1 - abs(1 - rectangleness_value) / tolerance, 0, 1)

func polygonness(path, tolerance=0.2):
    var convex_hull = Geometry2D.convex_hull(path)
    var hull_area = polygon_area(convex_hull)
    var area = polygon_area(path)
    if hull_area == 0:
        return 0
    var distance_between_ends = path[0].distance_to(path[-1])
    var polygonness_value = area / hull_area
    return clamp(1 - abs(1 - polygonness_value) / tolerance, 0, 1) * clamp(1 - distance_between_ends / 500, 0, 1)

func linearity(path, tolerance=0.1):
    var total_length = 0.0
    for i in range(path.size() - 1):
        total_length += path[i].distance_to(path[i + 1])
    var direct_distance = path[0].distance_to(path[-1])
    if total_length == 0:
        return 0
    var linearity_value = direct_distance / total_length
    return clamp(1 - abs(1 - linearity_value) / tolerance, 0, 1)

func transform_into_circle(path):
    var bbox = bounding_box(path)
    var center = bbox.position + bbox.size / 2
    var radius = min(bbox.size.x, bbox.size.y) / 2
    var num_points = 32
    path.clear()
    for i in range(num_points):
        var angle = (float(i) / num_points) * TAU
        var point = center + Vector2(cos(angle), sin(angle)) * radius
        path.append(point)
    path.append(path[0]) # Close the circle

func transform_into_rectangle(path):
    var bbox = bounding_box(path)
    path.clear()
    path.append(bbox.position)
    path.append(bbox.position + Vector2(bbox.size.x, 0))
    path.append(bbox.position + bbox.size)
    path.append(bbox.position + Vector2(0, bbox.size.y))
    path.append(bbox.position) # Close the rectangle

func transform_into_polygon(path):
    var convex_hull = Geometry2D.convex_hull(path)
    path.clear()
    for point in convex_hull:
        path.append(point)
    path.append(path[0]) # Close the polygon

func transform_into_line(path):
    if path.size() < 2:
        return
    var start_point = path[0]
    var end_point = path[-1]
    path.clear()
    path.append(start_point)
    path.append(end_point)

func polygon_area(path):
    var area = 0.0
    for i in range(path.size()):
        var j = (i + 1) % path.size()
        area += path[i].x * path[j].y
        area -= path[j].x * path[i].y
    return abs(area) / 2.0

func polygon_perimeter(path):
    var perimeter = 0.0
    for i in range(path.size() - 1):
        perimeter += path[i].distance_to(path[i + 1])
    if path.size() > 2:
        perimeter += path[-1].distance_to(path[0])
    return perimeter

func bounding_box(path):
    if path.size() == 0:
        return Rect2()
    var min_x = path[0].x
    var max_x = path[0].x
    var min_y = path[0].y
    var max_y = path[0].y
    for point in path:
        if point.x < min_x:
            min_x = point.x
        if point.x > max_x:
            max_x = point.x
        if point.y < min_y:
            min_y = point.y
        if point.y > max_y:
            max_y = point.y
    return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _on_paint_pressed() -> void:
    enable_canvas(!canvas_enabled)
    $PaintOpts/PaintOptsPopup.visible = false

func _on_paint_mouse_entered() -> void:
    $Paint.modulate = Color(0.5, 1, 0.5)

func _on_paint_mouse_exited() -> void:
    $Paint.modulate = Color(1, 1, 1)

func _on_hide_pressed() -> void:
    $Canvas.appear(not $Canvas.showing)
    $Hide/Off.visible = $Canvas.showing
    if not $Canvas.showing:
        enable_canvas(false)
    $PaintOpts/PaintOptsPopup.visible = false

func _on_hide_mouse_entered() -> void:
    $Hide.modulate = Color(0.5, 1, 0.5)

func _on_hide_mouse_exited() -> void:
    $Hide.modulate = Color(1, 1, 1)

func _on_undo_pressed() -> void:
    if paths.size() > 0:
        paths.pop_back()
        path_colors.pop_back()
        path_widths.pop_back()
    $PaintOpts/PaintOptsPopup.visible = false

func _on_undo_mouse_entered() -> void:
    $Undo.modulate = Color(0.5, 1, 0.5)

func _on_undo_mouse_exited() -> void:
    $Undo.modulate = Color(1, 1, 1)

func _on_clear_pressed() -> void:
    paths.clear()
    path_colors.clear()
    path_widths.clear()
    $PaintOpts/PaintOptsPopup.visible = false

func _on_clear_mouse_entered() -> void:
    $Clear.modulate = Color(0.5, 1, 0.5)

func _on_clear_mouse_exited() -> void:
    $Clear.modulate = Color(1, 1, 1)

func _on_paint_opts_pressed() -> void:
    $PaintOpts/PaintOptsPopup.visible = not $PaintOpts/PaintOptsPopup.visible

func _on_paint_opts_mouse_entered() -> void:
    $PaintOpts.self_modulate = Color(0.5, 1, 0.5)

func _on_paint_opts_mouse_exited() -> void:
    $PaintOpts.self_modulate = Color(1, 1, 1)

func _on_color_picker_button_color_changed(color: Color) -> void:
    opt_color = color

func _on_h_slider_value_changed(value: float) -> void:
    opt_stroke_width = int(value)

func _on_check_button_toggled(toggled_on: bool) -> void:
    opt_shape_recognition = toggled_on

func _on_reset_pressed() -> void:
    opt_color = Color(1, 0, 0, 0.5)
    opt_stroke_width = 4
    opt_shape_recognition = true
    $PaintOpts/PaintOptsPopup/MarginContainer/V1/H1/ColorPickerButton.color = opt_color
    $PaintOpts/PaintOptsPopup/MarginContainer/V1/H2/HSlider.value = opt_stroke_width
    $PaintOpts/PaintOptsPopup/MarginContainer/V1/H3/CheckButton.button_pressed = opt_shape_recognition
    
