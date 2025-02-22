extends Node2D

class_name SoulHolder

@export var soul_scene: PackedScene
@export var max_soul_spawn: int = 50

@export var dispersion_amount: float = 50
@export var outwards_time: float = 0.5
@export var inwards_time: float = 2
@export var screen_pos: Vector2 = Vector2(0, 0)

var souls: Array[SoulInstance] = []
var target_pos: Vector2 = Vector2.ZERO
var timer: float = 0
var souls_to_spawn: Array[Vector2] = []
var soul_spawn_timer: float = 0
@export var trail_max_points: int = 20

class SoulInstance:
	var trail: Line2D
	var trail_target: Node2D
	var trail_points: Array[Vector2] = []
	var light: Light2D
	var active: bool = false
	var sprite: AnimatedSprite2D
	var add: bool = true

func _ready() -> void:
	for i in range(max_soul_spawn):
		var new_soul_instance: SoulInstance = SoulInstance.new()
		var new_soul_scene: Line2D = soul_scene.instantiate()
		new_soul_instance.trail = new_soul_scene
		new_soul_instance.trail_target = new_soul_scene.get_node("TrailTarget")
		new_soul_instance.light = new_soul_instance.trail_target.get_node("Light")
		new_soul_instance.sprite = new_soul_instance.trail_target.get_node("Sprite")
		add_child(new_soul_instance.trail)
		souls.append(new_soul_instance)

	Events.enemy_died.connect(func(stats: Stats, from_parry: bool) -> void: 
		spawn_souls(stats)
	)

	Events.soul_exchanger_activated.connect(func(start_position: Vector2) -> void: 
		spawn_soul(target_pos, start_position, false)
	)

	deactivate_all_souls()

	# target_pos = get_viewport().get_canvas_transform().affine_inverse() * Vector2(0, 0)

func get_negative_soul_count() -> int:
	var count: int = 0

	for soul in souls:
		if soul.active and !soul.add:
			count += 1

	return count

func spawn_soul(spawn_pos: Vector2, destination: Vector2 = Vector2.ZERO, add: bool = true) -> void:
	for soul in souls:
		if not soul.active:
			soul.active = true
			soul.trail.visible = true
			soul.add = add

			soul.trail.global_position = spawn_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
			soul.trail_target.position = Vector2.ZERO
			var color: Color = Color.from_hsv(randf_range(0.5, 0.6), 0.2, 0.8)

			soul.trail.modulate = color
			soul.light.color = color

			var arc_type: int = randi_range(0, 1)
			var arc_amount: float = randf_range(0.8, 0.9)
			var arc_x: float = arc_amount if arc_type == 0 else 1.0
			var arc_y: float = arc_amount if arc_type == 1 else 1.0

			var tween_x: Tween = get_tree().create_tween()
			tween_x.set_trans(Tween.TRANS_EXPO)
			tween_x.set_ease(Tween.EASE_IN if arc_type == 0 else Tween.EASE_OUT)

			var tween_y: Tween = get_tree().create_tween()

			tween_x.tween_property(soul.trail_target, "global_position:x", soul.trail.global_position.x + randf_range(-dispersion_amount, dispersion_amount), outwards_time)
			tween_y.tween_property(soul.trail_target, "global_position:y", soul.trail.global_position.y + randf_range(-dispersion_amount, dispersion_amount), outwards_time)

			if destination == Vector2.ZERO:
				destination = target_pos

			var speed: float = randf_range(0.7, 1.3)
			tween_x.tween_property(soul.trail_target, "global_position:x", destination.x + randf_range(-10, 10), inwards_time * speed)
			tween_y.tween_property(soul.trail_target, "global_position:y", destination.y + randf_range(-10, 10), inwards_time * speed)

			get_tree().create_timer((outwards_time + (inwards_time * speed))).timeout.connect(func() -> void:
				deactivate_soul(soul)
				if add:
					Events.score_changed.emit(GameManager.get_instance().score + 1)
				else:
					Events.soul_remove_finished.emit()
					Events.score_changed.emit(GameManager.get_instance().score - 1)
			)

			break


func deactivate_soul(target_soul: SoulInstance) -> void:
	target_soul.trail_target.position = target_soul.trail.global_position
	target_soul.active = false
	target_soul.trail.visible = false
	target_soul.trail.clear_points()

func spawn_souls(stats: Stats) -> void:
	var amount: int = roundi(stats.score_reward)

	if amount > 0:
		for i in range(amount):
			souls_to_spawn.append(stats.global_position)

func deactivate_all_souls() -> void:
	for soul in souls:
		deactivate_soul(soul)

func _process(delta: float) -> void:
	var camera: Camera2D = GameManager.get_instance().camera

	if !camera:
		return

	var visible_rect := get_viewport().get_visible_rect()
	var position_in_screen := visible_rect.position + (visible_rect.size * screen_pos)
	var canvas_transform := get_viewport().get_canvas_transform()
	var world_position: Vector2 = canvas_transform.affine_inverse() * position_in_screen 
	target_pos = world_position

	timer += delta * 1

	if souls_to_spawn.size() > 0:
		soul_spawn_timer += delta * (souls_to_spawn.size() * 10)

		if soul_spawn_timer > 0.05:
			# if souls_to_spawn.size() > 8:
			# 	spawn_soul(souls_to_spawn.pop_front())

			if souls_to_spawn.size() > 4:
				spawn_soul(souls_to_spawn.pop_front())
			
			if souls_to_spawn.size() > 0:
				spawn_soul(souls_to_spawn.pop_front())

	for soul in souls:
		if !soul.active:
			continue

		soul.trail.add_point(soul.trail_target.position)

		if soul.trail.points.size() > trail_max_points:
			soul.trail.remove_point(0)

		if soul.trail.points.size() > 2:
			var direction: Vector2 = soul.trail.points[soul.trail.points.size() - 1] - soul.trail.points[soul.trail.points.size() - 2]
			soul.sprite.rotation = direction.angle()
			soul.sprite.rotation_degrees += 90
