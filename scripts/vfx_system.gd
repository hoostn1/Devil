extends Node

var sfx_enabled: bool = true
var screen_shake_enabled: bool = true
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

var camera: Camera2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		if camera:
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func screen_shake(intensity: float = 5.0, duration: float = 0.2) -> void:
	if not screen_shake_enabled:
		return
	shake_intensity = intensity
	shake_duration = duration

func play_cast_effect(color: Color) -> void:
	var world = get_tree().current_scene
	if not world:
		return
	
	var center = world.player_node.position if has_node("/root/Main/Player") else Vector2(400, 300)
	
	var ring = ColorRect.new()
	ring.color = color
	ring.modulate.a = 0.6
	ring.size = Vector2(20, 20)
	ring.position = center - Vector2(10, 10)
	world.add_child(ring)
	
	var tween = create_tween()
	tween.tween_property(ring, "size", Vector2(80, 80), 0.3)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)

func play_impact_effect(position: Vector2, color: Color) -> void:
	var world = get_tree().current_scene
	if not world:
		return
	
	var particles = Node2D.new()
	particles.position = position
	
	for i in range(6):
		var part = ColorRect.new()
		part.color = color
		part.size = Vector2(6, 6)
		part.position = Vector2.ZERO
		particles.add_child(part)
	
	world.add_child(particles)
	
	var tween = create_tween()
	for i in range(particles.get_child_count()):
		var part = particles.get_child(i)
		var angle = i * TAU / 6
		var offset = Vector2(cos(angle), sin(angle)) * 30
		tween.parallel().tween_property(part, "position", offset, 0.2)
	tween.parallel().tween_property(part, "modulate:a", 0.0, 0.2)
	
	tween.tween_callback(particles.queue_free)

func play_death_effect(position: Vector2) -> void:
	var world = get_tree().current_scene
	if not world:
		return
	
	var fade = ColorRect.new()
	fade.color = Color(0.8, 0.1, 0.1, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	world.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.3, 0.5)
	tween.tween_property(fade, "modulate:a", 0.0, 0.5)
	tween.tween_callback(fade.queue_free)

func set_camera(cam: Camera2D) -> void:
	camera = cam

func flash_screen(color: Color, duration: float = 0.1) -> void:
	var world = get_tree().current_scene
	if not world:
		return
	
	var flash = ColorRect.new()
	flash.color = color
	flash.modulate.a = 0
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	world.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.3, duration)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)

func trigger_screen_shake() -> void:
	screen_shake(8.0, 0.15)

func trigger_enemy_hit() -> void:
	screen_shake(3.0, 0.08)