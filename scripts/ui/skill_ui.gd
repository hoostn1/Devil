extends CanvasLayer

var visible_skill_ui: bool = false
var skill_ui_screen: Control

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		toggle_skill_ui()

func toggle_skill_ui() -> void:
	visible_skill_ui = !visible_skill_ui
	
	if visible_skill_ui:
		show_skill_screen()
	else:
		hide_skill_screen()

func show_skill_screen() -> void:
	if skill_ui_screen:
		skill_ui_screen.queue_free()
	
	skill_ui_screen = Control.new()
	skill_ui_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_ui_screen.modulate = Color(1, 1, 1, 0.95)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_ui_screen.add_child(bg)
	
	var title = Label.new()
	title.text = "COMPÉTENCES"
	title.add_theme_font_size_override("font_size", 28)
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(40, 30)
	skill_ui_screen.add_child(title)
	
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Points disponibles: %d" % GameManager.player_stats["skill_points"]
	points_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	points_label.position = Vector2(40, 70)
	skill_ui_screen.add_child(points_label)
	
	var skills_container = VBoxContainer.new()
	skills_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_container.position = Vector2(40, 120)
	skills_container.size = Vector2(600, 500)
	skill_ui_screen.add_child(skills_container)
	
	var skill_data = [
		{"id": "fireball", "name": "Trait de feu", "desc": "Projectile de feu, dégâts immédiats", "level_req": 1},
		{"id": "ice_shard", "name": "Éclat de glace", "desc": "Projectile froid, ralentit", "level_req": 1},
		{"id": "chain_lightning", "name": "Éclair en chaîne", "desc": "Foudre qui rebondit sur 3 cibles", "level_req": 6},
		{"id": "frost_nova", "name": "Nova de givre", "desc": "Explosion de froid en zone", "level_req": 6},
		{"id": "fireball_adv", "name": "Boule de feu", "desc": "Projectile AoE, dégâts feu élevés", "level_req": 12},
		{"id": "static_storm", "name": "Tempête statique", "desc": "Zone d'éclair persistante", "level_req": 12},
		{"id": "ice_orb", "name": "Orbe glaciale", "desc": "Projectile lent,large AoE froid", "level_req": 18},
		{"id": "elemental_mastery", "name": "Maîtrise élémentaire", "desc": "+% dommages élémentaires", "level_req": 18},
		{"id": "meteor", "name": "Météore", "desc": "Frappe retardée, dégâts massifs", "level_req": 24},
		{"id": "apocalypse", "name": "Apocalypse", "desc": "Pluie d'éclairs+feu+froid", "level_req": 30}
	]
	
	for skill in skill_data:
		var skill_box = _create_skill_entry(skill)
		skills_container.add_child(skill_box)
	
	var close_btn = Button.new()
	close_btn.text = "Fermer (K)"
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.position = Vector2(-150, -60)
	close_btn.size = Vector2(120, 40)
	close_btn.pressed.connect(toggle_skill_ui)
	skill_ui_screen.add_child(close_btn)
	
	add_child(skill_ui_screen)

func _create_skill_entry(skill: Dictionary) -> Control:
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 50)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var skill_level = GameManager.skill_levels.get(skill["id"], 0)
	var is_unlocked = GameManager.skill_tree_unlocked.get(skill["id"], false)
	var color = Color(0.306, 0.941, 0.769) if is_unlocked else Color(0.4, 0.4, 0.4)
	var display_name = "[%s] %s" % [skill_level, skill["name"]]
	if not is_unlocked:
		display_name += " (Nv. %d requis)" % skill["level_req"]
	name_label.text = display_name
	name_label.modulate = color
	info.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = skill["desc"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(desc_label)
	
	container.add_child(info)
	
	if is_unlocked and skill_level < 10:
		var minus_btn = Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(30, 30)
		minus_btn.pressed.connect(_on_skill_decrease.bind(skill["id"]))
		container.add_child(minus_btn)
		
		var level_display = Label.new()
		level_display.text = str(skill_level)
		level_display.custom_minimum_size = Vector2(30, 0)
		level_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(level_display)
		
		var plus_btn = Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(30, 30)
		if GameManager.player_stats["skill_points"] > 0:
			plus_btn.pressed.connect(_on_skill_increase.bind(skill["id"]))
		else:
			plus_btn.disabled = true
		container.add_child(plus_btn)
	
	return container

func _on_skill_increase(skill_id: String) -> void:
	if GameManager.upgrade_skill(skill_id):
		refresh_skill_ui()

func _on_skill_decrease(skill_id: String) -> void:
	GameManager.skill_levels[skill_id] = max(0, GameManager.skill_levels[skill_id] - 1)
	GameManager.player_stats["skill_points"] += 1
	refresh_skill_ui()

func refresh_skill_ui() -> void:
	if skill_ui_screen:
		var points_label = skill_ui_screen.get_node_or_null("PointsLabel")
		if points_label:
			points_label.text = "Points disponibles: %d" % GameManager.player_stats["skill_points"]
		show_skill_screen()

func hide_skill_screen() -> void:
	if skill_ui_screen:
		skill_ui_screen.queue_free()
		skill_ui_screen = null
	visible_skill_ui = false