extends Node

var pixels : float = 0
var pixel_multi : float = 1.0;

signal pixels_changed

func _ready() -> void:
	var font: FontFile = load("res://fonts/VT323-Regular.ttf")
	font.fixed_size = 16  # the native size you found
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY

func add_pixels(amount : int):
	pixels += amount * pixel_multi
	pixels_changed.emit(pixels)

func remove_pixels(amount : int):
	if amount <= pixels:
		pixels -= amount
		pixels_changed.emit(pixels)
		return true
	else:
		return false