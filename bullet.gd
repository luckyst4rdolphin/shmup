extends Area2D

@export var speed := 150.0
@export var damage := 1
var direction: Vector2 = Vector2.UP

func _ready() -> void:
	monitoring = true # needed for detection signals [web:700]

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Fallback hit check (in case signal isn't connected)
	for body in get_overlapping_bodies():
		_try_hit(body)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# Connect: Area2D -> body_entered(body) -> _on_body_entered
func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _try_hit(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("enemy") and body.has_method("apply_damage"):
		body.apply_damage(damage)
		queue_free()
