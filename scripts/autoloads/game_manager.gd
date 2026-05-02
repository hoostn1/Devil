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

var inventory: Array = []
var equipped: Dictionary = {}
var current_room: int = 0
var total_rooms_cleared: int = 0

var shards: int = 50

var game_state: String = "title"

func _ready():
	load_game()

func gain_xp(amount: int) -> void:
	player_stats["xp"] += amount
	while player_stats["xp"] >= player_stats["xp_to_next"]:
		player_stats["xp"] -= player_stats["xp_to_next"]
		player_stats["level"] += 1
		player_stats["attribute_points"] += 5
		player_stats["skill_points"] += 1
		player_stats["xp_to_next"] = int(100 * pow(player_stats["level"], 1.6))

func gain_shards(amount: int) -> void:
	shards += amount

func lose_shards(amount: int) -> void:
	shards = max(0, shards - amount)

func save_game() -> void:
	var save_data = {
		"player_stats": player_stats,
		"shards": shards,
		"current_room": current_room,
		"total_rooms_cleared": total_rooms_cleared
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
				shards = save_data.get("shards", 50)
				current_room = save_data.get("current_room", 0)
				total_rooms_cleared = save_data.get("total_rooms_cleared", 0)

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
	shards = 50
	current_room = 0
	total_rooms_cleared = 0
	save_game()

func get_health_percent() -> float:
	return float(player_stats["health"]) / float(player_stats["health_max"])

func get_mana_percent() -> float:
	return float(player_stats["mana"]) / float(player_stats["mana_max"])

func get_aura_radius() -> int:
	return 3 + int(player_stats["energy"] / 20)

func recalculate_stats() -> void:
	player_stats["health_max"] = 50 + (player_stats["vitality"] * 8)
	player_stats["mana_max"] = 30 + (player_stats["energy"] * 5)