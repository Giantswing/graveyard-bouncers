extends Node

func fast_tween(target: Object, property: String, value: Variant, duration: float, trans: int = Tween.TRANS_LINEAR) -> Tween:
	var tween := get_tree().create_tween()
	tween.set_trans(trans)
	tween.tween_property(target, property, value, duration)
	return tween

func spawn_prefab_from_list(list: Array[PrefabChance], container: Node2D, max_amount: int) -> void:
	if container.get_child_count() >= max_amount:
		return

	var total_chance: float = 0
	for prefab_chance in list:
		total_chance += prefab_chance.chance

	var chance: float = randf() * total_chance
	var current_chance: float = 0

	for prefab_chance in list:
		current_chance += prefab_chance.chance
		if chance <= current_chance:
			spawn_prefab(prefab_chance.prefab, container, prefab_chance.spawn_type, prefab_chance.free_space)
			return



func spawn_prefab(prefab: PackedScene, container: Node2D, pos_type: PrefabChance.SPAWN_POS_OPTIONS, free_space: float) -> Node2D:
	var new_prefab: Node2D = prefab.instantiate()
	var spawn_pos: Vector2 = Vector2.ZERO

	if container == null:
		container = $"/root/Level/Scenery/OtherContainer" 

	var horizontal_wall_padding = 10
	var max_tries = 20
	var game_width = GameManager.instance.game_width

	for i in range(max_tries):
		var pos_x = randf_range(-game_width / 2 + horizontal_wall_padding, game_width / 2 - horizontal_wall_padding)
		var pos_y = 147

		if pos_type == PrefabChance.SPAWN_POS_OPTIONS.AIR:
			pos_y = randf_range(90, 147)
		elif pos_type == PrefabChance.SPAWN_POS_OPTIONS.REWARD:
			pos_y = randf_range(0, -150)
		elif pos_type == PrefabChance.SPAWN_POS_OPTIONS.AIR_OUTSIDE:
			pos_y = randf_range(90, -120)
			var side = randf() < 0.5
			# var side = randf() > 1 

			pos_x = -game_width / 2 - 80 if side else game_width / 2 + 80

		spawn_pos = Vector2(pos_x, pos_y)

		var is_free: bool = true

		for unit in container.get_children():
			if unit.position.distance_to(spawn_pos) < free_space:
				is_free = false
				break

		var player = GameManager.instance.player

		if player and player.position.distance_to(spawn_pos) < free_space:
			is_free = false

		if not is_free:
			continue

		new_prefab.position = spawn_pos
		container.add_child(new_prefab)
		return new_prefab

	return null
