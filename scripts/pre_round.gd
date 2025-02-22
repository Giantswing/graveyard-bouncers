extends Node2D

var sprite_children: Array[AnimatedSprite2D] = []
var node_children: Array[Node] = []
var child_delay: float = 0.1
var dissolve_duration: float = 0.8

func _ready() -> void:
	sprite_children.clear()
	node_children = get_children()

	find_by_class(self, "AnimatedSprite2D", sprite_children)

	for child in sprite_children:
		if child.material == null:
			child.material = load("res://shaders/materials/MasterMaterial.tres").duplicate()

	show_children()

	Events.round_ended.connect(func() -> void:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			show_children()
		)
	)

	Events.round_countdown_start.connect(func(time: int) -> void:
		hide_children()
	)

func find_by_class(node: Node, className: String, result: Array) -> void:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		find_by_class(child, className, result)

func hide_children() -> void:
	for i in range(sprite_children.size() - 1, -1, -1):
		hide_child(sprite_children[i], sprite_children.size() - 1 - i)

func show_children() -> void:
	for i in range(sprite_children.size()):
		show_child(sprite_children[i], i)

func hide_child(child: AnimatedSprite2D, index: int) -> void:
	child.material.set_shader_parameter("dissolve_percentage", 1.0)
	get_tree().create_timer(child_delay * index).timeout.connect(func() -> void:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(child, "material:shader_parameter/dissolve_percentage", 0.0, dissolve_duration)
		tween.finished.connect(func() -> void:
			child.hide()
			node_children[index].process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
		)
	)

func show_child(child: AnimatedSprite2D, index: int) -> void:
	child.material.set_shader_parameter("dissolve_percentage", 0.0)
	node_children[index].process_mode = Node.ProcessMode.PROCESS_MODE_PAUSABLE

	get_tree().create_timer(child_delay * index).timeout.connect(func() -> void:
		child.show()
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(child, "material:shader_parameter/dissolve_percentage", 1.0, dissolve_duration)
	)
