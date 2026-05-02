extends Node

var player_stats: Dictionary = {
	"level": 1,
	"xp": 0,
	"xp_to_next": 100,
	"health": 50,
	"health_max": 50,
	"mana": 30,
	"mana_max": 30,
	"energy": 10,
	"vitality": 10,
	"dexterity": 10,
	"attribute_points": 0,
	"skill_points": 0
}

var skill_levels: Dictionary = {
	"fireball": 1,
	"ice_shard": 0,
	"chain_lightning": 0,
	"frost_nova": 0,
	"fireball_adv": 0,
	"static_storm": 0,
	"ice_orb": 0,
	"elemental_mastery": 0,
	"meteor": 0,
	"apocalypse": 0
}

var skill_tree_unlocked: Dictionary = {
	"fireball": true,
	"ice_shard": true,
	"chain_lightning": false,
	"frost_nova": false,
	"fireball_adv": false,
	"static_storm": false,
	"ice_orb": false,
	"elemental_mastery": false,
	"meteor": false,
	"apocalypse": false
}

var skill_requirements: Dictionary = {
	"chain_lightning": 6,
	"frost_nova": 6,
	"fireball_adv": 12,
	"static_storm": 12,
	"ice_orb": 18,
	"elemental_mastery": 18,
	"meteor": 24,
	"apocalypse": 30
}

var skill_synergies: Dictionary = {
	"fireball": {"fireball_adv": 0.09, "meteor": 0.12},
	"ice_shard": {"frost_nova": 0.08, "ice_orb": 0.10},
	"fireball_adv": {"fireball": 0, "meteor": 0.15}
}

var inventory: Array = []
var equipped: Dictionary = {}
var current_room: int = 0
var total_rooms_cleared: int = 0
var shards: int = 50
var game_state: String = "title"

var death_count: int = 0

func _ready():
	load_game()

func calculate_xp_to_next(level: int) -> int:
	return int(100 * pow(level, 1.6))

func gain_xp(amount: int) -> void:
	player_stats["xp"] += amount
	while player_stats["xp"] >= player_stats["xp_to_next"]:
		player_stats["xp"] -= player_stats["xp_to_next"]
		player_stats["level"] += 1
		player_stats["attribute_points"] += 5
		player_stats["skill_points"] += 1
		player_stats["xp_to_next"] = calculate_xp_to_next(player_stats["level"])
		_check_skill_unlocks()

func _check_skill_unlocks() -> void:
	for skill_name in skill_requirements:
		if player_stats["level"] >= skill_requirements[skill_name]:
			skill_tree_unlocked[skill_name] = true

func can_upgrade_skill(skill_name: String) -> bool:
	if not skill_tree_unlocked.get(skill_name, false):
		return false
	if skill_levels[skill_name] >= 10:
		return false
	return player_stats["skill_points"] > 0

func upgrade_skill(skill_name: String) -> bool:
	if not can_upgrade_skill(skill_name):
		return false
	skill_levels[skill_name] += 1
	player_stats["skill_points"] -= 1
	return true

func get_skill_damage(skill_name: String, base_damage: int) -> int:
	var level = skill_levels.get(skill_name, 0)
	var bonus = level * 2
	
	var synergy_bonus = 0.0
	if skill_synergies.has(skill_name):
		for linked_skill in skill_synergies[skill_name]:
			var linked_level = skill_levels.get(linked_skill, 0)
			synergy_bonus += skill_synergies[skill_name][linked_skill] * linked_level
	
	return int((base_damage + bonus) * (1.0 + float(player_stats["energy"]) / 100.0 + synergy_bonus))

func can_upgrade_attribute(attr: String) -> bool:
	if not attr in ["energy", "vitality", "dexterity"]:
		return false
	if player_stats["attribute_points"] <= 0:
		return false
	return true

func upgrade_attribute(attr: String) -> bool:
	if not can_upgrade_attribute(attr):
		return false
	player_stats[attr] += 1
	player_stats["attribute_points"] -= 1
	recalculate_stats()
	return true

func gain_shards(amount: int) -> void:
	shards += amount

func lose_shards(amount: int) -> void:
	shards = max(0, int(shards * (1.0 - amount / 100.0)))

func save_game() -> void:
	var save_data = {
		"player_stats": player_stats,
		"skill_levels": skill_levels,
		"shards": shards,
		"current_room": current_room,
		"total_rooms_cleared": total_rooms_cleared,
		"death_count": death_count
	}
	var save_file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_game() -> void:
	if FileAccess.file_exists("user://save_game.json"):
		var save_file = FileAccess.open("user://save_game.json", FileAccess.READ)
		if save_file:
			var json_str = save_file.get_as_string()
			save_file.close()
			var save_data = JSON.parse_string(json_str)
			if save_data:
				player_stats = save_data.get("player_stats", player_stats)
				skill_levels = save_data.get("skill_levels", skill_levels)
				shards = save_data.get("shards", 50)
				current_room = save_data.get("current_room", 0)
				total_rooms_cleared = save_data.get("total_rooms_cleared", 0)
				death_count = save_data.get("death_count", 0)

func reset_game() -> void:
	player_stats = {
		"level": 1,
		"xp": 0,
		"xp_to_next": 100,
		"health": 50,
		"health_max": 50,
		"mana": 30,
		"mana_max": 30,
		"energy": 10,
		"vitality": 10,
		"dexterity": 10,
		"attribute_points": 0,
		"skill_points": 0
	}
	skill_levels = {
		"fireball": 1,
		"ice_shard": 0,
		"chain_lightning": 0,
		"frost_nova": 0,
		"fireball_adv": 0,
		"static_storm": 0,
		"ice_orb": 0,
		"elemental_mastery": 0,
		"meteor": 0,
		"apocalypse": 0
	}
	shards = 50
	current_room = 0
	total_rooms_cleared = 0
	death_count = 0
	save_game()

func get_health_percent() -> float:
	return float(player_stats["health"]) / float(player_stats["health_max"])

func get_mana_percent() -> float:
	return float(player_stats["mana"]) / float(player_stats["mana_max"])

func get_xp_percent() -> float:
	return float(player_stats["xp"]) / float(player_stats["xp_to_next"])

func get_aura_radius() -> int:
	return 3 + int(player_stats["energy"] / 20)

func recalculate_stats() -> void:
	player_stats["health_max"] = 50 + (player_stats["vitality"] * 8)
	player_stats["mana_max"] = 30 + (player_stats["energy"] * 5)

func get_cast_speed() -> float:
	var dex = player_stats["dexterity"]
	var breakpoints = [0, 15, 32, 51, 72, 95, 120, 147, 176, 207]
	var frame_reduction = 0
	for i in range(breakpoints.size()):
		if dex >= breakpoints[i]:
			frame_reduction = i
	return 1.0 - (frame_reduction * 0.05)