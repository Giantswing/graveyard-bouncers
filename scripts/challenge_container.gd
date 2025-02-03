extends Node2D

var player: PlayerCharacter
@onready var start_point: Node2D = $ChallengeScene/StartPoint
var player_start_position: Vector2
@onready var transition: Node2D = $Transition

func _ready() -> void:
	Events.enter_challenge_mode.connect(start_challenge)
	Events.exit_challenge_mode.connect(exit_challenge)
	transition.hide()

func start_challenge(enter_player: PlayerCharacter) -> void:
	transition.show()
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		transition.hide()
	)

	player = enter_player
	player_start_position = player.global_position
	player.global_position = start_point.global_position

func exit_challenge(_exit_player: PlayerCharacter) -> void:
	transition.show()
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		transition.hide()
	)

	player.global_position = player_start_position
	player.extra_speed = Vector2(-100, 0)

