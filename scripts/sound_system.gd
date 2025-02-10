extends Node2D

@export var amount_of_audio_players: int = 10

var sfx_dict: Dictionary[String, SoundResource]

var audio_players: Array[AudioStreamPlayer2D] = []

func _ready() -> void:
	var sound_resources: Array[SoundResource] = get_sound_resources("res://sounds/sfx_sound_resources")

	for sound_resource in sound_resources:
		sfx_dict[sound_resource.key_name] = sound_resource
	
	print(sfx_dict)

	set_up_audio_players()

func get_sound_resources(path: String) -> Array[SoundResource]:
	var items: Array[SoundResource] = []
	var dir := DirAccess.open(path)

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while file_name != "":
		if !file_name.begins_with(".") and !file_name.ends_with(".import"):
			var full_path: String = path + "/" + file_name

			if full_path.ends_with(".remap"):
				full_path = full_path.substr(0, full_path.length() - 6)

			if ResourceLoader.exists(full_path):
				var res: SoundResource = ResourceLoader.load(full_path) as SoundResource
				if res:
					items.append(res)

		file_name = dir.get_next()

	dir.list_dir_end()
	return items



func set_up_audio_players() -> void:
	for i in range(amount_of_audio_players):
		var audio_player := AudioStreamPlayer2D.new()
		audio_player.volume_db = 0 
		audio_player.autoplay = false
		audio_player.bus = "SFX"
		audio_player.max_distance = 2000.0
		audio_player.name = "audio_player_" + str(i)
		audio_players.append(audio_player)
		add_child(audio_player)


func find_player() -> AudioStreamPlayer2D:
	for audio_player in audio_players:
		if not audio_player.playing:
			return audio_player

	return audio_players[0]


func play_audio(audio_name: String) -> void:
	var audio_player := find_player()

	var audio_resource: SoundResource = sfx_dict[audio_name]

	audio_player.stream = audio_resource.select_stream()
	audio_player.volume_db = audio_resource.volume_db

	audio_player.pitch_scale = audio_resource.base_pitch + randf_range(-audio_resource.pitch_range, audio_resource.pitch_range)

	if GameManager.instance.player != null:
		audio_player.global_position = GameManager.instance.player.global_position

	if audio_player.stream != null:
		audio_player.play()


func stop_audio(audio_name: String) -> void:
	for audio_player in audio_players:
		if audio_player.stream != null and audio_player.stream.name == audio_name:
			audio_player.stop()
			return
