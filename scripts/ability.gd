extends Resource

class_name Ability

@export var name: String = "Ability"
@export var uses: int
@export var start_uses: int = 1
@export var original_max_uses: int = 1
var max_uses: int = 1
@export var frames: SpriteFrames
@export var cooldown: float = 0.0

var active: bool = false


func init() -> void:
	uses = start_uses
	max_uses = original_max_uses


func increase_uses(amount: int) -> void:
	uses += amount
	if uses > max_uses:
		uses = max_uses
