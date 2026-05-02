class_name Spell extends RefCounted

var spell_name: String = ""
var damage: int = 10
var mana_cost: int = 5
var cooldown: float = 0.0
var element: String = "fire"
var level: int = 1
var range: float = 200.0

func _init() -> void:
	pass

func get_damage() -> int:
	return (damage + level * 2) * int(1.0 + float(GameManager.player_stats["energy"]) / 100.0)

func can_cast(caster: Node2D) -> bool:
	return GameManager.player_stats["mana"] >= mana_cost

func cast(caster: Node2D) -> void:
	pass

func apply_effect(target: Node2D) -> void:
	target.take_damage(get_damage())


class Fireball extends Spell:
	func _init() -> void:
		spell_name = "Trait de feu"
		damage = 8
		mana_cost = 5
		element = "fire"
	
	func cast(caster: Node2D) -> void:
		if not can_cast(caster):
			return
		
		caster.use_mana(mana_cost)
		
		var projectile = preload("res://scripts/spells/fireball.tscn").instantiate()
		projectile.position = caster.position
		projectile.direction = caster.get_global_mouse_position() - caster.position
		projectile.damage = get_damage()
		projectile.element = element
		caster.get_tree().current_scene.add_child(projectile)


class IceShard extends Spell:
	var slow_duration: float = 2.0
	
	func _init() -> void:
		spell_name = "Éclat de glace"
		damage = 6
		mana_cost = 4
		element = "cold"
	
	func cast(caster: Node2D) -> void:
		if not can_cast(caster):
			return
		
		caster.use_mana(mana_cost)
		
		var projectile = preload("res://scripts/spells/ice_shard.tscn").instantiate()
		projectile.position = caster.position
		projectile.direction = caster.get_global_mouse_position() - caster.position
		projectile.damage = get_damage()
		projectile.element = element
		projectile.slow_duration = slow_duration
		caster.get_tree().current_scene.add_child(projectile)


class LightningChain extends Spell:
	var bounces: int = 3
	
	func _init() -> void:
		spell_name = "Éclair en chaîne"
		damage = 5
		mana_cost = 8
		element = "lightning"
	
	func cast(caster: Node2D) -> void:
		if not can_cast(caster):
			return
		
		caster.use_mana(mana_cost)
		
		var enemies = caster.get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			var target = enemies[0]
			target.take_damage(get_damage())
			apply_bounces(caster, target, bounces - 1)

func apply_bounces(caster: Node2D, last_target: Node2D, bounces_remaining: int) -> void:
	if bounces_remaining <= 0:
		return
	
	var enemies = caster.get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = INF
	
	for enemy in enemies:
		if enemy == last_target:
			continue
		var dist = enemy.position.distance_to(last_target.position)
		if dist < closest_dist and dist < range:
			closest = enemy
			closest_dist = dist
	
	if closest:
		closest.take_damage(get_damage() * 70 / 100)
		apply_bounces(caster, closest, bounces_remaining - 1)