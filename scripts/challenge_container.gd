extends Node2D

@onready var transition: Node2D = $Transition
@onready var scene_container: Node2D = $SceneContainer
@onready var exit_area: Area2D = $ExitArea

var player_start_position: Vector2
var player: PlayerCharacter
var challenge_active: bool = false
var start_point: Node2D
var detect_exit: bool = false



func _ready() -> void:
	Events.set_up_challenge.connect(set_up_challenge)
	Events.enter_challenge_mode.connect(start_challenge)
	Events.exit_challenge_mode.connect(exit_challenge)

	exit_area.body_entered.connect(func(body: Node) -> void:
		if body is PlayerCharacter and detect_exit:
			print("Player has exited the challenge")
			Events.exit_challenge_mode.emit(body as PlayerCharacter)
	)
	
	transition.hide()

func set_up_challenge(challenge: Challenge) -> void:
	for child in scene_container.get_children():
		scene_container.remove_child(child)
		child.queue_free()


	var scene_spawn: Node2D = challenge.scene.instantiate()
	scene_container.add_child(scene_spawn)

	start_point = scene_spawn.get_node("StartPoint")
	

func start_challenge(enter_player: PlayerCharacter) -> void:
	transition.show()
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		transition.hide()
	)

	challenge_active = true
	player = enter_player
	player_start_position = player.global_position
	player.global_position = start_point.global_position
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		detect_exit = true
	)

func exit_challenge(_exit_player: PlayerCharacter) -> void:
	transition.show()
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		for child in scene_container.get_children():
			scene_container.remove_child(child)
			child.queue_free()

		transition.hide()
	)

	challenge_active = false
	player.global_position = player_start_position
	player.extra_speed = Vector2(-1000.0, 0)
	player.velocity = Vector2(-100.0, 0)
