extends CharacterBody2D

const TILE_SIZE: float = 64.0
const MOVE_SPEED: float = 200.0

var target_position: Vector2
var is_moving: bool = false
var current_spell: int = 0

@onready var sprite: Node2D = $Sprite
@onready var aura: ColorRect = $Aura

func _ready() -> void:
	recalculate_stats()
	_update_sprite()

func _physics_process(delta: float) -> void:
	if is_moving:
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		if distance > 5:
			velocity = direction * MOVE_SPEED
			move_and_slide()
			
			if direction.length() > 0:
				if sprite:
					sprite.scale.x = 1 if direction.x >= 0 else -1
		else:
			position = target_position
			velocity = Vector2.ZERO
			is_moving = false
	
	update_aura()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world = get_tree().current_scene
		if world and world.has_node("TileMap"):
			var tile_map = world.get_node("TileMap")
			var mouse_pos = get_global_mouse_position()
			var tile_pos = tile_map.local_to_map(mouse_pos)
			var world_pos = tile_map.map_to_local(tile_pos)
			
			target_position = world_pos
			is_moving = true

func _update_sprite() -> void:
	if not sprite:
		return
	
	for child in sprite.get_children():
		child.queue_free()
	
	var container = Node2D.new()
	container.name = "PlayerSprite"
	
	var robe = ColorRect.new()
	robe.color = Color(0.545, 0.102, 0.102)
	robe.size = Vector2(24, 50)
	robe.position = Vector2(-12, -50)
	container.add_child(robe)
	
	var robe_bottom = ColorRect.new()
	robe_bottom.color = Color(0.4, 0.08, 0.08)
	robe_bottom.size = Vector2(28, 20)
	robe_bottom.position = Vector2(-14, -20)
	container.add_child(robe_bottom)
	
	var torso = ColorRect.new()
	torso.color = Color(0.18, 0.18, 0.22)
	torso.size = Vector2(20, 25)
	torso.position = Vector2(-10, -45)
	container.add_child(torso)
	
	var head = ColorRect.new()
	head.color = Color(0.85, 0.75, 0.65)
	head.size = Vector2(16, 18)
	head.position = Vector2(-8, -63)
	container.add_child(head)
	
	var hair = ColorRect.new()
	hair.color = Color(0.1, 0.08, 0.06)
	hair.size = Vector2(18, 8)
	hair.position = Vector2(-9, -66)
	container.add_child(hair)
	
	var shoulders = ColorRect.new()
	shoulders.color = Color(0.18, 0.18, 0.22)
	shoulders.size = Vector2(28, 8)
	shoulders.position = Vector2(-14, -48)
	container.add_child(shoulders)
	
	var shoulder_l = ColorRect.new()
	shoulder_l.color = Color(0.79, 0.57, 0.17)
	shoulder_l.size = Vector2(6, 6)
	shoulder_l.position = Vector2(-14, -48)
	container.add_child(shoulder_l)
	
	var shoulder_r = ColorRect.new()
	shoulder_r.color = Color(0.79, 0.57, 0.17)
	shoulder_r.size = Vector2(6, 6)
	shoulder_r.position = Vector2(8, -48)
	container.add_child(shoulder_r)
	
	var baton = ColorRect.new()
	baton.color = Color(0.35, 0.25, 0.15)
	baton.size = Vector2(4, 40)
	baton.position = Vector2(14, -40)
	container.add_child(baton)
	
	var baton_top = ColorRect.new()
	baton_top.color = Color(0.79, 0.57, 0.17)
	baton_top.size = Vector2(8, 8)
	baton_top.position = Vector2(12, -44)
	container.add_child(baton_top)
	
	var belt = ColorRect.new()
	belt.color = Color(0.4, 0.08, 0.08)
	belt.size = Vector2(22, 4)
	belt.position = Vector2(-11, -22)
	container.add_child(belt)
	
	var belt_buckle = ColorRect.new()
	belt_buckle.color = Color(0.79, 0.57, 0.17)
	belt_buckle.size = Vector2(6, 4)
	belt_buckle.position = Vector2(-3, -22)
	container.add_child(belt_buckle)
	
	sprite.add_child(container)

func update_aura() -> void:
	var aura_radius = GameManager.get_aura_radius()
	if aura:
		aura.size = Vector2(aura_radius * 16, aura_radius * 16)
		aura.position = Vector2(-aura_radius * 8, -aura_radius * 8)
		aura.modulate = Color(0.306, 0.941, 0.769, 0.25)

func take_damage(amount: int) -> void:
	GameManager.player_stats["health"] -= amount
	
	var hit_effect = create_hit_effect()
	if hit_effect:
		add_child(hit_effect)
	
	if GameManager.player_stats["health"] <= 0:
		GameManager.player_stats["health"] = 0
		die()

func create_hit_effect() -> Node:
	var effect = ColorRect.new()
	effect.color = Color(1, 0, 0, 0.5)
	effect.size = Vector2(40, 60)
	effect.position = Vector2(-20, -60)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)
	
	return effect

func heal(amount: int) -> void:
	GameManager.player_stats["health"] = min(GameManager.player_stats["health"] + amount, GameManager.player_stats["health_max"])

func use_mana(amount: int) -> bool:
	if GameManager.player_stats["mana"] >= amount:
		GameManager.player_stats["mana"] -= amount
		return true
	return false

func regenerate_mana(amount: float) -> void:
	GameManager.player_stats["mana"] = min(GameManager.player_stats["mana"] + amount, GameManager.player_stats["mana_max"])

func recalculate_stats() -> void:
	GameManager.recalculate_stats()
	GameManager.player_stats["health"] = GameManager.player_stats["health_max"]
	GameManager.player_stats["mana"] = GameManager.player_stats["mana_max"]

func die() -> void:
	GameManager.game_state = "dead"
	get_tree().current_scene.show_death_screen()