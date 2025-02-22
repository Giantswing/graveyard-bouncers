extends Node2D

var game_manager: GameManager

func _ready() -> void:
	game_manager = GameManager.get_instance()

func _process(delta: float) -> void:
	if game_manager.game_mode == GameManager.MODES.BEFORE_ROUND or game_manager.game_mode == GameManager.MODES.CHALLENGE_MODE:
		position = lerp(position, Vector2(0, -400), 0.05)
	else:
		position = lerp(position, Vector2(0, -256), 0.05)
