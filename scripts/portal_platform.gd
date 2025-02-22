extends StaticBody2D

# @onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var portal: ChallengePortal = $Collision/ChallengePortal
var show_portal_at_beginning: bool = false

# func _ready() -> void:
	# Events.round_ended.connect(show_platform)
	# Events.round_countdown_start.connect(hide_platform)
	# hide_platform(1)


func _process(delta: float) -> void:
	if show_portal_at_beginning == false and GameManager.get_instance().current_round == 0:
		portal.process_mode = Node.PROCESS_MODE_DISABLED
		set_collision_layer_value(1, false)
		hide()
	else:
		portal.process_mode = Node.PROCESS_MODE_PAUSABLE
		set_collision_layer_value(1, true)
		show()
	

func hide_platform(_time: int) -> void:
	set_collision_layer_value(1, false)
	portal.hide()
	portal.process_mode = Node.PROCESS_MODE_DISABLED
	Utils.fast_tween(self, "rotation_degrees", 270, 0.5).tween_property(collision, "position", Vector2(-36, 23), 0.5)

func show_platform() -> void:
	get_tree().create_timer(2).timeout.connect(
		func() -> void:
			portal.show()
			portal.process_mode = Node.PROCESS_MODE_PAUSABLE
			portal.active = true
			set_collision_layer_value(1, true)
			Utils.fast_tween(self, "rotation_degrees", 180, 0.5).tween_property(collision, "position", Vector2(-36, -3), 0.5)
	)
