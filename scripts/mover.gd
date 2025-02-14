extends Node2D

@onready var move_points_container: Node2D = $MovePoints

@export var speed: float = 100.0

var move_points: Array[Vector2] = []
var current_move_point: int = 0

func _ready() -> void:
	for child in move_points_container.get_children():
		if child is Node2D:
			move_points.append(child.global_position)
			move_points_container.remove_child(child)

func _process(delta: float) -> void:
	if move_points.size() == 0:
		return

	var target: Vector2 = move_points[current_move_point]
	var direction: Vector2 = (target - global_position).normalized()
	global_position += direction * speed * delta

	if global_position.distance_to(target) < 1.0:
		current_move_point += 1
		if current_move_point >= move_points.size():
			current_move_point = 0
