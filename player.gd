# player.gd (copy/paste)
extends CharacterBody2D

@export var move_speed := 90.0
@export var bullet_scene: PackedScene = preload("res://Bullet.tscn")
@export var bullet_dir := Vector2.UP

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer


var wants_to_shoot := false

func _ready() -> void:
	assert(muzzle != null)
	assert(fire_timer != null)

	# If you didn't connect the signal in the editor, do it here:
	if not fire_timer.timeout.is_connected(_on_fire_timer_timeout):
		fire_timer.timeout.connect(_on_fire_timer_timeout)

func _physics_process(_delta: float) -> void:
	var move_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = move_vec * move_speed
	move_and_slide()

	# Press to start shooting
	if Input.is_action_just_pressed("shoot"):
		wants_to_shoot = true
		_try_shoot_now()

	# Release to stop shooting
	if Input.is_action_just_released("shoot"):
		wants_to_shoot = false

func _try_shoot_now() -> void:
	if bullet_scene == null:
		push_error("bullet_scene is null (assign it in Player inspector)")
		return

	if fire_timer.is_stopped():
		_shoot_once()
		fire_timer.start()

func _on_fire_timer_timeout() -> void:
	if wants_to_shoot:
		_shoot_once()
		fire_timer.start()

func _shoot_once() -> void:
	var b := bullet_scene.instantiate()
	if b == null:
		push_error("bullet_scene failed to instantiate")
		return

	# Put bullets in the world, not as child of player
	get_tree().current_scene.add_child(b)
	b.global_transform = muzzle.global_transform

	if b.has_method("set_direction"):
		b.set_direction(bullet_dir)
