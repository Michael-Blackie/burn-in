extends Control

@export var canvas: TextureRect

@export var pixel_label : Label
@export var grid_size_label : Label
@export var screen_label : Label
@export var canvas_progress_label : Label
@export var canvas_progress : ProgressBar
@export var pixel_upgrades : ScrollContainer
@export var screen_upgrades : ScrollContainer

const UpgradeButtonScene := preload("res://src/ui/upgrade_button.tscn")
var buttons := {}

func _ready() -> void:	
	GameManager.pixels_changed.connect(_on_pixels_changed)
	GameManager.grid_changed.connect(_on_grid_changed)
	canvas.pixel_erased.connect(_on_pixel_erased)

	build_upgrade_lists()
	refresh_buttons()

func _process(delta: float) -> void:
	refresh_buttons()

func _on_pixels_changed(pixels):
	pixel_label.text = NumFormat.short(pixels)

func _on_grid_changed(size : int, screen_number : int):
	grid_size_label.text = str(size) + " X " + str(size)
	screen_label.text = "SCREEN %02d" % screen_number

func _on_pixel_erased(remaining: int, total: int):
	canvas_progress_label.text = "%s / %s" % [NumFormat.short(remaining), NumFormat.short(total)]
	canvas_progress.max_value = total
	canvas_progress.value = remaining

func build_upgrade_lists() -> void:
	for u in GameManager.all_upgrades:
		var b := UpgradeButtonScene.instantiate()
		var list := pixel_upgrades if u.currency == UpgradeData.Currency.PIXELS else screen_upgrades
		list.add_child(b)
		b.pressed.connect(GameManager.buy.bind(u))
		buttons[u] = b

func refresh_buttons() -> void:
	for u in buttons:
		var b = buttons[u]
		var lvl = GameManager.level_of(u)
		var v = &"UpgradeLocked" if GameManager.screens_cleared < u.requires_screens \
			else (&"UpgradeAffordable" if GameManager.can_buy(u) else &"UpgradeExpensive")
		if b.theme_type_variation != v: b.theme_type_variation = v
		b.setup(u.display_name, u.cost(lvl))
