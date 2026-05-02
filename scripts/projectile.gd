extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: int = 10
var element: String = "fire"
var lifetime: float = 3.0

func _ready() -> void:
	add_to_group("projectiles")
	connect("area_entered", _on_area_entered)

func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		direction = (event.position - position).normalized()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var enemy = area
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", damage)
		queue_free()