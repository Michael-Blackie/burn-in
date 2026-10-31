extends Node
## Flame puff for burnt cells. Player burns always play (with a tiny gap so drags don't spam);
## auto-burn is rate-capped with jitter, so a big auto rate becomes a steady fire, not noise.
## Sounds are five whooshes cut from "waving torch" (freesound_community, Pixabay).

@export var canvas : TextureRect
@export var max_auto_per_sec := 8.0    # most auto-burn sounds per second (each is ~0.6s, so they overlap)
@export var player_gap := 0.06         # least time between player sounds

const CLICK_DB := -16.0
const AUTO_DB := -20.0                 # quieter, it rises with auto_rate up to +6 dB

const WHOOSHES : Array[AudioStream] = [
	preload("res://assets/audio/sfx/torch_0.wav"),
	preload("res://assets/audio/sfx/torch_1.wav"),
	preload("res://assets/audio/sfx/torch_2.wav"),
	preload("res://assets/audio/sfx/torch_3.wav"),
	preload("res://assets/audio/sfx/torch_4.wav"),
]

var _click : AudioStreamPlayer
var _auto : AudioStreamPlayer
var _click_cd := 0.0
var _auto_cd := 0.0


func _ready() -> void:
	canvas.burned.connect(_on_burned)
	_click = _make_player(CLICK_DB, 4)
	_auto = _make_player(AUTO_DB, 8)


func _process(delta: float) -> void:
	_click_cd -= delta
	_auto_cd -= delta


# A random variant each play, never the same twice in a row, at a random pitch and volume.
func _make_player(db: float, voices: int) -> AudioStreamPlayer:
	var r := AudioStreamRandomizer.new()
	for s in WHOOSHES: r.add_stream(-1, s)
	r.random_pitch = 1.2                # 1/1.2x .. 1.2x speed
	r.random_volume_offset_db = 3.0
	var p := AudioStreamPlayer.new()
	p.stream = r
	p.volume_db = db
	p.max_polyphony = voices            # oldest voice is cut when they all play
	add_child(p)
	return p


func _on_burned(_count: int, by_player: bool) -> void:
	if by_player:
		if _click_cd > 0.0: return
		_click_cd = player_gap
		_click.play()
	else:
		if _auto_cd > 0.0: return
		_auto_cd = randf_range(0.5, 1.5) / max_auto_per_sec   # jitter so the cap isn't a metronome
		var heat := clampf(log(GameManager.auto_rate) / log(500.0), 0.0, 1.0)   # 1/s -> 0, 500/s -> 1
		_auto.volume_db = AUTO_DB + 6.0 * heat
		_auto.play()
