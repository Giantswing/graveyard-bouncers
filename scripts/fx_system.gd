extends Node2D

var fx_dict: Dictionary[String, FxResource] = {}
@onready var soul_holder: SoulHolder = $SoulHolder

func _ready() -> void:
	var fx_resources: Array[FxResource] = get_fx_resources("res://scenes/fx/resources")

	for fx_resource in fx_resources:
		fx_dict[fx_resource.key_name] = fx_resource

	set_up_fx_systems()

func set_up_fx_systems() -> void:
	for fx_name: String in fx_dict.keys():
		var fx: FxResource = fx_dict[fx_name]
		var fx_scene: PackedScene = fx.scene
		var amount: int = fx.amount

		var parent: Node2D = Node2D.new()
		parent.name = fx_name
		add_child(parent)

		fx_dict[fx_name].instances = []
		fx_dict[fx_name].start_times = {}

		for i in range(amount):
			var particles: GPUParticles2D = fx_scene.instantiate() as GPUParticles2D
			particles.position = Vector2(0, 0)
			particles.emitting = false
			particles.one_shot = true
			parent.add_child(particles)

			fx_dict[fx_name].instances.append(particles)
			fx_dict[fx_name].start_times[particles] = 0.0



func get_fx_resources(path: String) -> Array[FxResource]:
	var items: Array[FxResource] = []
	var dir := DirAccess.open(path)

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while file_name != "":
		if !file_name.begins_with(".") and !file_name.ends_with(".import"):
			var full_path: String = path + "/" + file_name

			if full_path.ends_with(".remap"):
				full_path = full_path.substr(0, full_path.length() - 6)

			if ResourceLoader.exists(full_path):
				var res: FxResource = ResourceLoader.load(full_path) as FxResource
				if res:
					items.append(res)

		file_name = dir.get_next()

	dir.list_dir_end()
	return items


func play_fx(fx_name: String, spawn_position: Vector2) -> void:
	var parent: Node2D = get_node(fx_name) as Node2D
	if !parent:
		return

	var fx: GPUParticles2D = find_available_fx(fx_name)
	if fx == null:
		print("No available particle systems for " + fx_name)
		return

	fx.position = spawn_position
	fx.restart()
	fx.emitting = true

	# Store the current time as the start time
	fx_dict[fx_name].start_times[fx] = Time.get_ticks_msec()


func find_available_fx(fx_name: String) -> GPUParticles2D:
	var parent: Node2D = get_node(fx_name) as Node2D
	if !parent:
		return null

	var fx_data := fx_dict[fx_name]
	var oldest_fx: GPUParticles2D = null

	# Current time for comparison
	var oldest_time: int = Time.get_ticks_msec()

	for particles: GPUParticles2D in fx_data.instances:
		#If we found one that is not emitting, return it inmediatly
		if !particles.emitting:
			return particles

		# Otherwise, check if it is the oldest one
		var start_time: int = fx_data.start_times.get(particles, oldest_time)

		if start_time < oldest_time:
			oldest_time = start_time
			oldest_fx = particles

	# Reuse the oldest active particle system
	return oldest_fx
