class_name Enemy extends CharacterBody2D

var enemy_name: String = "Cendrier"
var health: int = 30
var health_max: int = 30
var damage: int = 5
var speed: float = 80.0
var level: int = 4

var resistances: Dictionary = {
	"fire": 0.5,
	"cold": 0.0,
	"lightning": 0.0,
	"arcane": 0.0
}

var is_elite: bool = false
var is_boss: bool = false
var drops_shards: bool = true

var state: String = "idle"
var target: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	health = get_base_health()
	health_max = health

func _physics_process(delta: float) -> void:
	if state == "chase" and target:
		var direction = (target.position - position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if position.distance_to(target.position) < 30:
			attack_target()

func get_base_health() -> int:
	return int(30 * level * 1.4)

func get_damage() -> int:
	return int(5 + level * 3)

func get_resistance(element: String) -> float:
	return resistances.get(element, 0.0)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func attack_target() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

func die() -> void:
	if drops_shards:
		var shard_drop = RandomNumberGenerator.new().randi_range(1, 5)
		GameManager.gain_shards(shard_drop)
	
	var xp_drop = 10 * level
	GameManager.gain_xp(xp_drop)
	
	if randf() < 0.15:
		var LootSystem = preload("res://scripts/loot_system.gd")
		var loot = LootSystem.LootSystem.new().roll_drop(level)
		if loot:
			InventoryUI.call("add_item", loot)
	
	queue_free()

func on_player_detected(player: Node2D) -> void:
	target = player
	state = "chase"


class Cendrier extends Enemy:
	func _init() -> void:
		enemy_name = "Cendrier"
		level = 4
		resistances = {"fire": 0.5, "cold": 0.0, "lightning": 0.0, "arcane": 0.0}
		health = get_base_health()
		damage = get_damage()


class VoileDeCendre extends Enemy:
	func _init() -> void:
		enemy_name = "Voile de cendre"
		level = 4
		resistances = {"fire": 0.5, "cold": -0.2, "lightning": 0.0, "arcane": 0.0}
		speed = 50.0
		health = get_base_health()
		damage = get_damage() - 2


class GolemDeScories extends Enemy:
	func _init() -> void:
		enemy_name = "Golem de scories"
		level = 4
		resistances = {"fire": 0.75, "cold": 0.0, "lightning": 0.0, "arcane": 0.0}
		speed = 40.0
		is_elite = true
		health = get_base_health() * 4
		damage = get_damage() * 2.5