extends OptionButton

func _ready():
    for char_name in Characters.characters.keys():
        var char = Characters.characters[char_name]
        if char.type != "Outcast":
            continue
        add_item(char.name)
        var icon = char.portrait
        if icon == null:
            icon = Characters.missing
        set_item_icon(get_item_count() - 1, icon)
