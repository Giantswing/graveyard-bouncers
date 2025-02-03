extends Node2D

class_name ChallengePortal

@onready var area: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $PortalInside

@export var enter: bool = true
@export var active: bool = true
@export var portal_color: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	area.body_entered.connect(detect_player)

func _process(delta: float) -> void:
	if active:
		sprite.modulate = lerp(sprite.modulate, Color(portal_color.r, portal_color.g, portal_color.b, 1), 0.1 * delta * 60.0)
	else:
		sprite.modulate = lerp(sprite.modulate, Color(portal_color.r, portal_color.g, portal_color.b, 0), 0.1 * delta * 60.0)

func detect_player(body: Node) -> void:
	if !active:
		return

	if body is PlayerCharacter:
		active = false

		if enter:
			Events.enter_challenge_mode.emit(body as PlayerCharacter)
		else:
			Events.exit_challenge_mode.emit(body as PlayerCharacter)
	
