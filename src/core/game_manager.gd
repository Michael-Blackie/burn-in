extends Node

var ash : float = 0
var pages : int = 0

var pages_burned : int = 0

var ash_multi : float = 1.0
var page_multi : int = 0
var brush_size : int = 1
var auto_rate : float = 0.0
var drag_erase : bool = false

const PAGES: Array[Texture2D] = [
	preload("res://assets/pages/shopping_16.png"),
	preload("res://assets/pages/newspaper_32.png"),
	preload("res://assets/pages/letter_48.png"),
	preload("res://assets/pages/diary_64.png"),
	preload("res://assets/pages/photo_96.png"),
	preload("res://assets/pages/map_96.png"),
]

const BLANK_SIZES : Array[int] = [16, 32, 48, 64, 96, 96]
var grid_size : int = 16

var page_index := 0

var levels : Dictionary = {} 
var all_upgrades : Array[UpgradeData] = []

signal ash_changed(ash : float)
signal pages_changed(pages : int)
signal grid_changed(grid_size : int, page : int)
signal upgrades_changed()


func _ready() -> void:
	var directory_path = "res://src/data/"
	var files = DirAccess.get_files_at(directory_path)

	for file_name in files:
		if file_name.get_extension() == "tres":
			all_upgrades.append(load(directory_path + file_name))
			print(all_upgrades)

# Ash methods
func add_ash(amount : float):
	ash += amount * ash_multi
	ash_changed.emit(ash)

func remove_ash(amount : float):
	if amount <= ash:
		ash -= amount
		ash_changed.emit(ash)
		return true
	else:
		return false

func add_pages(amount : int):
	pages += amount * page_multi
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
	pages += 1; pages_burned += 1
	page_index += 1
	grid_changed.emit(current_size(), page_index + 1)


# Upgrade methods
func level_of(u: UpgradeData) -> int:
	return levels.get(u.id, 0)

func can_buy(u: UpgradeData) -> bool:
	var lvl := level_of(u)
	if u.max_level > 0 and lvl >= u.max_level:
		return false
	
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
	ash_multi = 1.0; brush_size = 1; auto_rate = 0.0; drag_erase = false
	for u in all_upgrades:   # Array[UpgradeData], e.g. preloaded from src/data
		var lvl := level_of(u)
		match u.stat:
			UpgradeData.Stat.ASH_MULTI: ash_multi += u.value_per_level * lvl
			UpgradeData.Stat.BRUSH_SIZE:  brush_size  += int(u.value_per_level) * lvl
			UpgradeData.Stat.AUTO_RATE:   auto_rate   += u.value_per_level * lvl
			UpgradeData.Stat.DRAG_ERASE:  drag_erase = lvl > 0

func current_page() -> Texture2D:
	return PAGES[mini(page_index, PAGES.size() - 1)]

func current_size() -> int:
	var tex := current_page()
	return tex.get_width() if tex else BLANK_SIZES[mini(page_index, BLANK_SIZES.size() - 1)]