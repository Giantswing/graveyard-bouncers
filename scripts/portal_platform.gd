extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var portal: ChallengePortal = $ChallengePortal

func _ready() -> void:
	Events.round_ended.connect(show_platform)
	Events.round_started.connect(hide_platform)


func hide_platform() -> void:
	set_collision_layer_value(1, false)
	portal.hide()
	portal.process_mode = Node.PROCESS_MODE_DISABLED
	Utils.fast_tween(self, "rotation_degrees", 270, 0.5).tween_property(sprite, "position", Vector2(-36, 15), 0.5)

func show_platform() -> void:
	get_tree().create_timer(2).timeout.connect(
		func() -> void:
			portal.show()
			portal.process_mode = Node.PROCESS_MODE_PAUSABLE
			portal.active = true
			set_collision_layer_value(1, true)
			Utils.fast_tween(self, "rotation_degrees", 180, 0.5).tween_property(sprite, "position", Vector2(-36, -1), 0.5)
	)
