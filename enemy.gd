extends CharacterBody2D

@export var hp := 5
@export var explosion_scene: PackedScene
@onready var explosion_point: Marker2D = $EnemyCollision/ExplosionPoint

@export var speed := 40
@export var change_dir_time := 1.0

@export var playfield_bounds: Node2D
var tl: Marker2D
var br: Marker2D

# Collision
@export var wall_layer := 1
@export var enter_margin := 12.0
var entering := true

# Movement
var move_dir := Vector2.LEFT
var t := 0.0

# Per-enemy RNG so multiple enemies spawned same frame don't “sync”
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize() # RNG instance has its own seed

	assert(playfield_bounds != null, "Enemy.playfield_bounds not set (assign it in spawner)")
	tl = playfield_bounds.get_node("TopLeft") as Marker2D
	br = playfield_bounds.get_node("BottomRight") as Marker2D
	assert(tl != null and br != null, "PlayfieldBounds needs TopLeft and BottomRight Marker2D")

	# Pass through walls until inside
	set_collision_mask_value(wall_layer, false)

	# Start timer so wander chooses direction quickly after entering
	t = 0.0

func random_dir() -> Vector2:
	var d := Vector2.ZERO
	while d.length_squared() < 0.001:
		d = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	return d.normalized()

func playfield_rect() -> Rect2:
	var a := tl.global_position
	var b := br.global_position
	var rect := Rect2(a, b - a).abs() # has_point not reliable w/ negative size
	rect.position += Vector2(enter_margin, enter_margin)
	rect.size -= Vector2(enter_margin * 2.0, enter_margin * 2.0)
	return rect

func inside_playfield(p: Vector2) -> bool:
	return playfield_rect().has_point(p) # right/bottom edges excluded by convention

func _physics_process(delta: float) -> void:
	var rect := playfield_rect()

	if entering:
		# Nearest point inside rect (clamp)
		var target := Vector2(
			clamp(global_position.x, rect.position.x, rect.position.x + rect.size.x),
			clamp(global_position.y, rect.position.y, rect.position.y + rect.size.y)
		)
		var v := target - global_position

		if v.length_squared() < 0.01:
			entering = false
			set_collision_mask_value(wall_layer, true)
			move_dir = random_dir()
			t = change_dir_time
		else:
			move_dir = v.normalized()
	else:
		t -= delta
		if t <= 0.0:
			t = change_dir_time
			move_dir = random_dir()

	# Fail-safe: never allow stop due to zero direction
	if move_dir.length_squared() < 0.001:
		move_dir = random_dir()

	velocity = move_dir * speed
	move_and_slide() # uses CharacterBody2D.velocity for motion/collisions

	if entering and inside_playfield(global_position):
		entering = false
		set_collision_mask_value(wall_layer, true)
		move_dir = random_dir()
		t = change_dir_time

func apply_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		die()

func die() -> void:
	if explosion_scene:
		var ex = explosion_scene.instantiate()
		get_parent().add_child(ex)
		ex.global_position = explosion_point.global_position
	queue_free()
