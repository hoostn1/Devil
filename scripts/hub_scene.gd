extends Node2D

var is_hub: bool = true

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	GameManager.game_state = "hub"
	_setup_hub_environment()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T: _use_portal()
			KEY_ENTER: _start_run()
			KEY_1: _talk_to_merchant(0)
			KEY_2: _talk_to_merchant(1)
			KEY_3: _talk_to_merchant(2)
			KEY_I: InventoryUI.call("toggle_inventory")
			KEY_K: SkillUI.call("toggle_skill_ui")

func _setup_hub_environment() -> void:
	modulate = Color(1, 1, 1, 1)
	
	var bg = ColorRect.new()
	bg.name = "HubBg"
	bg.color = Color(0.05, 0.04, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.custom_minimum_size = Vector2(1280, 720)
	add_child(bg)
	
	var title = Label.new()
	title.text = "RUINES DU CAIRN"
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(40, 30)
	add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Le hub"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(0.6, 0.6, 0.6)
	subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	subtitle.position = Vector2(40, 70)
	add_child(subtitle)
	
	var merchants_info = _create_merchants_info()
	merchants_info.position = Vector2(40, 150)
	add_child(merchants_info)
	
	var controls = _create_controls_panel()
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(40, -180)
	add_child(controls)
	
	var player_stats_info = _create_player_info()
	player_stats_info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	player_stats_info.position = Vector2(-250, 30)
	add_child(player_stats_info)

func _create_merchants_info() -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	
	var title = Label.new()
	title.text = "MARCHANDS"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var m1 = Label.new()
	m1.text = "[1] Arcaniste Selva - Potions, objets magiques"
	m1.modulate = Color(0.306, 0.941, 0.769)
	vbox.add_child(m1)
	
	var m2 = Label.new()
	m2.text = "[2] Forgeron Drath - Améliorations d'objets"
	m2.modulate = Color(0.306, 0.941, 0.769)
	vbox.add_child(m2)
	
	var m3 = Label.new()
	m3.text = "[3] Sage Wyn - Identification, respec"
	m3.modulate = Color(0.306, 0.941, 0.769)
	vbox.add_child(m3)
	
	return vbox

func _create_controls_panel() -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 150)
	
	var title = Label.new()
	title.text = "CONTRÔLES"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var enter_label = Label.new()
	enter_label.text = "[ENTRER] Entrer dans le donjon"
	vbox.add_child(enter_label)
	
	var portal_label = Label.new()
	portal_label.text = "[T] Portail de retour"
	vbox.add_child(portal_label)
	
	var inv_label = Label.new()
	inv_label.text = "[I] Inventaire | [K] Compétences"
	vbox.add_child(inv_label)
	
	var exit_label = Label.new()
	exit_label.text = "[ÉCHAP] Quitter"
	vbox.add_child(exit_label)
	
	return vbox

func _create_player_info() -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 200)
	
	var title = Label.new()
	title.text = "VOTRE MAGE"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var level = Label.new()
	level.text = "Niveau: %d" % GameManager.player_stats["level"]
	vbox.add_child(level)
	
	var xp = Label.new()
	xp.text = "XP: %d/%d" % [GameManager.player_stats["xp"], GameManager.player_stats["xp_to_next"]]
	vbox.add_child(xp)
	
	var shards = Label.new()
	shards.text = "Éclats: %d" % GameManager.shards
	vbox.add_child(shards)
	
	var health = Label.new()
	health.text = "PV: %d/%d" % [GameManager.player_stats["health"], GameManager.player_stats["health_max"]]
	vbox.add_child(health)
	
	var mana = Label.new()
	mana.text = "Mana: %d/%d" % [GameManager.player_stats["mana"], GameManager.player_stats["mana_max"]]
	vbox.add_child(mana)
	
	var attr = Label.new()
	attr.text = "Énergie: %d | Vitalité: %d | Dextérité: %d" % [
		GameManager.player_stats["energy"],
		GameManager.player_stats["vitality"],
		GameManager.player_stats["dexterity"]
	]
	vbox.add_child(attr)
	
	var skill_pts = Label.new()
	skill_pts.text = "Points compétences: %d" % GameManager.player_stats["skill_points"]
	vbox.add_child(skill_pts)
	
	var attr_pts = Label.new()
	attr_pts.text = "Points attributs: %d" % GameManager.player_stats["attribute_points"]
	vbox.add_child(attr_pts)
	
	return vbox

func _talk_to_merchant(index: int) -> void:
	match index:
		0: _show_merchant_selva()
		1: _show_merchant_drath()
		2: _show_merchant_wyn()

func _show_merchant_selva() -> void:
	var popup = _create_merchant_popup("Arcaniste Selva", [
		{"name": "Potion de mana (petit)", "price": 15},
		{"name": "Potion de mana (grand)", "price": 40},
		{"name": "Parchemin de portail", "price": 20},
		{"name": "Objet Magique aléatoire", "price": randi_range(80, 200)}
	])
	add_child(popup)

func _show_merchant_drath() -> void:
	var popup = _create_merchant_popup("Forgeron Drath", [
		{"name": "Améliorer Normal → Magique", "price": 50},
		{"name": "Réinitialiser affixes", "price": 75}
	])
	add_child(popup)

func _show_merchant_wyn() -> void:
	var popup = _create_merchant_popup("Sage Wyn", [
		{"name": "Identifier objet", "price": 10},
		{"name": "Identifier en masse", "price": 40},
		{"name": "Respec 1 compétence", "price": 100},
		{"name": "Respec 1 attribut", "price": 80}
	])
	add_child(popup)

func _create_merchant_popup(merchant_name: String, items: Array) -> Control:
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.custom_minimum_size = Vector2(400, 300)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.08, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(bg)
	
	var title = Label.new()
	title.text = merchant_name
	title.add_theme_font_size_override("font_size", 24)
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(20, 20)
	popup.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-40, 20)
	close_btn.size = Vector2(30, 30)
	close_btn.pressed.connect(popup.queue_free)
	popup.add_child(close_btn)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.set_anchors_preset(Control.PRESET_CENTER)
	grid.position = Vector2(-150, -80)
	grid.custom_minimum_size = Vector2(300, 200)
	
	for item in items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 40)
		btn.text = item["name"] + " (" + str(item["price"]) + " Éclats)"
		btn.pressed.connect(_buy_item.bind(item))
		grid.add_child(btn)
	
	popup.add_child(grid)
	
	return popup

func _buy_item(item: Dictionary) -> void:
	var price = item["price"]
	if GameManager.shards >= price:
		GameManager.shards -= price
		GameManager.save_game()
	else:
		pass

func _use_portal() -> void:
	pass

func _start_run() -> void:
	GameManager.current_room = 0
	GameManager.game_state = "playing"
	get_tree().change_scene_to_file("res://scenes/main.tscn")