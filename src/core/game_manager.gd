extends Node

var ash : float = 0
var pages : int = 0

var pages_burned : int = 0
var ash_total : float = 0          # all ash ever made, for the end screen
var play_time : float = 0.0        # seconds of play (intro excluded), for the end screen
var running := false               # false during the intro and after the ending

var ash_multi : float = 1.0
var page_gain : int = 1            # Pages earned per page burned
var brush_size : int = 1
var auto_rate : float = 0.0
var drag_erase : bool = false
var auto_multi : float = 1.0
var ending_bought := false         # "The Deed" bought: the deed, then the last page, come next

# The opening pages, in order. After these, pages come at random from PAGES_96.
const PAGES: Array[Texture2D] = [
	preload("res://assets/pages/shopping_16.png"),
	preload("res://assets/pages/newspaper_32.png"),
	preload("res://assets/pages/letter_48.png"),
	preload("res://assets/pages/diary_64.png"),
]

# Never the same one twice in a row. Most are made by tools/gen_pages.ps1.
const PAGES_96: Array[Texture2D] = [
	preload("res://assets/pages/photo_96.png"),
	preload("res://assets/pages/map_96.png"),
	preload("res://assets/pages/diary2_96.png"),
	preload("res://assets/pages/bill_96.png"),
	preload("res://assets/pages/lost_dog_96.png"),
	preload("res://assets/pages/postcard_96.png"),
	preload("res://assets/pages/recipe_96.png"),
]

# The ending: after "The Deed" is bought, these two come next. Burning the last one ends the game.
const DEED_PAGE := preload("res://assets/pages/deed_96.png")
const LAST_PAGE := preload("res://assets/pages/last_96.png")

# Header names, by image file name
const PAGE_NAMES := {
	"shopping_16": "A SHOPPING LIST", "newspaper_32": "YESTERDAY'S PAPER", "letter_48": "A LETTER",
	"diary_64": "MY DIARY", "photo_96": "A PHOTOGRAPH", "map_96": "THE MAP HOME",
	"diary2_96": "MY DIARY, AGAIN", "bill_96": "THE GAS BILL", "lost_dog_96": "A LOST DOG POSTER",
	"postcard_96": "MUM'S POSTCARD", "recipe_96": "GRAN'S RECIPE",
	"deed_96": "THE DEED TO THE HOUSE", "last_96": "THE LAST PAGE",
}

var _page: Texture2D = PAGES[0]
var page_index := 0

var levels : Dictionary = {}
var all_upgrades : Array[UpgradeData] = []

signal ash_changed(ash : float)
signal pages_changed(pages : int)
signal grid_changed(grid_size : int, page : int)
signal upgrades_changed()
signal game_finished             # the last page has burned


func _ready() -> void:
	# list_directory sees through the .remap files an exported build uses (DirAccess doesn't)
	const DIR := "res://src/data/"
	for file_name in ResourceLoader.list_directory(DIR):
		if file_name.ends_with(".tres"):
			all_upgrades.append(load(DIR + file_name))

	# Button order: earliest unlock first, then cheapest
	all_upgrades.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool:
		if a.requires_pages != b.requires_pages:
			return a.requires_pages < b.requires_pages
		return a.base_cost < b.base_cost)

func _process(delta: float) -> void:
	if running:
		play_time += delta

## Called when the intro ends.
func start_run() -> void:
	running = true

## Back to a fresh game, then reload the scene (the intro plays again).
func restart() -> void:
	ash = 0; pages = 0; pages_burned = 0; ash_total = 0; play_time = 0.0; running = false
	page_index = 0; _page = PAGES[0]
	levels.clear()
	recalc_stats()
	get_tree().reload_current_scene()

# Ash methods
func add_ash(amount : float):
	ash += amount * ash_multi
	ash_total += amount * ash_multi
	ash_changed.emit(ash)

func remove_ash(amount : float):
	if amount <= ash:
		ash -= amount
		ash_changed.emit(ash)
		return true
	else:
		return false

func add_pages(amount : int):
	pages += amount
	pages_changed.emit(pages)

func remove_pages(amount : int):
	if amount <= pages:
		pages -= amount
		pages_changed.emit(pages)
		return true
	else:
		return false

# Grid methods
func new_grid() -> void:
	pages_burned += 1                  # before add_pages: the UI unlocks the Pages tab from it
	add_pages(page_gain)
	if _page == LAST_PAGE:
		running = false
		game_finished.emit()
		return
	page_index += 1
	_page = _next_page()
	grid_changed.emit(current_size(), page_index + 1)


# Upgrade methods
func level_of(u: UpgradeData) -> int:
	return levels.get(u.id, 0)

func is_locked(u: UpgradeData) -> bool:
	return pages_burned < u.requires_pages

func is_maxed(u: UpgradeData) -> bool:
	return u.max_level > 0 and level_of(u) >= u.max_level

func can_buy(u: UpgradeData) -> bool:
	if is_locked(u) or is_maxed(u):
		return false
	var lvl := level_of(u)

	var wallet : float
	if u.currency == UpgradeData.Currency.ASH:
		wallet = ash
	else:
		wallet = pages

	return wallet >= u.cost(lvl)

func buy(u: UpgradeData) -> void:
	if not can_buy(u):
		return
	var price := u.cost(level_of(u))
	if u.currency == UpgradeData.Currency.ASH:
		remove_ash(price)
	else:
		remove_pages(int(price))
	levels[u.id] = level_of(u) + 1
	recalc_stats()
	upgrades_changed.emit()

func recalc_stats() -> void:
	ash_multi = 1.0; brush_size = 1; auto_rate = 0.0; drag_erase = false; auto_multi = 1.0
	page_gain = 1; ending_bought = false
	var ash_factor := 1.0   # multiplicative bonuses, applied after the additive ones
	for u in all_upgrades:   # Array[UpgradeData], e.g. preloaded from src/data
		var lvl := level_of(u)
		match u.stat:
			UpgradeData.Stat.ASH_MULTI: ash_multi += u.value_per_level * lvl
			UpgradeData.Stat.BRUSH_SIZE: brush_size  += int(u.value_per_level) * lvl
			UpgradeData.Stat.AUTO_RATE: auto_rate   += u.value_per_level * lvl
			UpgradeData.Stat.DRAG_ERASE: drag_erase = lvl > 0
			UpgradeData.Stat.ASH_FACTOR: ash_factor *= pow(u.value_per_level, lvl)
			UpgradeData.Stat.AUTO_MULTI: auto_multi *= pow(u.value_per_level, lvl)
			UpgradeData.Stat.END_GAME: ending_bought = ending_bought or lvl > 0
			UpgradeData.Stat.PAGE_GAIN: page_gain += int(u.value_per_level) * lvl
	ash_multi *= ash_factor
	auto_rate *= auto_multi


func current_page() -> Texture2D:
	return _page

func current_page_name() -> String:
	return PAGE_NAMES.get(_page.resource_path.get_file().get_basename(), "A PAGE")

func _next_page() -> Texture2D:
	if ending_bought:
		return LAST_PAGE if _page == DEED_PAGE else DEED_PAGE
	if page_index < PAGES.size():
		return PAGES[page_index]
	var pick := _page
	while pick == _page:   # reroll repeats; needs at least 2 pages in PAGES_96
		pick = PAGES_96.pick_random()
	return pick

func current_size() -> int:
	return _page.get_width()
