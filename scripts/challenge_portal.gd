extends Node2D

class_name ChallengePortal

@onready var area: Area2D = $Area2D
@export var enter: bool = true
@export var active: bool = true

func _ready() -> void:
	area.body_entered.connect(detect_player)

func detect_player(body: Node) -> void:
	if !active:
		return

	if body is PlayerCharacter:
		active = false

		if enter:
			Events.enter_challenge_mode.emit(body as PlayerCharacter)
		else:
			Events.exit_challenge_mode.emit(body as PlayerCharacter)
	
