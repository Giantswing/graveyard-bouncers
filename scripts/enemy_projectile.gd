extends StaticBody2D

class_name EnemyProjectile

@onready var sprite: AnimatedSprite2D = $Sprite

var owner_stats: Stats
var velocity: Vector2 = Vector2()
var point_to_velocity: bool = true
var target_scale: Vector2 = Vector2(1, 1)
var alive_max_time: float = 5
var last_pos: Vector2 = Vector2()
var returning: bool = false
var points: Array[Vector2] = []

@onready var stats: Stats = $Stats

func _ready() -> void:
	scale = Vector2.ZERO
	Utils.fast_tween(self, "scale", target_scale, 0.2)
	get_tree().create_timer(alive_max_time).timeout.connect(func() -> void:
		queue_free()
	)

	stats.on_parry.connect(process_parry)

func process_parry() -> void:
	velocity = Vector2.ZERO
	returning = true
	# stats.take_damage(1, true, true)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", owner_stats.global_position, 0.3)
	tween.finished.connect(func() -> void:
		owner_stats.take_damage(2, true)
		queue_free()
	)


func _process(delta: float) -> void:
	position += velocity * delta
	points.append(global_position)

	if(points.size() > 3):
		points.remove_at(0)

	if point_to_velocity and points.size() > 2:
		var dir := (points[1] - points[0]).angle()
		sprite.rotation = dir
		sprite.rotation_degrees += 90

func _physics_process(delta: float) -> void:
	last_pos = global_position
