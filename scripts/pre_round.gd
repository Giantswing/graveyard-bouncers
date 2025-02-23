extends Node2D

@export var dissolve_duration: float
@export var desired_total_duration: float
@export var appear_delay: float

var targets: Array[PreRoundTarget]
var child_delay: float


class PreRoundTarget:
	var initial_pos: Vector2
	var parent: Node
	var sprites: Array[AnimatedSprite2D]

	func _init(parent_node: Node) -> void:
		parent = parent_node
		initial_pos = parent.position
		sprites = []
		find_sprites(parent, sprites)
		for sprite in sprites:
			if sprite.material == null:
				sprite.material = load("res://shaders/materials/MasterMaterial.tres").duplicate()

	static func find_sprites(node: Node, result: Array) -> void:
		if node is AnimatedSprite2D:
			result.append(node)
		for child in node.get_children():
			find_sprites(child, result)



func _ready() -> void:
	child_delay = desired_total_duration / get_children().size()

	var ordered_children: Array[Node] = get_children()

	ordered_children.sort_custom(func(a: Node, b: Node) -> bool:
		return a.global_position.y > b.global_position.y
	)

	for i in range(ordered_children.size()):
		print(ordered_children[i].name)
		

	for ordered_child in ordered_children:
		targets.append(PreRoundTarget.new(ordered_child))

	for target in targets:
		target.parent.hide()
		target.parent.process_mode = Node.PROCESS_MODE_DISABLED

		for sprite in target.sprites:
			sprite.hide()


	get_tree().create_timer(appear_delay).timeout.connect(func() -> void:
		show_targets()
	)

	Events.round_ended.connect(func() -> void:
		get_tree().create_timer(appear_delay).timeout.connect(show_targets)
	)

	Events.round_countdown_start.connect(func(time: int) -> void:
		hide_targets()
	)

func hide_targets() -> void:
	for i in range(targets.size() - 1, -1, -1):
		hide_target(targets[i], targets.size() - 1 - i)

func show_targets() -> void:
	for i in range(targets.size()):
		show_target(targets[i], i)

func hide_target(target: PreRoundTarget, index: int) -> void:
	target.parent.process_mode = Node.PROCESS_MODE_DISABLED

	for sprite in target.sprites:
		sprite.material.set_shader_parameter("dissolve_percentage", 1.0)

	get_tree().create_timer(child_delay * index).timeout.connect(func() -> void:
		for sprite in target.sprites:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(sprite, "material:shader_parameter/dissolve_percentage", 0.0, dissolve_duration)
			tween.finished.connect(func() -> void:
				sprite.hide()
				target.parent.process_mode = Node.PROCESS_MODE_DISABLED
			)
	)

func show_target(target: PreRoundTarget, index: int) -> void:
	if target.parent.name == "PortalPlatform" and GameManager.get_instance().current_round == 0:
		return

	target.parent.show()
	target.parent.process_mode = Node.PROCESS_MODE_PAUSABLE
	target.parent.position = target.initial_pos

	get_tree().create_timer(child_delay * index).timeout.connect(func() -> void:
		for sprite in target.sprites:
			sprite.show()
			sprite.material.set_shader_parameter("dissolve_percentage", 0.0)
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(sprite, "material:shader_parameter/dissolve_percentage", 1.0, dissolve_duration)
	)
