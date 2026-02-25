extends Area2D

@export var speed := 150.0
@export var damage := 1
@export var hit_explosion_scene: PackedScene
var direction: Vector2 = Vector2.UP

func _ready() -> void:
	monitoring = true # needed for detection signals

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Fallback hit check (in case signal isn't connected)
	for body in get_overlapping_bodies():
		_try_hit(body)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("apply_damage"):
		body.apply_damage(damage)

		if hit_explosion_scene != null:
			var ex := hit_explosion_scene.instantiate()
			get_tree().current_scene.add_child(ex)
			ex.global_position = global_position

		queue_free()

func _try_hit(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("enemy") and body.has_method("apply_damage"):
		body.apply_damage(damage)
		queue_free()
