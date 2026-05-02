class_name Item extends RefCounted

var id: String = ""
var name: String = ""
var quality: int = 0
var type: String = "weapon"
var slot: String = "main_hand"

var base_stats: Dictionary = {}
var affixes: Array = []
var tags: Array = []

enum Quality {NORMAL = 0, MAGIC = 1, RARE = 2, SET = 3, UNIQUE = 4, RUNEGLYPH = 5}

var quality_colors: Dictionary = {
	0: Color.WHITE,
	1: Color(0.2, 0.6, 1),
	2: Color(1, 0.8, 0.2),
	3: Color(0.2, 0.8, 0.2),
	4: Color(1, 0.85, 0.4),
	5: Color(0.8, 0.8, 0.8)
}

func _init(item_id: String = "", item_quality: int = 0) -> void:
	id = item_id
	quality = item_quality
	_apply_template()

func _apply_template() -> void:
	var templates = _get_templates()
	if templates.has(id):
		var t = templates[id]
		name = t["name"]
		type = t["type"]
		slot = t["slot"]
		base_stats = t.get("stats", {}).duplicate()
		_quality_bonus()

func _quality_bonus() -> void:
	match quality:
		0: pass
		1: _add_magic_affixes(1)
		2: _add_magic_affixes(randi_range(2, 3))
		3: _add_set_bonus()
		4: _add_unique_affixes()

func _add_magic_affixes(count: int) -> void:
	var prefixes = [
		{"name": "de Feu", "stat": "fire_damage", "value": randi_range(3, 8)},
		{"name": "de Givre", "stat": "cold_damage", "value": randi_range(3, 8)},
		{"name": "d'Éclair", "stat": "lightning_damage", "value": randi_range(3, 8)},
		{"name": "Arcane", "stat": "arcane_damage", "value": randi_range(3, 8)},
		{"name": "Puissant", "stat": "damage", "value": randi_range(2, 5)},
		{"name": "Rugissant", "stat": "cast_speed", "value": randi_range(5, 15)},
		{"name": " Énergétique", "stat": "mana", "value": randi_range(10, 25)},
		{"name": "Vital", "stat": "health", "value": randi_range(15, 40)}
	]
	var suffixes = [
		{"name": " du Mage", "stat": "energy", "value": randi_range(1, 4)},
		{"name": " du Sorcier", "stat": "vitality", "value": randi_range(1, 3)},
		{"name": " de l'Archimage", "stat": "dexterity", "value": randi_range(1, 3)},
		{"name": " de Régénération", "stat": "regen", "value": randi_range(5, 15)},
		{"name": " de Richesse", "stat": "magic_find", "value": randi_range(10, 30)}
	]
	
	for i in range(count):
		if randf() < 0.5 and prefixes.size() > 0:
			var p = prefixes.pop_at(0)
			affixes.append({"prefix": true, "name": p["name"], "stat": p["stat"], "value": p["value"]})
		elif suffixes.size() > 0:
			var s = suffixes.pop_at(0)
			affixes.append({"prefix": false, "name": s["name"], "stat": s["stat"], "value": s["value"]})

func _add_set_bonus() -> void:
	_add_magic_affixes(2)
	add_tag("set")

func _add_unique_affixes() -> void:
	var unique_mods = [
		{"stat": "damage", "value": randi_range(10, 20)},
		{"stat": "all_elements", "value": randi_range(15, 30)}
	]
	for m in unique_mods:
		affixes.append({"unique": true, "stat": m["stat"], "value": m["value"]})

func add_tag(tag: String) -> void:
	tags.append(tag)

func get_color() -> Color:
	return quality_colors.get(quality, Color.WHITE)

func get_display_name() -> String:
	var display = name
	for a in affixes:
		if a.has("prefix"):
			display = a["name"] + " " + display
		elif a.has("suffix"):
			display = display + " " + a["name"]
	return display

func get_total_stats() -> Dictionary:
	var stats = base_stats.duplicate()
	for a in affixes:
		if a.has("stat"):
			var s = a["stat"]
			if not stats.has(s):
				stats[s] = 0
			stats[s] += a["value"]
	return stats

func _get_templates() -> Dictionary:
	return {
		"staff_apprentice": {"name": "Bâton de l'Apprenti", "type": "weapon", "slot": "main_hand", "stats": {"damage": 5, "fire_damage": 2}},
		"robe_novice": {"name": "Robe du Novice", "type": "armor", "slot": "body", "stats": {"health": 15, "mana": 5}},
		"belt_leather": {"name": "Ceinture de Cuir Runique", "type": "armor", "slot": "belt", "stats": {}},
		"pendant_arcane": {"name": "Pendentif Arcane", "type": "accessory", "slot": "neck", "stats": {"energy": 3}},
		"ring_start": {"name": "Anneau du Début", "type": "accessory", "slot": "ring", "stats": {"energy": 1, "vitality": 1, "dexterity": 1}},
		"staff_fire": {"name": "Bâton de Feu", "type": "weapon", "slot": "main_hand", "stats": {"damage": 8, "fire_damage": 10}},
		"staff_ice": {"name": "Bâton de Givre", "type": "weapon", "slot": "main_hand", "stats": {"damage": 7, "cold_damage": 8}},
		"robe_mage": {"name": "Robe du Mage", "type": "armor", "slot": "body", "stats": {"health": 30, "mana": 20}},
		"amulet_power": {"name": "Amulette de Puissance", "type": "accessory", "slot": "neck", "stats": {"energy": 5}},
		"ring_mana": {"name": "Anneau de Mana", "type": "accessory", "slot": "ring", "stats": {"mana": 15, "regen": 10}}
	}


class LootSystem:
	
	var treasure_classes: Dictionary = {
		"common": {"drops": ["staff_apprentice", "robe_novice", "belt_leather"], "chance": 0.15},
		"magic": {"drops": ["staff_fire", "staff_ice", "pendant_arcane"], "chance": 0.10},
		"rare": {"drops": ["robe_mage", "amulet_power", "ring_mana"], "chance": 0.03}
	}
	
	func roll_drop(zone_level: int, magic_find: float = 0) -> Item:
		var roll = randf()
		var no_drop = 0.5 / (1.0 + magic_find / 100.0)
		
		if roll < no_drop:
			return null
		
		var quality = _determine_quality(roll, magic_find)
		var tc = _get_treasure_class(zone_level)
		var item_id = tc["drops"].pick_random()
		
		return Item.new(item_id, quality)
	
	func _determine_quality(roll: float, mf: float) -> int:
		var base_chance = 1.0 - (roll * (1.0 + mf / 100.0))
		
		if base_chance < 0.001:
			return 4
		elif base_chance < 0.03:
			return 2
		elif base_chance < 0.10:
			return 1
		return 0
	
	func _get_treasure_class(zone_level: int) -> Dictionary:
		if zone_level < 5:
			return treasure_classes["common"]
		elif zone_level < 15:
			return treasure_classes["magic"]
		return treasure_classes["rare"]