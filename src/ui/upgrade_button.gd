extends Button

@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel


func _ready() -> void:
	_sync_label_colours()


# Fires whenever theme_type_variation changes (e.g. Affordable -> Expensive).
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_sync_label_colours()


func setup(upgrade_name: String, cost: int) -> void:
	name_label.text = upgrade_name
	price_label.text = str(cost)


# Labels use the Label theme type, not the Button's font colours,
# so copy the current variation's font colour onto them.
# Locked buttons also give the labels a solid black box over the hatching.
func _sync_label_colours() -> void:
	var c := get_theme_color(&"font_color")
	var locked := theme_type_variation == &"UpgradeLocked"
	for l: Label in [name_label, price_label]:
		l.theme_type_variation = &"UpgradeLabelLocked" if locked else &"UpgradeLabel"
		l.add_theme_color_override(&"font_color", c)
