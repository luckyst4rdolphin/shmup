extends Node

@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
@onready var enemies: Node2D = $"../Enemies"

@onready var playfield_bounds: Node2D = $"../PlayfieldBounds"
@export var left_spawn_x := -40.0
@export var right_spawn_x := 440.0
@export var bottom_keepout := 140.0

@export var min_spawn_distance := 24.0
@export var max_spawn_tries := 80

@export var wave_size := 4
@export var spawn_gap := 0.2
@export var kills_to_advance := 8
var kills := 0

var alive_in_wave := 0
var wave_running := false
var wave_id := 0
var wave_enemies := {}

@onready var level_root: Node2D = get_parent() as Node2D
@export var stage_step := 300.0
@export var stage_move_time := 2.0

func _ready() -> void:
	start_wave()

func get_playfield_rect_global() -> Rect2:
	var tl := playfield_bounds.get_node("TopLeft") as Marker2D
	var br := playfield_bounds.get_node("BottomRight") as Marker2D
	return Rect2(tl.global_position, br.global_position - tl.global_position).abs()

func start_wave() -> void:
	if wave_running:
		return
	wave_running = true

	wave_id += 1
	var my_wave := wave_id

	alive_in_wave = 0
	wave_enemies.clear()
	
	var spawned := 0
	var attempts := 0
	var max_attempts := wave_size * 50

	while spawned < wave_size and attempts < max_attempts:
		if my_wave != wave_id:
			return

		var e := spawn_one()
		if e != null:
			spawned += 1

		attempts += 1
		await get_tree().create_timer(spawn_gap).timeout

	if spawned <= 0:
		wave_running = false
		await get_tree().create_timer(0.5).timeout
		start_wave()

func spawn_one() -> Node2D:
	if playfield_bounds == null:
		push_error("playfield_bounds is null (assign it in Inspector)")
		return null

	var tl := playfield_bounds.get_node("TopLeft") as Marker2D
	var br := playfield_bounds.get_node("BottomRight") as Marker2D
	var r := Rect2(tl.global_position, br.global_position - tl.global_position).abs()

	var spawn_y_min := r.position.y
	var spawn_y_max := (r.position.y + r.size.y) - bottom_keepout
	if spawn_y_max <= spawn_y_min:
		spawn_y_max = spawn_y_min + 1.0

	var chosen_pos := Vector2.ZERO
	var found := false

	for i in range(max_spawn_tries):
		var x := left_spawn_x if randf() < 0.5 else right_spawn_x
		var y := randf_range(spawn_y_min, spawn_y_max)
		var p := Vector2(x, y)
		if is_far_from_others(p):
			chosen_pos = p
			found = true
			break

	if not found:
		return null

	var e := enemy_scene.instantiate()
	e.global_position = chosen_pos
	e.playfield_bounds = playfield_bounds

	var id := e.get_instance_id()
	wave_enemies[id] = true
	alive_in_wave = wave_enemies.size()

	e.died.connect(_on_enemy_died.bind(id)) # bind id so duplicates are ignored

	enemies.add_child(e)
	return e

func is_far_from_others(pos: Vector2) -> bool:
	for c in enemies.get_children():
		if c is Node2D:
			if (c.global_position - pos).length() < min_spawn_distance:
				return false
	return true

func _on_enemy_died(id: int) -> void:
	if wave_enemies.has(id):
		wave_enemies.erase(id)
		kills += 1

	alive_in_wave = wave_enemies.size()

	if kills >= kills_to_advance:
		kills = 0
		wave_running = false
		await advance_stage()
		call_deferred("start_wave")
		return

	if alive_in_wave <= 0 and wave_running:
		wave_running = false
		call_deferred("start_wave") # defer to avoid physics flushing error

func advance_stage() -> void:
	if level_root == null:
		push_error("level_root not assigned")
		return

	var tween := level_root.create_tween()
	tween.tween_property(
		level_root,
		"position",
		level_root.position + Vector2(0, stage_step), # DOWN
		stage_move_time
	)
	await tween.finished
