extends Resource

class_name Challenge

@export var scene: PackedScene
@export var chance: float = 1.0
@export var debug: bool = false

var original_chance: float
var active: bool = false
