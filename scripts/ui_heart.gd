extends Panel

class_name ui_heart 

@onready var Sprite: AnimatedSprite2D = $Sprite

func set_heart_state(is_filled: bool) -> void:
	if is_filled:
		Sprite.play("Filled")
	else:
		Sprite.play("Empty")
