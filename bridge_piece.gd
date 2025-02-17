extends StaticBody2D

class_name BridgePiece

@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape

var colliding_with_player: bool = false

func _ready() -> void:
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)

func on_body_entered(body: Node2D) -> void:
	colliding_with_player = true

func on_body_exited(body: Node) -> void:
	colliding_with_player = false

func allow_from_below() -> void:
	collision_shape.one_way_collision = true
