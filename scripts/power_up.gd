extends Resource

class_name PowerUp 

@export var frames: SpriteFrames
@export var power_up_name: String = "Power Up"
@export var power_up_description: String = "This is a power up"
@export var chance: float = 1
@export var cost: int = 1
@export var amount: int = 1

var original_chance: float
var original_cost: int
var original_amount: int
var active: bool = true 
