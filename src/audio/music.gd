extends Node
## Background drone. The track fades to silence at the end (~168s, then ~8s of nothing), so
## instead of looping the file, two players crossfade: shortly before the fade-out, the
## other one starts again from the top.
## Track: "Cinematic Drones Textures 020" by biiansu (Pixabay).

const TRACK := preload("res://assets/audio/music/drones_020.mp3")
const LOOP_END := 168.0                # seconds; the track's own fade-out starts here
const XFADE := 6.0                     # crossfade length
const FIRST_FADE_IN := 2.0

@export var volume_db := -12.0

var _players : Array[AudioStreamPlayer] = []
var _current := 0


func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.stream = TRACK
		add_child(p)
		_players.append(p)
	_start(_players[0], FIRST_FADE_IN)


func _process(_delta: float) -> void:
	var p := _players[_current]
	if p.playing and p.get_playback_position() >= LOOP_END - XFADE:
		_fade(p, 1.0, 0.0).finished.connect(p.stop)
		_current = 1 - _current
		_start(_players[_current], XFADE)


func _start(p: AudioStreamPlayer, fade_in: float) -> void:
	_set_level(0.0, p)
	p.play()
	_fade(p, 0.0, 1.0, fade_in)


# Fades on an equal-power curve, so the crossfade doesn't dip in the middle.
func _fade(p: AudioStreamPlayer, from: float, to: float, time := XFADE) -> Tween:
	var t := create_tween()
	t.tween_method(_set_level.bind(p), from, to, time)
	return t


func _set_level(level: float, p: AudioStreamPlayer) -> void:
	p.volume_db = volume_db + linear_to_db(maxf(sqrt(level), 0.0001))
