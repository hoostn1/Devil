extends Node2D

const TILE_SIZE: float = 64.0
const MAP_WIDTH: int = 8
const MAP_HEIGHT: int = 8
var rng: RandomNumberGenerator

var current_room_index: int = 0
var room_level: int = 4
var time_played_seconds: float = 0.0

@onready var tile_map: TileMap = $TileMap
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/HealthBar
@onready var mana_bar: ProgressBar = $CanvasLayer/HUD/ManaBar
@onready var health_label: Label = $CanvasLayer/HUD/HealthLabel
@onready var mana_label: Label = $CanvasLayer/HUD/ManaLabel
@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var shards_label: Label = $CanvasLayer/HUD/ShardsLabel
@onready var room_label: Label = $CanvasLayer/HUD/RoomLabel
@onready var xp_bar: ProgressBar = $CanvasLayer/HUD/XpBar
@onready var player_node: CharacterBody2D = $Player
@onready var skill_ui: CanvasLayer = $SkillUI

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	GameManager._check_skill_unlocks()
	GameManager.game_state = "playing"
	_configure_tile_map()
	if current_room_index >= 4:
		_generate_boss_room()
	else:
		_generate_room()
	_spawn_player()
	update_hud()

func _process(delta: float) -> void:
	if GameManager.game_state == "playing":
		update_hud()
		_player_regen(delta)

func _input(event: InputEvent) -> void:
	if GameManager.game_state != "playing":
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		_move_to_position(mouse_pos)
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q: _cast_spell(0)
			KEY_W: _cast_spell(1)
			KEY_E: _cast_spell(2)
			KEY_R: _cast_spell(3)
			KEY_F: _use_potion(0)
			KEY_G: _use_potion(1)
			KEY_K: skill_ui.call("toggle_skill_ui")
			KEY_I: InventoryUI.call("toggle_inventory")
			KEY_T: _use_portal()
			KEY_ENTER: _go_to_hub()

func _configure_tile_map() -> void:
	tile_map.tile_size = Vector2i(int(TILE_SIZE), int(TILE_SIZE))
	tile_map.rendering_quadrant_size = Vector2i(8, 8)
	tile_map.y_sort_mode = true

func _generate_room() -> void:
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_type = 0
			var roll = rng.randf()
			if roll < 0.60:
				tile_type = 0
			elif roll < 0.85:
				tile_type = rng.randi_range(1, 2)
			elif roll < 0.95:
				tile_type = rng.randi_range(3, 5)
			else:
				tile_type = 6
			
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))
	
	_spawn_enemies()

func _spawn_player() -> void:
	player_node.position = Vector2(TILE_SIZE * 3.5, TILE_SIZE * 5)
	player_node.recalculate_stats()

func _move_to_position(target: Vector2) -> void:
	player_node.target_position = target
	player_node.is_moving = true

func _spawn_enemies() -> void:
	if current_room_index >= 4:
		_spawn_boss()
	else:
		_spawn_regular_enemies()

func _spawn_regular_enemies() -> void:
	var num_enemies = rng.randi_range(2, 5)
	for i in range(num_enemies):
		var enemy = CharacterBody2D.new()
		enemy.name = "Cendrier"
		enemy.add_to_group("enemies")
		
		var sprite = ColorRect.new()
		sprite.name = "Sprite"
		sprite.color = Color(0.102, 0.078, 0.063)
		sprite.size = Vector2(32, 48)
		sprite.position = Vector2(-16, -48)
		enemy.add_child(sprite)
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(32, 48)
		collision.shape = shape
		enemy.add_child(collision)
		
		var random_pos = Vector2(
			rng.randf_range(1, MAP_WIDTH-2) * TILE_SIZE,
			rng.randf_range(1, MAP_HEIGHT-2) * TILE_SIZE
		)
		enemy.position = random_pos
		
		add_child(enemy)

func update_hud() -> void:
	var health_percent = GameManager.get_health_percent()
	var mana_percent = GameManager.get_mana_percent()
	var xp_percent = GameManager.get_xp_percent()
	
	health_bar.value = health_percent
	mana_bar.value = mana_percent
	if xp_bar:
		xp_bar.value = xp_percent
	
	health_label.text = "Santé: %d/%d" % [GameManager.player_stats["health"], GameManager.player_stats["health_max"]]
	mana_label.text = "Mana: %d/%d" % [GameManager.player_stats["mana"], GameManager.player_stats["mana_max"]]
	level_label.text = "Nv. %d" % GameManager.player_stats["level"]]
	shards_label.text = "Éclats: %d" % GameManager.shards
	room_label.text = "Salle: %d" % (current_room_index + 1)

func _player_regen(delta: float) -> void:
	var regen_rate = 1.0 + (float(GameManager.player_stats["energy"]) / 20.0)
	player_node.regenerate_mana(regen_rate * delta)

func _cast_spell(slot: int) -> void:
	match slot:
		0: _fireball()
		1: _ice_shard()
		2: _lightning()

func _fireball() -> void:
	if not player_node.use_mana(5):
		return
	
	var projectile = Area2D.new()
	projectile.name = "Fireball"
	projectile.add_to_group("projectiles")
	
	var sprite = ColorRect.new()
	sprite.color = Color(1, 0.4, 0.1)
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.position = player_node.position
	
	var mouse_pos = get_global_mouse_position()
	projectile.set("direction", (mouse_pos - player_node.position).normalized())
	projectile.set_script(load("res://scripts/projectile.gd"))
	
	add_child(projectile)

func _ice_shard() -> void:
	if not player_node.use_mana(4):
		return
	
	var projectile = Area2D.new()
	projectile.name = "IceShard"
	projectile.add_to_group("projectiles")
	
	var sprite = ColorRect.new()
	sprite.color = Color(0.5, 0.8, 1)
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.position = player_node.position
	
	add_child(projectile)

func _lightning() -> void:
	if not player_node.use_mana(8):
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damage = int(7 * (1.0 + float(GameManager.player_stats["energy"]) / 100.0)
	for i in range(min(3, enemies.size())):
		enemies[i].take_damage(damage)

func _use_potion(slot: int) -> void:
	GameManager.player_stats["mana"] = min(GameManager.player_stats["mana"] + 25, GameManager.player_stats["mana_max"])
	GameManager.player_stats["health"] = min(GameManager.player_stats["health"] + 15, GameManager.player_stats["health_max"])

func show_death_screen() -> void:
	GameManager.game_state = "dead"
	GameManager.lose_shards(int(GameManager.shards * 0.2))
	GameManager.player_stats["health"] = 0
	
	var death_screen = Control.new()
	death_screen.name = "DeathScreen"
	death_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var label = Label.new()
	label.text = "La magie s'éteint... pour l'instant.\n\nÉclats perdus: %d\nXP perdue: 10%%" % int(GameManager.shards * 0.2)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var button = Button.new()
	button.text = "Retourner au hub"
	button.set_anchors_preset(Control.PRESET_CENTER)
	button.position = Vector2(-80, 60)
	button.size = Vector2(160, 40)
	button.pressed.connect(_on_respawn_pressed)
	
	death_screen.add_child(label)
	death_screen.add_child(button)
	$CanvasLayer.add_child(death_screen)

func _on_respawn_pressed() -> void:
	GameManager.player_stats["health"] = GameManager.player_stats["health_max"]
	GameManager.player_stats["mana"] = GameManager.player_stats["mana_max"]
	GameManager.game_state = "playing"
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func show_victory_screen() -> void:
	GameManager.game_state = "victory"
	
	var victory_screen = Control.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_screen.add_child(bg)
	
	var title = Label.new()
	title.text = "GARDIEN VAINCU"
	title.add_theme_font_size_override("font_size", 36)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-150, -150)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.8, 0.2, 0.2)
	victory_screen.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Un gardien de moins. Quatre régions restent sous l'emprise de Devil.\nLa route est longue — mais la magie, elle, ne faiblit pas."
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-250, -80)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_screen.add_child(subtitle)
	
	var stats = Label.new()
	stats.text = "Temps joué: %d min | Salles: %d | Éclats: %d" % [
		int(time_played_seconds / 60),
		current_room_index + 1,
		GameManager.shards
	]
	stats.set_anchors_preset(Control.PRESET_CENTER)
	stats.position = Vector2(-120, 20)
	victory_screen.add_child(stats)
	
	var continue_btn = Button.new()
	continue_btn.text = "Continuer"
	continue_btn.set_anchors_preset(Control.PRESET_CENTER)
	continue_btn.position = Vector2(-60, 100)
	continue_btn.size = Vector2(120, 40)
	continue_btn.pressed.connect(_go_to_hub)
	victory_screen.add_child(continue_btn)
	
	$CanvasLayer.add_child(victory_screen)

func _go_to_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _spawn_boss() -> void:
	var boss = preload("res://scripts/enemies/boss_guardian.gd").new()
	boss.name = "Gardien des Cendres"
	boss.position = Vector2(TILE_SIZE * 4, TILE_SIZE * 4)
	add_child(boss)

func _generate_boss_room() -> void:
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_type = 2
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))
	_spawn_boss()

func _use_portal() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")