extends CharacterBody2D
signal died

@export var hp := 5
@export var explosion_scene: PackedScene
@onready var explosion_point: Marker2D = $EnemyCollision/ExplosionPoint

@export var speed := 30
@export var change_dir_time := 3.5

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

# “70% area” wandering (no clamping)
@export var wander_area_percent := 0.70
@export var arrive_dist := 8.0
var target_pos: Vector2 = Vector2.ZERO

# Separation so enemies don't clump
@export var separation_radius := 50.0
@export var separation_strength := 100.0

# Per-enemy RNG so multiple enemies spawned same frame don't “sync”
var rng := RandomNumberGenerator.new()

@export var max_enemy_y := 500.0

var dead := false

func _ready() -> void:
	rng.randomize()

	assert(playfield_bounds != null, "Enemy.playfield_bounds not set (assign it in spawner)")
	tl = playfield_bounds.get_node("TopLeft") as Marker2D
	br = playfield_bounds.get_node("BottomRight") as Marker2D
	assert(tl != null and br != null, "PlayfieldBounds needs TopLeft and BottomRight Marker2D")

	# Pass through walls until inside
	set_collision_mask_value(wall_layer, false)

	# Slightly desync direction-change timers between enemies
	t = rng.randf_range(0.0, change_dir_time)

	add_to_group("enemy")

func random_dir() -> Vector2:
	var d := Vector2.ZERO
	while d.length_squared() < 0.001:
		d = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	return d.normalized()

func playfield_rect() -> Rect2:
	var a := tl.global_position
	var b := br.global_position
	var rect := Rect2(a, b - a).abs()

	# Looser margins so enemies can go higher
	rect.position += Vector2(0.0, 0.0)
	rect.size -= Vector2(0.0, 0.0)

	var bottom := float(min(rect.position.y + rect.size.y, max_enemy_y))
	rect.size.y = max(bottom - rect.position.y, 1.0)
	return rect

func inside_playfield(p: Vector2) -> bool:
	return playfield_rect().has_point(p)

func get_enemy_area_rect_global(percent: float = 0.70) -> Rect2:
	percent = clamp(percent, 0.0, 1.0)

	var m_tl := playfield_bounds.get_node("TopLeft") as Marker2D
	var m_br := playfield_bounds.get_node("BottomRight") as Marker2D
	var outer := Rect2(m_tl.global_position, m_br.global_position - m_tl.global_position).abs()

	var inner_size := outer.size * percent

	# Bias upward so enemies use more of the top of the screen
	var inner_pos := outer.position + Vector2(
		(outer.size.x - inner_size.x) * 0.5,
		(outer.size.y - inner_size.y) * 0.2  # smaller factor → higher area
	)

	return Rect2(inner_pos, inner_size)

func pick_new_target() -> void:
	var r := get_enemy_area_rect_global(wander_area_percent)
	target_pos = Vector2(
		rng.randf_range(r.position.x, r.position.x + r.size.x),
		rng.randf_range(r.position.y, r.position.y + r.size.y)
	)

func separation_vector() -> Vector2:
	var push := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self or not (e is Node2D):
			continue
		var d: Vector2 = global_position - e.global_position
		var dist: float = d.length()
		if dist > 0.001 and dist < separation_radius:
			push += d / dist * (1.0 - dist / separation_radius)
	return push


func _physics_process(delta: float) -> void:
	var rect := playfield_rect()

	if entering:
		# Entering behavior: go to nearest point inside rect
		var enter_target := Vector2(
			clamp(global_position.x, rect.position.x, rect.position.x + rect.size.x),
			clamp(global_position.y, rect.position.y, rect.position.y + rect.size.y)
		)
		var v := enter_target - global_position

		if v.length_squared() < 0.01:
			entering = false
			set_collision_mask_value(wall_layer, true)
			pick_new_target()
			t = change_dir_time
		else:
			move_dir = v.normalized()
	else:
		# Wander inside 70% rect by moving toward a random target point
		t -= delta
		if t <= 0.0 or global_position.distance_to(target_pos) <= arrive_dist:
			t = change_dir_time
			pick_new_target()

		var v2 := target_pos - global_position
		if v2.length_squared() < 0.001:
			pick_new_target()
			v2 = target_pos - global_position
		move_dir = v2.normalized()

	# Base desired movement
	var desired := move_dir * speed

	# Add separation so enemies don't clump
	var sep := separation_vector() * separation_strength
	desired += sep

	velocity = desired.limit_length(speed)
	move_and_slide() # uses CharacterBody2D.velocity for motion/collisions

	if entering and inside_playfield(global_position):
		entering = false
		set_collision_mask_value(wall_layer, true)
		pick_new_target()
		t = change_dir_time

func apply_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		die()

func die() -> void:
	if dead:
		return
	dead = true

	died.emit()
	if explosion_scene:
		var ex = explosion_scene.instantiate()
		get_parent().add_child(ex)
		ex.global_position = explosion_point.global_position
	queue_free()
