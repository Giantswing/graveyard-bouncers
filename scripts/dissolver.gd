extends Node2D

class_name DissolveScenery

@export var dissolve_duration: float
@export var desired_total_duration: float
@export var appear_delay: float
@export var show_pre_round: bool = false
@export var show_in_round: bool = false

var targets: Array[DissolveTarget]
var child_delay: float
var scenery_to_spawn: PackedScene = null

class DissolveTarget:
	var initial_pos: Vector2
	var parent: Node
	var sprites: Array[AnimatedSprite2D]
	var tile_layers: Array[TileMapLayer]

	func _init(parent_node: Node) -> void:
		parent = parent_node
		initial_pos = parent.position
		sprites = []
		find_sprites(parent, sprites)
		tile_layers = []
		find_tile_layers(parent, tile_layers)

		for sprite in sprites:
			if sprite.material == null:
				sprite.material = load("res://shaders/materials/MasterMaterial.tres").duplicate()

		for tile_layer in tile_layers:
			if tile_layer.material == null:
				tile_layer.material = load("res://shaders/materials/MasterMaterial.tres").duplicate()

	static func find_sprites(node: Node, result: Array) -> void:
		if node is AnimatedSprite2D:
			result.append(node)
		for child in node.get_children():
			find_sprites(child, result)

	static func find_tile_layers(node: Node, result: Array) -> void:
		if node is TileMapLayer:
			result.append(node)
		for child in node.get_children():
			find_tile_layers(child, result)


func _ready() -> void:
	startup()

func startup() -> void:
	if show_pre_round:
		prepare_scenery()
		get_tree().create_timer(appear_delay * 0.25).timeout.connect(func() -> void:
			show_targets()
		)
		Events.round_ended.connect(func() -> void:
			get_tree().create_timer(appear_delay).timeout.connect(show_targets)
		)
		Events.round_countdown_start.connect(func(time: int) -> void:
			hide_targets()
		)

	elif show_in_round:
		if scenery_to_spawn == null:
			prepare_scenery()

		Events.round_ended.connect(func() -> void:
			hide_targets()
		)

		# Events.round_countdown_start.connect(func(time: int) -> void:
		# 	if scenery_to_spawn != null:
		# 		prepare_scenery()
		# )

		Events.round_started.connect(func() -> void:
			get_tree().create_timer(appear_delay).timeout.connect(show_targets)
		)


func add_scenery(scenery: PackedScene) -> void:
	scenery_to_spawn = scenery
	prepare_scenery()


func prepare_scenery() -> void:
	if scenery_to_spawn != null:
		for child in get_children():
			child.queue_free()

		targets = []

		var new_scenery: Node = scenery_to_spawn.instantiate()
		new_scenery.position = Vector2(0, 0)
		add_child(new_scenery)

		# for child in new_scenery.get_children():
		# 	add_child(child)
			


	child_delay = desired_total_duration / get_children().size()

	var ordered_children: Array[Node] = get_children()

	ordered_children.sort_custom(func(a: Node, b: Node) -> bool:
		return a.global_position.y > b.global_position.y
	)

	for ordered_child in ordered_children:
		targets.append(DissolveTarget.new(ordered_child))

	for target in targets:
		target.parent.hide()
		target.parent.process_mode = Node.PROCESS_MODE_DISABLED

		for sprite in target.sprites:
			sprite.hide()



func hide_targets() -> void:
	for i in range(targets.size() - 1, -1, -1):
		hide_target(targets[i], targets.size() - 1 - i)

func show_targets() -> void:
	for i in range(targets.size()):
		show_target(targets[i], i)

func hide_target(target: DissolveTarget, index: int) -> void:
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

		for tile_layer in target.tile_layers:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(tile_layer, "material:shader_parameter/dissolve_percentage", 0.0, dissolve_duration)
			tween.finished.connect(func() -> void:
				tile_layer.hide()
				tile_layer.collision_enabled = false
				target.parent.process_mode = Node.PROCESS_MODE_DISABLED
			)
	)

func show_target(target: DissolveTarget, index: int) -> void:
	# if target.parent.name == "PortalPlatform" and GameManager.get_instance().current_round == 0:
	# 	return

	target.parent.show()
	target.parent.process_mode = Node.PROCESS_MODE_PAUSABLE
	target.parent.position = target.initial_pos

	get_tree().create_timer(child_delay * index).timeout.connect(func() -> void:
		for sprite in target.sprites:
			sprite.show()
			sprite.material.set_shader_parameter("dissolve_percentage", 0.0)
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(sprite, "material:shader_parameter/dissolve_percentage", 1.0, dissolve_duration)

		for tile_layer in target.tile_layers:
			tile_layer.show()
			tile_layer.material.set_shader_parameter("dissolve_percentage", 0.0)
			tile_layer.collision_enabled = true
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(tile_layer, "material:shader_parameter/dissolve_percentage", 1.0, dissolve_duration)
	)
