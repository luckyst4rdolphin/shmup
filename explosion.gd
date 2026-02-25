extends Node2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if anim.sprite_frames and anim.sprite_frames.has_animation("explode"):
		anim.play("explode")
	else:
		anim.play() # plays the currently selected/default animation
	await anim.animation_finished
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
