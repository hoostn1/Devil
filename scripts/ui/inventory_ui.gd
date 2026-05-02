extends CanvasLayer

var is_inventory_visible: bool = false
var inventory_ui: Control

var inventory_size: int = 24
var inventory: Array = []
var selected_item: int = -1

@onready var game_manager = GameManager

func _ready() -> void:
	inventory.resize(inventory_size)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		toggle_inventory()

func toggle_inventory() -> void:
	is_inventory_visible = !is_inventory_visible
	if is_inventory_visible:
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	if inventory_ui:
		inventory_ui.queue_free()
	
	inventory_ui = Control.new()
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_ui.modulate = Color(1, 1, 1, 0.95)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_ui.add_child(bg)
	
	var title = Label.new()
	title.text = "INVENTAIRE"
	title.add_theme_font_size_override("font_size", 28)
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(40, 30)
	inventory_ui.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "Fermer (I)"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-150, 30)
	close_btn.size = Vector2(120, 40)
	close_btn.pressed.connect(toggle_inventory)
	inventory_ui.add_child(close_btn)
	
	var grid = _create_inventory_grid()
	grid.position = Vector2(40, 120)
	inventory_ui.add_child(grid)
	
	var equipment = _create_equipment_panel()
	equipment.position = Vector2(500, 120)
	inventory_ui.add_child(equipment)
	
	var stats_panel = _create_stats_panel()
	stats_panel.position = Vector2(700, 120)
	inventory_ui.add_child(stats_panel)
	
	var shards_display = Label.new()
	shards_display.text = "Éclats: %d" % GameManager.shards
	shards_display.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	shards_display.position = Vector2(40, -60)
	inventory_ui.add_child(shards_display)
	
	add_child(inventory_ui)

func _create_inventory_grid() -> Control:
	var grid = GridContainer.new()
	grid.columns = 6
	grid.custom_minimum_size = Vector2(384, 256)
	
	for i in range(inventory_size):
		var slot = _create_slot(i)
		grid.add_child(slot)
	
	return grid

func _create_slot(index: int) -> Control:
	var slot = Button.new()
	slot.custom_minimum_size = Vector2(56, 56)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var item = inventory[index] if index < inventory.size() else null
	if item:
		_update_slot_display(slot, item)
		slot.pressed.connect(_on_slot_pressed.bind(index))
	else:
		slot.modulate = Color(0.2, 0.2, 0.2)
	
	return slot

func _update_slot_display(slot: Button, item: Item) -> void:
	slot.modulate = item.get_color()
	slot.text = item.name.substr(0, 1)
	slot.tooltip_text = item.get_display_name()

func _on_slot_pressed(index: int) -> void:
	if selected_item == -1:
		selected_item = index
	else:
		if selected_item != index:
			_swap_items(selected_item, index)
		selected_item = -1

func _swap_items(idx1: int, idx2: int) -> void:
	var temp = inventory[idx1]
	inventory[idx1] = inventory[idx2]
	inventory[idx2] = temp
	refresh()

func _create_equipment_panel() -> Control:
	var panel = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(180, 300)
	
	var title = Label.new()
	title.text = "ÉQUIPEMENT"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)
	
	var slots = ["main_hand", "body", "belt", "neck", "ring"]
	for slot_name in slots:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 40)
		btn.text = slot_name.replace("_", " ").capitalize()
		panel.add_child(btn)
	
	return panel

func _create_stats_panel() -> Control:
	var panel = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(200, 300)
	
	var title = Label.new()
	title.text = "STATISTIQUES"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)
	
	var stats = [
		"Énergie: %d" % GameManager.player_stats["energy"],
		"PV: %d" % GameManager.player_stats["health_max"],
		"Mana: %d" % GameManager.player_stats["mana_max"],
		"Dextérité: %d" % GameManager.player_stats["dexterity"]
	]
	for stat in stats:
		var label = Label.new()
		label.text = stat
		panel.add_child(label)
	
	return panel

func add_item(item: Item) -> bool:
	for i in range(inventory_size):
		if inventory[i] == null:
			inventory[i] = item
			return true
	return false

func remove_item(index: int) -> Item:
	var item = inventory[index]
	inventory[index] = null
	return item

func refresh() -> void:
	if is_inventory_visible:
		show_inventory()

func hide_inventory() -> void:
	if inventory_ui:
		inventory_ui.queue_free()
		inventory_ui = null
	is_inventory_visible = false