extends Node
## UI sounds: one click (Zapsplat "menu click 003") for hover, pitched down and louder for buy,
## pitched up and louder for deny; and a deep whoosh when a new page arrives (a torch whoosh pitched down).

@export var ui : Control

const CLICK := preload("res://assets/audio/ui/hover_click.mp3")
const PAGE := preload("res://assets/audio/sfx/torch_2.wav")

var _hover : AudioStreamPlayer
var _buy : AudioStreamPlayer
var _deny : AudioStreamPlayer
var _page : AudioStreamPlayer


func _ready() -> void:
	_hover = _make_player(CLICK, -20.0, 1.06)
	_buy = _make_player(CLICK, -10.0, 1.0)
	_buy.pitch_scale = 0.7              # deeper "clunk" for a purchase
	_deny = _make_player(CLICK, -12.0, 1.0)
	_deny.pitch_scale = 1.5             # higher "tick" for can't buy
	_page = _make_player(PAGE, -6.0, 1.0)
	_page.pitch_scale = 0.6             # slower and deeper than a burn

	ui.upgrade_hovered.connect(_hover.play)
	ui.buy_denied.connect(_deny.play)
	GameManager.upgrades_changed.connect(_buy.play)
	GameManager.grid_changed.connect(func(_size, _n): _page.play())


# pitch_range 1.0 = no variation; 1.06 = up to about a semitone either way.
func _make_player(stream: AudioStream, db: float, pitch_range: float) -> AudioStreamPlayer:
	var r := AudioStreamRandomizer.new()
	r.add_stream(-1, stream)
	r.random_pitch = pitch_range
	var p := AudioStreamPlayer.new()
	p.stream = r
	p.volume_db = db
	p.max_polyphony = 3
	add_child(p)
	return p
