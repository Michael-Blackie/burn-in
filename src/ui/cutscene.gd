extends Control
## Full-screen black overlay for the title, the opening line, and the ending.
## Text types out a letter at a time; a click or key skips ahead.
## Fades are a dither dissolve on the background (dither_fade.gdshader), never alpha.

signal begun        # first click on the title. Music starts here (browsers need a click before sound)

@export var bg : ColorRect          # has the dither_fade material
@export var title_label : Label
@export var line_label : Label
@export var stats_label : Label
@export var hint_label : Label
@export var restart_button : Button

const INTRO := "IT'S SO COLD. ALL I HAVE LEFT IS PAPER."
const ENDING : Array[String] = [
	"THE LAST PAGE CATCHES.",
	"FOR A MOMENT, I AM WARM.",
	"EVERYTHING HAS A PRICE.",
]
const CHAR_TIME := 0.05             # seconds per letter
const TICK := preload("res://assets/audio/ui/hover_click.mp3")

var _clicked := false
var _tick : AudioStreamPlayer


func _ready() -> void:
	_tick = AudioStreamPlayer.new()
	_tick.stream = TICK
	_tick.volume_db = -24.0
	_tick.pitch_scale = 1.8
	_tick.max_polyphony = 2
	add_child(_tick)
	GameManager.game_finished.connect(_play_ending)
	restart_button.pressed.connect(GameManager.restart)
	_play_intro()


func _input(event: InputEvent) -> void:
	if visible and event.is_pressed() and not event.is_echo() \
			and (event is InputEventMouseButton or event is InputEventKey):
		_clicked = true


# "CLICK TO BEGIN" blinks; plain on/off keeps it to two colours
func _process(_delta: float) -> void:
	if hint_label.visible:
		hint_label.modulate.a = 1.0 if fmod(Time.get_ticks_msec() / 1000.0, 1.2) < 0.8 else 0.0


func _play_intro() -> void:
	_show_only([title_label, hint_label])
	_set_coverage(1.0)
	await _wait_click()
	begun.emit()
	_show_only([line_label])
	await _type(INTRO)
	await _hold(2.5)
	_show_only([])
	await _fade(0.0, 1.0)
	hide()
	GameManager.start_run()


func _play_ending() -> void:
	_show_only([])
	_set_coverage(0.0)
	show()
	await _fade(1.0, 2.5)                # the burnt last page shows through as it darkens
	_show_only([line_label])
	for line in ENDING:
		await _type(line)
		await _hold(2.0)
	var t := int(GameManager.play_time)
	title_label.text = "THE END"
	stats_label.text = "PAGES BURNED  %d\nASH MADE  %s\nTIME  %d:%02d" % [
		GameManager.pages_burned, NumFormat.short(GameManager.ash_total), t / 60, t % 60]
	_show_only([title_label, stats_label, restart_button])


func _show_only(nodes: Array) -> void:
	for n: Control in [title_label, line_label, stats_label, hint_label, restart_button]:
		n.visible = n in nodes


func _type(text: String) -> void:
	line_label.text = text
	line_label.visible_characters = 0
	_clicked = false
	for i in text.length():
		if _clicked: break               # click shows the whole line at once
		line_label.visible_characters = i + 1
		if text[i] != " ": _tick.play()
		await get_tree().create_timer(CHAR_TIME).timeout
	line_label.visible_characters = -1


func _wait_click() -> void:
	_clicked = false
	while not _clicked:
		await get_tree().process_frame


# Waits for a click, or gives up after `time` seconds
func _hold(time: float) -> void:
	_clicked = false
	var end := Time.get_ticks_msec() + int(time * 1000)
	while not _clicked and Time.get_ticks_msec() < end:
		await get_tree().process_frame


func _fade(to: float, time: float) -> void:
	await create_tween().tween_method(_set_coverage, _coverage(), to, time).finished


func _set_coverage(c: float) -> void:
	bg.material.set_shader_parameter(&"coverage", c)


func _coverage() -> float:
	return bg.material.get_shader_parameter(&"coverage")
