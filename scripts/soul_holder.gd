extends Node2D

class_name SoulHolder

@export var soul_scene: PackedScene
@export var max_soul_spawn: int = 50

@export var dispersion_amount: float = 50
@export var outwards_time: float = 0.5
@export var inwards_time: float = 2

var souls: Array[SoulInstance] = []
var target_pos: Vector2 = Vector2(-270, -150)
var timer: float = 0
var souls_to_spawn: Array[Vector2] = []
var soul_spawn_timer: float = 0
var trail_max_points: int = 20

class SoulInstance:
	var trail: Line2D
	var trail_target: Node2D
	var trail_points: Array[Vector2] = []
	var active: bool = false

func _ready() -> void:
	for i in range(max_soul_spawn):
		var new_soul_instance: SoulInstance = SoulInstance.new()
		var new_soul_scene: Line2D = soul_scene.instantiate()
		new_soul_instance.trail = new_soul_scene
		new_soul_instance.trail_target = new_soul_scene.get_node("TrailTarget")
		add_child(new_soul_instance.trail)
		souls.append(new_soul_instance)

	Events.enemy_died.connect(spawn_souls)
	deactivate_all_souls()


func spawn_soul(spawn_pos: Vector2) -> void:
	for soul in souls:
		if not soul.active:
			soul.active = true
			soul.trail.visible = true

			soul.trail.global_position = spawn_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			soul.trail_target.position = Vector2.ZERO

			var arc_type: int = randi_range(0, 1)
			var arc_amount: float = randf_range(0.8, 0.9)
			var arc_x: float = arc_amount if arc_type == 0 else 1.0
			var arc_y: float = arc_amount if arc_type == 1 else 1.0

			var tween_x: Tween = get_tree().create_tween()
			tween_x.set_trans(Tween.TRANS_EXPO)
			tween_x.set_ease(Tween.EASE_IN_OUT)

			var tween_y: Tween = get_tree().create_tween()
			tween_x.set_trans(Tween.TRANS_EXPO)
			tween_x.set_ease(Tween.EASE_IN if arc_type == 0 else Tween.EASE_OUT)
			tween_x.tween_property(soul.trail_target, "global_position:x", soul.trail.global_position.x + randf_range(-dispersion_amount, dispersion_amount), outwards_time)
			tween_y.tween_property(soul.trail_target, "global_position:y", soul.trail.global_position.y + randf_range(-dispersion_amount, dispersion_amount), outwards_time)
			tween_x.tween_property(soul.trail_target, "global_position:x", target_pos.x + randf_range(-10, 10), inwards_time * randf_range(0.8, 1.2))
			tween_y.tween_property(soul.trail_target, "global_position:y", target_pos.y + randf_range(-1, 1), inwards_time * randf_range(0.8, 1.2))

			get_tree().create_timer((outwards_time + inwards_time) + 0.2).timeout.connect(func() -> void: deactivate_soul(soul))

			break

func deactivate_soul(target_soul: SoulInstance) -> void:
	target_soul.trail_target.position = target_soul.trail.global_position
	target_soul.active = false
	target_soul.trail.visible = false
	target_soul.trail.clear_points()

func spawn_souls(stats: Stats) -> void:
	var amount: int = roundi(stats.score_reward * 0.5)

	if amount > 0:
		for i in range(amount):
			souls_to_spawn.append(stats.global_position)

func deactivate_all_souls() -> void:
	for soul in souls:
		deactivate_soul(soul)

func _process(delta: float) -> void:
	timer += delta * 1

	if souls_to_spawn.size() > 0:
		soul_spawn_timer += delta
		if soul_spawn_timer > 0.02:
			spawn_soul(souls_to_spawn.pop_front())
			soul_spawn_timer = 0

	for soul in souls:
		if !soul.active:
			continue

		soul.trail.add_point(soul.trail_target.position)
		if soul.trail.points.size() > trail_max_points:
			soul.trail.remove_point(0)
