extends Control

@export var canvas: TextureRect

@export var ash_label : Label
@export var ash_rate_label : Label
@export var pages_label : Label
@export var pages_box : Control       # PAGES counter, hidden until the first page is burned
@export var pages_tab : Button
@export var grid_size_label : Label
@export var page_label : Label
@export var canvas_progress_label : Label
@export var canvas_progress : ProgressBar
@export var ash_upgrades : ScrollContainer
@export var page_upgrades : ScrollContainer
@export var tooltip : Control
@export var tooltip_title : Label
@export var tooltip_body : Label

const UpgradeButtonScene := preload("res://src/ui/upgrade_button.tscn")
const LOCKED_NAME := "???"
var buttons := {}
var _hovered : UpgradeData          # upgrade the tooltip is showing, or null
var _hovered_button : Control

signal upgrade_hovered
signal buy_denied        # pressed an upgrade that's locked, maxed or too expensive

func _ready() -> void:
	GameManager.ash_changed.connect(_on_ash_changed)
	GameManager.pages_changed.connect(_on_pages_changed)
	GameManager.upgrades_changed.connect(_update_rate)
	GameManager.grid_changed.connect(_on_grid_changed)
	canvas.pixel_erased.connect(_on_pixel_erased)

	build_upgrade_lists()
	refresh_buttons()
	_on_ash_changed(GameManager.ash)
	_on_pages_changed(GameManager.pages)
	_on_grid_changed(GameManager.current_size(), GameManager.page_index + 1)
	_update_rate()

func _process(delta: float) -> void:
	refresh_buttons()
	if _hovered: _update_tooltip()

func _on_ash_changed(ash):
	ash_label.text = NumFormat.short(ash)

func _on_pages_changed(pages : int):
	pages_label.text = NumFormat.short(pages)
	var unlocked := GameManager.pages_burned > 0
	pages_box.visible = unlocked
	pages_tab.disabled = not unlocked
	pages_tab.text = "PAGES" if unlocked else LOCKED_NAME

# Per click = one cell's worth; per second = auto-burn cells times the same multiplier.
func _update_rate():
	ash_rate_label.text = "%s per click | %s/s" % [
		NumFormat.rate(GameManager.ash_multi),
		NumFormat.rate(GameManager.auto_rate * GameManager.ash_multi)]

# Header: the page's name on the left, its number on the right.
func _on_grid_changed(_size : int, page_number : int):
	page_label.text = GameManager.current_page_name()
	grid_size_label.text = "PAGE %02d" % page_number

func _on_pixel_erased(remaining: int, total: int):
	canvas_progress_label.text = "%s / %s" % [NumFormat.short(remaining), NumFormat.short(total)]
	canvas_progress.max_value = total
	canvas_progress.value = remaining

func build_upgrade_lists() -> void:
	for u in GameManager.all_upgrades:
		var b := UpgradeButtonScene.instantiate()
		var scroll := ash_upgrades if u.currency == UpgradeData.Currency.ASH else page_upgrades
		scroll.get_node("VBoxContainer").add_child(b)
		b.pressed.connect(_on_upgrade_pressed.bind(u))
		b.mouse_entered.connect(upgrade_hovered.emit)
		b.mouse_entered.connect(_show_tooltip.bind(u, b))
		b.mouse_exited.connect(_hide_tooltip.bind(u))
		buttons[u] = b

func _show_tooltip(u: UpgradeData, b: Control) -> void:
	_hovered = u; _hovered_button = b
	_update_tooltip()
	tooltip.show()

func _hide_tooltip(u: UpgradeData) -> void:
	if _hovered == u:
		_hovered = null
		tooltip.hide()

# Runs every frame while shown, so level and "NOW" stay current after a purchase.
func _update_tooltip() -> void:
	var u := _hovered
	var title: String
	var body: String
	if GameManager.is_locked(u):
		title = LOCKED_NAME
		body = "Burn %d page%s to unlock." % [u.requires_pages, "" if u.requires_pages == 1 else "s"]
	else:
		title = u.display_name
		var lines: PackedStringArray = []
		if u.description != "": lines.append(u.description)
		lines.append(u.effect_text() + ("" if u.max_level == 1 else " per level"))
		if u.max_level != 1:   # one-offs already say BOUGHT on the button
			var lvl := GameManager.level_of(u)
			var level := "LEVEL %d" % lvl + ("/%d" % u.max_level if u.max_level > 0 else "")
			if lvl > 0 and u.total_text(lvl) != "": level += "  NOW " + u.total_text(lvl)
			lines.append(level)
		body = "\n".join(lines)
	if tooltip_title.text != title: tooltip_title.text = title
	if tooltip_body.text != body:
		tooltip_body.text = body
		tooltip.reset_size()   # shrink to the new text

	# Left of the side panel, level with the button, kept on screen. Whole pixels only.
	var r := _hovered_button.get_global_rect()
	var y := clampf(r.position.y, 0.0, get_viewport_rect().size.y - tooltip.size.y)
	tooltip.global_position = Vector2(r.position.x - tooltip.size.x - 32, y).round()

func _on_upgrade_pressed(u: UpgradeData) -> void:
	if GameManager.can_buy(u):
		GameManager.buy(u)   # buy sound plays from upgrades_changed
	else:
		buy_denied.emit()

func refresh_buttons() -> void:
	for u in buttons:
		var b = buttons[u]
		var lvl = GameManager.level_of(u)
		var locked := GameManager.is_locked(u)
		var v = &"UpgradeLocked" if locked \
			else (&"UpgradeAffordable" if GameManager.can_buy(u) else &"UpgradeExpensive")
		if b.theme_type_variation != v: b.theme_type_variation = v
		var price := "BOUGHT" if GameManager.is_maxed(u) else NumFormat.short(u.cost(lvl))
		b.setup(LOCKED_NAME if locked else u.display_name, price)
