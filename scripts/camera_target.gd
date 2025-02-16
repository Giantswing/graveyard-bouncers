extends Node2D

class_name CameraTarget

@export var importance: Vector2 = Vector2.ZERO
@export var offset: Vector2 = Vector2.ZERO
@export var max_distance: float = 500.0


func _enter_tree() -> void:
	get_tree().create_timer(0.1).timeout.connect(func() -> void: Events.ctarget_add.emit(self))

func _exit_tree() -> void:
	Events.ctarget_remove.emit(self)
