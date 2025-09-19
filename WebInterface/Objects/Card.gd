'''
Card.gd
This script manages the display and interaction of character cards in the village scene.
'''

extends Node2D

class_name Card

const Character := Characters.Character
const CharacterData := Characters.CharacterData
const Village := VillageScene.Village

const missing := preload("res://Characters/missing_good.png")

const WIDTH := 570
const HEIGHT := 553

var id := 0
var delay := 0.0
var blink_time := 0.0
var village : Village = null
var vscene : VillageScene = null
var target_position := Vector2.ZERO
var text_container : NinePatchRect = null
var text_label : Label = null
var movement_tween : Tween = null

var data := Character.new(0)

var hovered := false

func _process(delta):
    if village != null and village.num_characters > 0:
        $CardNum.text = "#" + str(data.id)
        if target_position == Vector2.ZERO:
            var angle_step = 360.0 / village.num_characters
            var radius = 220.0
            var deg = id * angle_step - 90
            var angle = deg_to_rad(deg)
            var x = radius * cos(angle)
            var y = radius * sin(angle)
            target_position = Vector2(x, y)
            var deg_mod = fposmod(deg, 360.0)
            if deg_mod >= 295 or deg_mod <= 65:
                text_container = $RightTextContainer
                text_label = $RightTextContainer/Text
            elif deg_mod >= 65 and deg_mod < 115:
                text_container = $TopTextContainer
                text_label = $TopTextContainer/Text
            elif deg_mod >= 115 and deg_mod <= 245:
                text_container = $LeftTextContainer
                text_label = $LeftTextContainer/Text
            else:
                text_container = $BottomTextContainer
                text_label = $BottomTextContainer/Text
        text_label.visible_ratio += delta * 2
        var fs = 16
        text_label.add_theme_font_size_override("font_size", fs)
        var h = max(86, text_label.get_minimum_size().y + 42)
        while h > 200 and fs > 6:
            fs -= 1
            text_label.add_theme_font_size_override("font_size", fs)
            h = max(86, text_label.get_minimum_size().y + 42)
        if text_container == $RightTextContainer:
            $RightTextContainer.size.y = h
            $RightTextContainer.position.y = -300 - 4*$RightTextContainer.size.y + 5*86
        elif text_container == $BottomTextContainer:
            $BottomTextContainer.size.y = h
            $BottomTextContainer.position.y = 800 + 5*$BottomTextContainer.size.y - 5*86
            $BottomTextContainer/Text.anchor_top = 1.0
        elif text_container == $LeftTextContainer: 
            $LeftTextContainer.size.y = h
            $LeftTextContainer.position.y = -300 - 4*$LeftTextContainer.size.y + 5*86
        else:
            $TopTextContainer.size.y = h
            $TopTextContainer.position.y = -800 - 5*$TopTextContainer.size.y + 5*86
            $TopTextContainer/Text.anchor_bottom = 1.0
        if delay > (id-1) * 0.1:
            visible = true
            if position.distance_to(target_position) > 1:
                if movement_tween == null or not movement_tween.is_running():
                    movement_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
                    movement_tween.tween_property(self, "position", target_position, 1)
            else:
                position = target_position
        else:
            visible = false
        delay += delta
        $CardEdit.visible = vscene.closest_card() == self
        $Clickable.visible = false
        if data.dead:
            $Dead.visible = true
            $Revealed.modulate = Color(0.7, 0.3, 0.3)
            $Unrevealed.modulate = Color(0.7, 0.3, 0.3)
            $Dead.modulate = Color(0.7, 0.7, 0.7)
        else:
            $Dead.visible = false
            $Revealed.modulate = Color(1.0, 1.0, 1.0)
            $Unrevealed.modulate = Color(1.0, 1.0, 1.0)
        if is_revealed():
            $RevealOrder.visible = true
            $RevealOrder/Label.text = str(data.reveal_order)
        else:
            $RevealOrder.visible = false
    else:
        $CardEdit.visible = false
        $Clickable.visible = true
        if blink_time == 0:
            if hovered:
                modulate = Color(1.2, 1.2, 1.2)
            else:
                modulate = Color(1.0, 1.0, 1.0)

    if blink_time > 0:
        blink_time -= delta
        if fmod(blink_time, 0.5) > 0.25:
            modulate = Color(1.0, 0.5, 0.5)
        else:
            modulate = Color(1.0, 1.0, 1.0)
    else:
        blink_time = 0
            
    if data._character != null and not data.character.unknown:
        if data.never_disguised or data.never_corrupted:
            $Disguise.visible = false
            
            if data.never_disguised and data.never_corrupted:
                $DisguiseName.text = "<Real, Uncorrupted>"
            elif data.never_corrupted:
                $DisguiseName.text = "<Uncorrupted>"
            elif data.never_disguised:
                $DisguiseName.text = "<Real>"
        elif data.disguise != null:
            $Disguise.visible = true
            if data.dead:
                $DisguiseName.text = "(" + data.disguise.name.to_upper().replace("_", " ") + ")"
            else:
                $DisguiseName.text = "(" + data.character.name.to_upper().replace("_", " ") + ")"
        else:
            $Disguise.visible = false
            $DisguiseName.text = ""
    else:
        $Disguise.visible = false
        if data.hidden_evil:
            $DisguiseName.text = "<Evil>"
        else:
            $DisguiseName.text = ""
    
    if village != null:
        if is_revealed() and data._character != null:
            $CardEdit/Disguise.disabled = data.character.disguise == "None"
            $CardEdit/Speech.disabled = false
            $CardEdit/Corruption.disabled = data.character.alignment != "Good"
            $CardEdit/Uncorrupted.visible = data.character.alignment == "Good" and not data.character.corruption == "Always"
            $CardEdit/RevealEarlier.visible = true
            $CardEdit/RevealLater.visible = true
            $CardEdit/MarkEvil.visible = false
            $CardEdit/Real.visible = data.character.disguise == "None"
            $CardEdit/RevealEarlier.disabled = data.reveal_order <= 1
            $CardEdit/RevealLater.disabled = data.reveal_order >= village.num_revealed
        else:
            $CardEdit/Disguise.disabled = true
            $CardEdit/Speech.disabled = true
            $CardEdit/Corruption.disabled = true
            $CardEdit/Uncorrupted.visible = false
            $CardEdit/RevealEarlier.visible = false
            $CardEdit/RevealLater.visible = false
            $CardEdit/MarkEvil.visible = true
            $CardEdit/Real.visible = false

func reveal(silent := false):
    if is_revealed():
        return
    $Revealed.visible = true
    $Unrevealed.visible = false
    if not silent and village != null:
        data.reveal_order = village.next_reveal_order()

func unreveal(silent := false):
    if not is_revealed():
        return
    $Revealed.visible = false
    $Unrevealed.visible = true
    if not silent and village != null:
        village.unreveal_character(data)

func is_revealed() -> bool:
    return $Revealed.visible

func set_character(character: CharacterData):
    if character == null or character.unknown:
        unset_character()
        return
    if character.disguise != "None":
        data.never_disguised = false
    if character.alignment != "Good" or character.corruption == "Always":
        data.never_corrupted = false
    data.character = character
    data.hidden_evil = false
    if character.disguise == "None":
        data.disguise = null
    if data.disguise == null or data.dead:
        set_portrait(character)

func unset_character():
    data.character = null
    data.disguise = null
    data.corrupted = false
    data.never_disguised = false
    set_statement(null)
    set_portrait(null)

func set_portrait(character: CharacterData):
    if character == null:
        $Revealed/CharacterTex.texture = missing
        $Revealed/Name.text = "[font_size=48]CHARACTER NAME[/font_size]"
        $Revealed/Name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
        $Revealed/Border.modulate = Color(0.65, 0.35, 0.75)
        return
    $Revealed/CharacterTex.texture = character.portrait
    var font_color = "#FFFFFF"
    if character.type == "Outcast":
        $Revealed/Border.modulate = Color(0.8, 0.7, 0.0)
        font_color = "#FFFF7F"
    elif character.type == "Minion":
        $Revealed/Border.modulate = Color(1.0, 0.0, 0.0)
        font_color = "#FF9933"
    elif character.type == "Demon":
        $Revealed/Border.modulate = Color(1.0, 0.0, 0.0)
        font_color = "#FF3333"
    else:
        $Revealed/Border.modulate = Color(0.65, 0.35, 0.75)
    var _name = character.name.to_upper().replace("_", " ")
    if data.corrupted:
        $Revealed/Name.text = "[font_size=24][color=" + font_color + "]" + _name + "[/color]\n[/font_size][color=#FF5500]<Corrupted>[/color]"
    else: 
        $Revealed/Name.text = "[font_size=48][color=" + font_color + "]" + _name + "[/color][/font_size]"

func set_disguise(character: CharacterData):
    data.never_disguised = false
    data.disguise = character
    if character == null or data.dead:
        set_portrait(data.character)
    else:
        set_portrait(character)

func set_statement(statement : Statement):
    self.data.statement = statement
    if text_label != null:
        if statement != null:
            text_container.visible = true
            var stmt = statement.get_string().replace("could be: Cabbage", "could be:\na Cabbage")
            text_label.text = stmt
            text_label.visible_ratio = 0.0
        else:
            text_container.visible = false

func set_marker(id, enabled):
    if id < 0 or id > 3:
        return
    get_node("Marker" + str(id + 1)).visible = enabled

func get_marker(id):
    if id < 0 or id > 3:
        return false
    return get_node("Marker" + str(id + 1)).visible

func set_marker_data(id, color, icon):
    if id < 0 or id > 3:
        return
    var marker = get_node("Marker" + str(id + 1))
    marker.self_modulate = color
    marker.get_node("Icon").texture = icon

func get_marker_color(id):
    if id < 0 or id > 3:
        return Color(1, 1, 1)
    var marker = get_node("Marker" + str(id + 1))
    return marker.self_modulate

func get_marker_icon(id):
    if id < 0 or id > 3:
        return null
    var marker = get_node("Marker" + str(id + 1))
    return marker.get_node("Icon").texture

func set_template_marker(template_no : int):
    match template_no:
        1:
            _toggle_marker(0, Color(0.45, 1, 0), null)
        2:
            _toggle_marker(0, Color(1, 0.533, 0), null)
        3:
            _toggle_marker(0, Color(0.96, 0.112, 0), null)
        4:
            _toggle_marker(1, Color(0.01, 0.72, 1.0), load("res://Icons/Exclamation Mark Flat White 256.png"))
        5:
            _toggle_marker(1, Color(0.533, 0, 1), load("res://Icons/Question Mark Flat White 256.png"))
        6:
            _toggle_marker(1, Color(0.2, 0.2, 0.2), load("res://Icons/Skull Flat White 256.png"))
        7:
            _toggle_marker(2, Color(1, 1, 0), load("res://Icons/Star Flat White 256.png"))
        8:
            _toggle_marker(2, Color(1, 0, 1), load("res://Icons/Heart Flat White 256.png"))
        9:
            _toggle_marker(2, Color(0.5, 0, 0), load("res://Icons/Bomb Flat White 256.png"))
        0:
            for i in range(4):
                set_marker(i, false)

func _toggle_marker(id : int, color = null, icon = null):
    if id < 0 or id > 3:
        return
    if get_marker(id) and get_marker_color(id) == color and get_marker_icon(id) == icon:
        set_marker(id, false)
    else:
        set_marker(id, true)
        set_marker_data(id, color, icon)

func blink(t := 2.0):
    blink_time = t

func show_solution(possible_real_roles : Array, could_be_corrupted : bool):
    var text = ""
    var possibly_evil = false
    var always_evil = not could_be_corrupted
    var possibly_corrupted = could_be_corrupted
    var always_lying = true
    var possibly_disguised = false
    var always_disguised = not could_be_corrupted
    if could_be_corrupted and data.character.unknown and not possible_real_roles.has(null):
        possible_real_roles.append(null)
    for role in possible_real_roles:
        if text != "":
            text += "\n"
        if role == null:
            text += "- " + data.character.name + " <U>"
            if data.character.alignment != "Evil":
                always_evil = false
                always_lying = false
            always_disguised = false
        else:
            possibly_disguised = true
            if role.alignment == "Evil":
                possibly_evil = true
            else:
                always_evil = false
            if role.corruption == "Always":
                text += "- " + role.name + " <C>"
                possibly_corrupted = true
            else:
                text += "- " + role.name
                if role.alignment != "Evil":
                    always_lying = false
    if could_be_corrupted:
        if text != "":
            text += "\n"
        text += "- " + data.character.name + " <C>"
    if possible_real_roles.size() > 1 or (could_be_corrupted and possible_real_roles.size() > 0):
        $Sol.text = "This could be:\n" + text
    else:
        $Sol.text = "This is:\n" + text.replace("- ", "")
    if always_evil:
        $Sol.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
    elif possibly_evil and always_lying:
        $Sol.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2))
    elif possibly_evil:
        $Sol.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
    elif possibly_corrupted:
        $Sol.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
    elif always_disguised:
        $Sol.add_theme_color_override("font_color", Color(0.6, 0.8, 0.2))
    elif possibly_disguised:
        $Sol.add_theme_color_override("font_color", Color(0.4, 0.8, 0.2))
    else:
        $Sol.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
    $Sol.visible = true

func hide_solution():
    $Sol.visible = false

func _on_clickable_mouse_entered() -> void:
    hovered = true

func _on_clickable_mouse_exited() -> void:
    hovered = false

func _on_dead_pressed() -> void:
    data.dead = not data.dead
    set_portrait(data.get_visible_character())
    if vscene != null:
        vscene.hide_solution()

func _on_corruption_pressed() -> void:
    data.corrupted = not data.corrupted
    if data.corrupted and data.never_corrupted:
        data.never_corrupted = false
    if data._character != null:
        var font_color = "#FFFFFF"
        if data.character.type == "Outcast":
            font_color = "#FFFF7F"
        elif data.character.type == "Minion":
            font_color = "#FF9933"
        elif data.character.type == "Demon":
            font_color = "#FF3333"
        var _name = data.character.name.to_upper().replace("_", " ")
        if data.corrupted:
            $Revealed/Name.text = "[font_size=24][color=" + font_color + "]" + _name + "[/color]\n[/font_size][color=#FF5500]<Corrupted>[/color]"
        else:
            $Revealed/Name.text = "[font_size=48][color=" + font_color + "]" + _name + "[/color][/font_size]"
    if vscene != null:
        vscene.hide_solution()

func _on_mark_evil_pressed() -> void:
    data.hidden_evil = not data.hidden_evil
    if vscene != null:
        vscene.hide_solution()

func _on_real_pressed() -> void:
    if data.character.disguise == "None":
        data.never_disguised = not data.never_disguised
        if data.disguise != null:
            set_disguise(null)
        if vscene != null:
            vscene.hide_solution()

func _on_uncorrupted_pressed() -> void:
    data.never_corrupted = not data.never_corrupted
    if data.corrupted:
        data.corrupted = false
        if data._character != null:
            var font_color = "#FFFFFF"
            if data.character.type == "Outcast":
                font_color = "#FFFF7F"
            elif data.character.type == "Minion":
                font_color = "#FF9933"
            elif data.character.type == "Demon":
                font_color = "#FF3333"
            var _name = data.character.name.to_upper().replace("_", " ")
            $Revealed/Name.text = "[font_size=48][color=" + font_color + "]" + _name + "[/color][/font_size]"
    if vscene != null:
        vscene.hide_solution()

func _on_reveal_later_pressed() -> void:
    village.move_reveal_later(data)
    if vscene != null:
        vscene.hide_solution()

func _on_reveal_earlier_pressed() -> void:
    village.move_reveal_earlier(data)
    if vscene != null:
        vscene.hide_solution()
