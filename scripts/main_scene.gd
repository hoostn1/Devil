extends Node2D

const TILE_SIZE: float = 64.0

@onready var tile_map: TileMap = $TileMap
@onready var player_node: CharacterBody2D = $Player
@onready var mini_map: ColorRect = $CanvasLayer/HUD/MiniMap

var current_room_index: int = 0
var room_level: int = 4
var time_played_seconds: float = 0.0
var rng: RandomNumberGenerator
var explored_rooms: Array = []

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	time_played_seconds = 0.0
	GameManager._check_skill_unlocks()
	GameManager.game_state = "playing"
	_configure_tile_map()
	_generate_room()
	_spawn_player()
	update_hud()

func _process(delta: float) -> void:
	if GameManager.game_state == "playing":
		update_hud()
		_player_regen(delta)
		time_played_seconds += delta
		_update_mini_map()

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
			KEY_K: SkillUI.call("toggle_skill_ui")
			KEY_I: InventoryUI.call("toggle_inventory")
			KEY_T: _use_portal()
			KEY_ENTER: _go_to_hub()

func _configure_tile_map() -> void:
	tile_map.tile_size = Vector2i(int(TILE_SIZE), int(TILE_SIZE))
	tile_map.rendering_quadrant_size = Vector2i(8, 8)
	tile_map.y_sort_mode = true

func _generate_room() -> void:
	for x in range(8):
		for y in range(8):
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
		_spawn_cendrier()

func _spawn_cendrier() -> void:
	var enemy = CharacterBody2D.new()
	enemy.name = "Cendrier"
	enemy.add_to_group("enemies")
	enemy.set_script(load("res://scripts/enemies/enemy.gd"))
	
	var sprite = _create_enemy_sprite("cendrier")
	enemy.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	enemy.add_child(collision)
	
	var random_pos = Vector2(
		rng.randf_range(1, 6) * TILE_SIZE,
		rng.randf_range(1, 6) * TILE_SIZE
	)
	enemy.position = random_pos
	enemy.call("_ready")
	add_child(enemy)

func _create_enemy_sprite(enemy_type: String) -> Node2D:
	var container = Node2D.new()
	
	match enemy_type:
		"cendrier":
			var body = ColorRect.new()
			body.color = Color(0.102, 0.078, 0.063)
			body.size = Vector2(28, 44)
			body.position = Vector2(-14, -44)
			container.add_child(body)
			
			var head = ColorRect.new()
			head.color = Color(0.15, 0.1, 0.08)
			head.size = Vector2(20, 20)
			head.position = Vector2(-10, -64)
			container.add_child(head)
			
			var eyes = ColorRect.new()
			eyes.color = Color(0.88, 0.38, 0.13)
			eyes.size = Vector2(4, 4)
			eyes.position = Vector2(-6, -58)
			container.add_child(eyes)
			var eyes2 = ColorRect.new()
			eyes2.color = Color(0.88, 0.38, 0.13)
			eyes2.size = Vector2(4, 4)
			eyes2.position = Vector2(2, -58)
			container.add_child(eyes2)
	
	return container

func _spawn_boss() -> void:
	for x in range(8):
		for y in range(8):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(2, 0))
	
	var boss = CharacterBody2D.new()
	boss.name = "Gardien des Cendres"
	boss.position = Vector2(TILE_SIZE * 4, TILE_SIZE * 4)
	boss.add_to_group("enemies")
	boss.add_to_group("bosses")
	boss.set_script(load("res://scripts/enemies/boss_guardian.gd"))
	
	var sprite = _create_boss_sprite()
	boss.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 64)
	collision.shape = shape
	boss.add_child(collision)
	
	boss.call("_ready")
	add_child(boss)

func _create_boss_sprite() -> Node2D:
	var container = Node2D.new()
	container.name = "BossSprite"
	
	var body = ColorRect.new()
	body.color = Color(0.1, 0.08, 0.06)
	body.size = Vector2(44, 60)
	body.position = Vector2(-22, -60)
	container.add_child(body)
	
	var torso = ColorRect.new()
	torso.color = Color(0.6, 0.06, 0.06)
	torso.size = Vector2(36, 30)
	torso.position = Vector2(-18, -50)
	container.add_child(torso)
	
	var head = ColorRect.new()
	head.color = Color(0.12, 0.1, 0.08)
	head.size = Vector2(28, 28)
	head.position = Vector2(-14, -82)
	container.add_child(head)
	
	var crown = ColorRect.new()
	crown.color = Color(0.75, 0.72, 0.66)
	crown.size = Vector2(24, 8)
	crown.position = Vector2(-12, -90)
	container.add_child(crown)
	
	var face_left = ColorRect.new()
	face_left.color = Color(0.6, 0.04, 0.04)
	face_left.size = Vector2(4, 6)
	face_left.position = Vector2(-8, -74)
	container.add_child(face_left)
	
	var face_right = ColorRect.new()
	face_right.color = Color(0.6, 0.04, 0.04)
	face_right.size = Vector2(4, 6)
	face_right.position = Vector2(4, -74)
	container.add_child(face_right)
	
	var eye_glow = ColorRect.new()
	eye_glow.color = Color(0.9, 0.2, 0.1)
	eye_glow.size = Vector2(3, 3)
	eye_glow.position = Vector2(-7, -73)
	container.add_child(eye_glow)
	
	var eye_glow2 = ColorRect.new()
	eye_glow2.color = Color(0.9, 0.2, 0.1)
	eye_glow2.size = Vector2(3, 3)
	eye_glow2.position = Vector2(4, -73)
	container.add_child(eye_glow2)
	
	var aura = ColorRect.new()
	aura.color = Color(0.9, 0.1, 0.1, 0.2)
	aura.size = Vector2(64, 64)
	aura.position = Vector2(-32, -64)
	container.add_child(aura)
	
	return container

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
	level_label.text = "Nv. %d" % GameManager.player_stats["level"]
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
	
	var sprite = _create_fireball_sprite()
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.position = player_node.position
	
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player_node.position).normalized()
	projectile.set("direction", dir)
	projectile.set_script(load("res://scripts/projectile.gd"))
	projectile.set("damage", int(10 * (1.0 + float(GameManager.player_stats["energy"]) / 100.0)))
	projectile.set("element", "fire")
	
	add_child(projectile)

func _create_fireball_sprite() -> Node2D:
	var container = Node2D.new()
	
	var core = ColorRect.new()
	core.color = Color(1, 0.6, 0.1)
	core.size = Vector2(12, 12)
	core.position = Vector2(-6, -6)
	container.add_child(core)
	
	var glow = ColorRect.new()
	glow.color = Color(1, 0.3, 0.05, 0.6)
	glow.size = Vector2(20, 20)
	glow.position = Vector2(-10, -10)
	container.add_child(glow)
	
	var particles = ColorRect.new()
	particles.color = Color(1, 0.8, 0.2, 0.4)
	particles.size = Vector2(6, 6)
	particles.position = Vector2(-3, -8)
	container.add_child(particles)
	
	return container

func _ice_shard() -> void:
	if not player_node.use_mana(4):
		return
	
	var projectile = Area2D.new()
	projectile.name = "IceShard"
	projectile.add_to_group("projectiles")
	
	var sprite = _create_ice_shard_sprite()
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.position = player_node.position
	
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player_node.position).normalized()
	projectile.set("direction", dir)
	projectile.set_script(load("res://scripts/projectile.gd"))
	projectile.set("damage", int(8 * (1.0 + float(GameManager.player_stats["energy"]) / 100.0)))
	projectile.set("element", "cold")
	
	add_child(projectile)

func _create_ice_shard_sprite() -> Node2D:
	var container = Node2D.new()
	
	var core = ColorRect.new()
	core.color = Color(0.5, 0.85, 1)
	core.size = Vector2(10, 10)
	core.position = Vector2(-5, -5)
	container.add_child(core)
	
	var glow = ColorRect.new()
	glow.color = Color(0.3, 0.7, 0.9, 0.5)
	glow.size = Vector2(14, 14)
	glow.position = Vector2(-7, -7)
	container.add_child(glow)
	
	var sparkle = ColorRect.new()
	sparkle.color = Color.WHITE
	sparkle.size = Vector2(3, 3)
	sparkle.position = Vector2(-1.5, -1.5)
	container.add_child(sparkle)
	
	return container

func _lightning() -> void:
	if not player_node.use_mana(8):
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damage = int(10 * (1.0 + float(GameManager.player_stats["energy"]) / 100.0))
	for i in range(min(3, enemies.size())):
		_create_lightning_effect(enemies[i].position)
		enemies[i].take_damage(damage)

func _create_lightning_effect(pos: Vector2) -> void:
	var effect = ColorRect.new()
	effect.color = Color(0.9, 0.9, 0.3)
	effect.size = Vector2(4, 30)
	effect.position = pos + Vector2(-2, -15)
	effect.modulate.a = 0.8
	add_child(effect)
	
	var glow = ColorRect.new()
	glow.color = Color(0.6, 0.6, 0.2, 0.4)
	glow.size = Vector2(8, 40)
	glow.position = pos + Vector2(-4, -20)
	add_child(glow)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)
	tween.tween_callback(glow.queue_free)

func _use_potion(slot: int) -> void:
	GameManager.player_stats["mana"] = min(GameManager.player_stats["mana"] + 25, GameManager.player_stats["mana_max"])
	GameManager.player_stats["health"] = min(GameManager.player_stats["health"] + 15, GameManager.player_stats["health_max"])

func _update_mini_map() -> void:
	if mini_map:
		pass

func show_death_screen() -> void:
	GameManager.game_state = "dead"
	GameManager.lose_shards(int(GameManager.shards * 0.2))
	GameManager.player_stats["health"] = 0
	
	var death_screen = Control.new()
	death_screen.name = "DeathScreen"
	death_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(bg)
	
	var label = Label.new()
	label.text = "La magie s'éteint... pour l'instant.\n\nÉclats perdus: %d\nXP perdue: 10%%" % int(GameManager.shards * 0.2)
	label.add_theme_font_size_override("font_size", 24)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-200, -80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_screen.add_child(label)
	
	var button = Button.new()
	button.text = "Retourner au hub"
	button.set_anchors_preset(Control.PRESET_CENTER)
	button.position = Vector2(-80, 40)
	button.size = Vector2(160, 40)
	button.pressed.connect(_on_respawn_pressed)
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
	for x in range(8):
		for y in range(8):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(2, 0))
	_spawn_boss_enemy()

func _spawn_boss_enemy() -> void:
	var boss = preload("res://scripts/enemies/boss_guardian.gd").new()
	boss.name = "Gardien des Cendres"
	boss.position = Vector2(TILE_SIZE * 4, TILE_SIZE * 4)
	add_child(boss)

func _generate_boss_room() -> void:
	for x in range(8):
		for y in range(8):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(2, 0))
	_spawn_boss_enemy()

func _use_portal() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")