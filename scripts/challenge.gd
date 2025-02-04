extends Resource

class_name Challenge

@export var debug: bool = false
@export var scene: PackedScene
@export var chance: float = 1.0
@export var difficulty: float = 1

var original_chance: float
var active: bool = false
