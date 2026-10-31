extends TextureRect
## Draws a page as data: R = how burnt a cell is (0..1), G = 1 if the cell is ink.
## The burn.gdshader material turns that into the dithered 1-bit look.

var grid_size : int

var alive : PackedInt32Array
var slot : PackedInt32Array

# Unburnt paper cells touching a burnt one. Auto-burn picks from here so holes spread.
var edge : PackedInt32Array
var edge_slot : PackedInt32Array   # cell index -> position in edge, or -1
const NEW_HOLE_CHANCE := 0.01       # chance an auto-burn starts a fresh hole instead

var total_paper : int = 0
var dirty : bool = false
var _cleared : bool = false
var _acc : float = 0.0

var image : Image

const BURN_TIME := 0.6
var burning : PackedInt32Array
var burn_t : PackedFloat32Array

signal canvas_cleared
signal pixel_erased(remaining : int, total : int)


func _ready() -> void:
	canvas_cleared.connect(GameManager.new_grid)
	GameManager.grid_changed.connect(func(_size, _n): reset())
	reset()


func _process(delta: float) -> void:
	# Handle auto clickers
	_acc += GameManager.auto_rate * delta
	var n := int(_acc)
	if n > 0 and not _cleared:
		var erased := burn_spread(n)
		_acc -= erased                     # what wasn't used carries over to the next grid
		if erased > 0:
			GameManager.add_ash(erased)
			pixel_erased.emit(alive.size(), total_paper)
		check_cleared()

	_update_burning(delta)

	# Upload changes once per frame
	if dirty:
		texture.update(image)
		dirty = false


func update_image(x: int, y: int):
	if _cleared or not erase_index(y * grid_size + x):   # ink, or already burning
		return
	GameManager.add_ash(1)
	pixel_erased.emit(alive.size(), total_paper)
	check_cleared()


func reset() -> void:
	var page: Image = GameManager.current_page().get_image()   # a copy, safe to read
	page.convert(Image.FORMAT_RGBA8)                      # imported images may not be RGBA8
	grid_size = page.get_width()
	var total := grid_size * grid_size

	image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBA8)
	alive.clear(); slot.resize(total)
	edge.clear(); edge_slot.resize(total); edge_slot.fill(-1)
	burning.clear(); burn_t.clear()

	for i in total:
		var x := i % grid_size; var y := i / grid_size
		var paper := page.get_pixel(x, y).r > 0.5
		image.set_pixel(x, y, Color(0.0, 0.0 if paper else 1.0, 0.0))   # unburnt paper, or ink
		if paper:
			slot[i] = alive.size(); alive.append(i)
		else:
			slot[i] = -1                                  # ink can never be burnt

	total_paper = alive.size()
	texture = ImageTexture.create_from_image(image)      # new size means a new texture
	_cleared = false
	pixel_erased.emit(alive.size(), total_paper)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = find_pos_in_grid(event.position)
		update_image(cell.x, cell.y)


func find_pos_in_grid(pos: Vector2):
	var cell_size := size / grid_size   # separate x/y in case it's not square
	var coords := Vector2i((pos / cell_size).floor())
	return coords.clamp(Vector2i.ZERO, Vector2i(grid_size - 1, grid_size - 1))


## Takes a cell out of play and starts it burning. False if it's ink or already gone.
func erase_index(i: int) -> bool:
	var s := slot[i]
	if s == -1:
		return false

	var last := alive[alive.size() - 1]
	alive[s] = last                   # move the last entry into the gap
	slot[last] = s                    # tell it where it lives now
	alive.resize(alive.size() - 1)    # drop the old last entry
	slot[i] = -1

	# This cell is no longer an edge; its unburnt neighbours now are.
	_edge_remove(i)
	var x := i % grid_size
	if x > 0: _edge_add(i - 1)
	if x < grid_size - 1: _edge_add(i + 1)
	if i >= grid_size: _edge_add(i - grid_size)
	if i < grid_size * (grid_size - 1): _edge_add(i + grid_size)

	burning.append(i); burn_t.append(0.0)
	return true


## Auto-burn: grows existing holes outward, occasionally starting a new one.
func burn_spread(n: int) -> int:
	var erased := 0
	while erased < n and alive.size() > 0:
		var pick: int
		if edge.is_empty() or randf() < NEW_HOLE_CHANCE:
			pick = alive[randi() % alive.size()]   # start a new hole
		else:
			pick = edge[randi() % edge.size()]     # spread an existing one
		erase_index(pick)
		erased += 1
	return erased


func _edge_add(i: int) -> void:
	if slot[i] == -1 or edge_slot[i] != -1:   # ink, already burnt, or already an edge
		return
	edge_slot[i] = edge.size()
	edge.append(i)


func _edge_remove(i: int) -> void:
	var s := edge_slot[i]
	if s == -1:
		return
	var last := edge[edge.size() - 1]
	edge[s] = last
	edge_slot[last] = s
	edge.resize(edge.size() - 1)
	edge_slot[i] = -1


func check_cleared():
	if alive.is_empty() and not _cleared:
		_cleared = true
		while burning.size() > 0: await get_tree().process_frame   # let the last cells finish
		await get_tree().create_timer(1.0).timeout                  # hold on the burnt page
		canvas_cleared.emit()


## Raises each burning cell's R from 0 to 1; the shader draws it as denser and denser dither.
func _update_burning(delta: float) -> void:
	var k := burning.size() - 1
	while k >= 0:                                   # go backwards so swap-remove is safe
		burn_t[k] += delta
		var i := burning[k]
		var amount := minf(burn_t[k] / BURN_TIME, 1.0)
		image.set_pixel(i % grid_size, i / grid_size, Color(amount, 0.0, 0.0))
		if amount >= 1.0:                           # finished: drop it from the list
			burning[k] = burning[-1]; burn_t[k] = burn_t[-1]
			burning.resize(burning.size() - 1); burn_t.resize(burn_t.size() - 1)
		k -= 1
	if burning.size() > 0:
		dirty = true
