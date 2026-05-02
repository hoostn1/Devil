class_name BossGuardian extends CharacterBody2D

var enemy_name: String = "Gardien des Cendres"
var health: int = 4704
var health_max: int = 4704
var damage: int = 85
var speed: float = 60.0
var level: int = 4

var phase: int = 1
var max_phase_health: float = 0.7

var is_boss: bool = true
var drops_shards: bool = true
var has_summoned_minions: bool = false

var target: Node2D = null
var state: String = "idle"

var summon_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var phase_changed: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	health = get_base_health()
	health_max = health
	phase = 1
	state = "idle"

func _physics_process(delta: float) -> void:
	if state == "chase" and target:
		var direction = (target.position - position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if position.distance_to(target.position) < 50:
			attack_target()
	
	_update_timers(delta)
	_check_phase()

func _update_timers(delta: float) -> void:
	if summon_cooldown > 0:
		summon_cooldown -= delta
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _check_phase() -> void:
	var health_percent = float(health) / float(health_max)
	
	match phase:
		1:
			if health_percent < max_phase_health:
				phase = 2
				_change_phase()
		2:
			if health_percent < 0.3:
				phase = 3
				_change_phase()

func _change_phase() -> void:
	match phase:
		2:
			state = "enraged"
			speed *= 1.3
			damage = int(damage * 1.2)
			_summon_minions()
		3:
			state = "desperate"
			speed *= 1.5
			damage = int(damage * 1.3)
			_summon_minions()

func _summon_minions() -> void:
	if has_summoned_minions:
		return
	
	has_summoned_minions = true
	
	var world = get_tree().current_scene
	if world:
		for i in range(3):
			var minion = CharacterBody2D.new()
			minion.name = "Cendrier"
			minion.add_to_group("enemies")
			
			var sprite = ColorRect.new()
			sprite.name = "Sprite"
			sprite.color = Color(0.15, 0.1, 0.08)
			sprite.size = Vector2(28, 40)
			sprite.position = Vector2(-14, -40)
			minion.add_child(sprite)
			
			var random_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
			minion.position = position + random_offset
			
			world.add_child(minion)

func get_base_health() -> int:
	return int(30 * level * 1.4 * 20)

func get_damage() -> int:
	return int(5 + level * 3 * 5)

func get_resistance(element: String) -> float:
	match element:
		"fire": return 0.5
		"cold": return 0.25
		"lightning": return 0.0
		"arcane": return 0.0
	return 0.0

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func attack_target() -> void:
	if attack_cooldown <= 0 and target and target.has_method("take_damage"):
		target.take_damage(damage)
		attack_cooldown = 1.5

func die() -> void:
	if drops_shards:
		var shard_drop = randi_range(80, 150)
		GameManager.gain_shards(shard_drop)
	
	var xp_drop = 300 * level
	GameManager.gain_xp(xp_drop)
	
	GameManager.total_rooms_cleared += 1
	
	queue_free()
	get_tree().current_scene.show_victory_screen()

func on_player_detected(player: Node2D) -> void:
	target = player
	state = "chase"

func get_display_info() -> Dictionary:
	return {
		"name": enemy_name,
		"health": health,
		"health_max": health_max,
		"phase": phase,
		"state": state
	}