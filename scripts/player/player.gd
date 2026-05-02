extends CharacterBody2D

const TILE_SIZE: float = 64.0
const MOVE_SPEED: float = 200.0

var target_position: Vector2
var is_moving: bool = false
var current_spell: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var aura: Node2D = $Aura

func _ready() -> void:
	recalculate_stats()

func _physics_process(delta: float) -> void:
	if is_moving:
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		if distance > 5:
			velocity = direction * MOVE_SPEED
			move_and_slide()
			
			if direction.length() > 0:
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

func update_aura() -> void:
	var aura_radius = GameManager.get_aura_radius()
	aura.scale = Vector2(aura_radius * 2, aura_radius * 2) / 64.0
	aura.modulate.a = 0.3

func take_damage(amount: int) -> void:
	GameManager.player_stats["health"] -= amount
	if GameManager.player_stats["health"] <= 0:
		GameManager.player_stats["health"] = 0
		die()

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