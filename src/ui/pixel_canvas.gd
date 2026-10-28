extends TextureRect

@export var grid_size : int = 16

@export var col_1 : Color
@export var col_2 : Color

var image : Image

var dirty : bool = false

func _ready() -> void:
	create_image()

func _process(delta: float) -> void:
	if dirty:
		texture.update(image)
		dirty = false

func create_image():
	image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBA8)
	image.fill(col_1)
	texture = ImageTexture.create_from_image(image)

func update_image(x: int, y: int):
	image.set_pixel(x, y, col_2)
	dirty = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = find_pos_in_grid(event.position)
		update_image(cell.x, cell.y)
			

func find_pos_in_grid(pos: Vector2):
	var cell_size := size / grid_size   # separate x/y in case it's not square
	var coords := Vector2i((pos / cell_size).floor())
	return coords.clamp(Vector2i.ZERO, Vector2i(grid_size - 1, grid_size - 1))
