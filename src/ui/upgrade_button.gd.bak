extends Button

func setup(upgrade_name: String, cost: int) -> void:
	$HBoxContainer/NameLabel.text = upgrade_name
	$HBoxContainer/PriceLabel.text = str(cost)

func set_text_color(c: Color) -> void:
	for l in [$HBoxContainer/NameLabel, $HBoxContainer/PriceLabel]:
		l.add_theme_color_override("font_color", c)