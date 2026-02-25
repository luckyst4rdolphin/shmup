extends CharacterBody2D

const MOVE_SPEED = 50


func _process(delta: float) -> void:
	var move_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move_vec:
		velocity = move_vec * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()
