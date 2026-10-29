extends TextureRect

@export var grid_size : int = 16

@export var col_1 : Color
@export var col_2 : Color

var remaining : int

var image : Image

var dirty : bool = false

signal canvas_cleared
signal pixel_erased(remaining : int, total : int)


func _ready() -> void:
	canvas_cleared.connect(GameManager.new_grid)

	create_image()
	GameManager.grid_changed.connect(func(size, _n): reset(size))
	reset(GameManager.grid_size)
	
	
func _process(delta: float) -> void:
	if dirty:
		texture.update(image)
		dirty = false

func create_image():
	image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBA8)
	image.fill(col_1)
	texture = ImageTexture.create_from_image(image)

func update_image(x: int, y: int):
	if image.get_pixel(x, y) == col_2:   # already erased
		return

	image.set_pixel(x, y, col_2)
	dirty = true
	remaining -= 1
	GameManager.add_pixels(1)
	pixel_erased.emit(remaining, grid_size * grid_size)
	if remaining == 0:
		canvas_cleared.emit()

func reset(new_size: int) -> void:
	grid_size = new_size
	remaining = grid_size * grid_size
	create_image()
	pixel_erased.emit(remaining, remaining)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = find_pos_in_grid(event.position)
		update_image(cell.x, cell.y)
			

func find_pos_in_grid(pos: Vector2):
	var cell_size := size / grid_size   # separate x/y in case it's not square
	var coords := Vector2i((pos / cell_size).floor())
	return coords.clamp(Vector2i.ZERO, Vector2i(grid_size - 1, grid_size - 1))
