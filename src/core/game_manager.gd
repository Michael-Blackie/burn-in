extends Node

var pixels : float = 0
var pixel_multi : float = 1.0;

signal pixels_changed

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