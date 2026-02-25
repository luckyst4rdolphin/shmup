extends Node

@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
@onready var enemies: Node2D = $"../Enemies"

@onready var playfield_bounds: Node2D = $"../PlayfieldBounds"
@export var left_spawn_x := -40.0
@export var right_spawn_x := 440.0
@export var min_y := 40.0
@export var max_y := 680.0
@export var bottom_keepout := 120.0

@export var min_spawn_distance := 48.0  # tweak; roughly enemy size + padding
@export var max_spawn_tries := 20

func _ready() -> void:
	spawn_three()

func get_playfield_rect_global() -> Rect2:
	var tl := playfield_bounds.get_node("TopLeft") as Marker2D
	var br := playfield_bounds.get_node("BottomRight") as Marker2D
	return Rect2(tl.global_position, br.global_position - tl.global_position).abs()

func spawn_three() -> void:
	for i in range(3):
		spawn_one()
		await get_tree().create_timer(0.2).timeout

func spawn_one() -> void:
	if playfield_bounds == null:
		push_error("playfield_bounds is null (assign it in Inspector)")
		return

	# compute dynamic rect from markers (same as before)
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
		var y := randf_range(spawn_y_min, spawn_y_max) # random float in range
		var p := Vector2(x, y)
		if is_far_from_others(p):
			chosen_pos = p
			found = true
			break

	if not found:
		return # skip spawning this time (or lower min_spawn_distance / increase tries)

	var e := enemy_scene.instantiate()
	e.global_position = chosen_pos
	e.playfield_bounds = playfield_bounds
	enemies.add_child(e)


func is_far_from_others(pos: Vector2) -> bool:
	for c in enemies.get_children():
		if c is Node2D:
			if (c.global_position - pos).length() < min_spawn_distance:
				return false
	return true
