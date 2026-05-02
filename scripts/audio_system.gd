extends Node

var sfx_enabled: bool = true
var volume: float = 0.7

var sounds: Dictionary = {}

func _ready() -> void:
	pass

func play_sound(sound_name: String, volume_mod: float = 1.0) -> void:
	if not sfx_enabled:
		return
	
	match sound_name:
		"fire_cast":
			_play_tone(440, 0.1, 0.3 * volume_mod)
		"ice_cast":
			_play_tone(523, 0.15, 0.25 * volume_mod)
		"lightning_cast":
			_play_tone(660, 0.1, 0.4 * volume_mod)
		"hit":
			_play_tone(110, 0.05, 0.5 * volume_mod)
		"enemy_death":
			_play_tone(80, 0.2, 0.4 * volume_mod)
		"player_death":
			_play_tone(60, 0.5, 0.5 * volume_mod)
		"level_up":
			_play_tone(523, 0.1, 0.0)
			_play_tone(659, 0.1, 0.0)
			_play_tone(784, 0.15, 0.0)
		"pickup":
			_play_tone(880, 0.08, 0.3 * volume_mod)
		"potion":
			_play_tone(700, 0.1, 0.3 * volume_mod)
		"ui_click":
			_play_tone(1000, 0.03, 0.2 * volume_mod)
		"boss_summon":
			_play_tone(110, 0.3, 0.6 * volume_mod)
			_play_tone(165, 0.3, 0.5 * volume_mod)

func _play_tone(freq: float, duration: float, volume_mod: float = 0.5) -> void:
	var oscillator = AudioStreamPlayer.new()
	oscillator.volume_db = linear_to_db(volume * volume_mod)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.playback = stream.generate_stream_buffer()
	
	oscillator.stream = stream
	oscillator.position = Vector3(freq, 0, 0)
	
	add_child(oscillator)
	oscillator.play()
	
	get_tree().create_timer(duration).timeout.connect(func():
		oscillator.stop()
		oscillator.queue_free()
	)

func set_volume(v: float) -> void:
	volume = clamp(v, 0.0, 1.0)

func toggle_sfx() -> void:
	sfx_enabled = !sfx_enabled