extends Node2D

@export var amount_of_audio_players: int = 10

var sfx_dict: Dictionary[String, SoundResource]

var audio_players: Array[AudioStreamPlayer2D] = []

var music_players: Array[AudioStreamPlayer2D] = []
var current_music_player: int = 0

var mute_volume: float = -40

func _ready() -> void:
	var sound_resources: Array[SoundResource] = get_sound_resources("res://sounds/sfx_sound_resources")

	for sound_resource in sound_resources:
		sfx_dict[sound_resource.key_name] = sound_resource
	
	print(sfx_dict)

	set_up_audio_players()
	set_up_track_players()

	play_music("song-end-round")
	Events.round_started.connect(func() -> void:
		play_music("song-round")
	)
	Events.round_ended.connect(func() -> void:
		play_music("song-end-round")
	)
	Events.enter_challenge_mode.connect(func(_player: PlayerCharacter) -> void:
		play_music("song-challenge")
	)
	Events.exit_challenge_mode.connect(func(_player: PlayerCharacter) -> void:
		play_music("song-end-round")
	)


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


func set_up_track_players() -> void:
	var music_track := AudioStreamPlayer2D.new()
	music_track.volume_db = -8.0
	music_track.autoplay = true
	music_track.bus = "Music"
	music_track.max_distance = 2000.0
	music_track.name = "music_track"

	var music_track2 := AudioStreamPlayer2D.new()
	music_track2.volume_db = mute_volume
	music_track2.autoplay = true 
	music_track2.bus = "Music"
	music_track2.max_distance = 2000.0
	music_track2.name = "music_track2"

	music_players.append(music_track)
	music_players.append(music_track2)

	add_child(music_track)
	add_child(music_track2)



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


func play_music(audio_name: String, fadeout_time: float = 0.35) -> void:
	var selected_music_player: AudioStreamPlayer2D = music_players[current_music_player]
	var other_index := 0 if current_music_player == 1 else 1
	var other_music_player: AudioStreamPlayer2D = music_players[other_index]

	var audio_resource: SoundResource = sfx_dict[audio_name]
	selected_music_player.stream = audio_resource.select_stream()
	var volume_to := audio_resource.volume_db

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(other_music_player, "volume_db", mute_volume, fadeout_time)
	tween.tween_property(selected_music_player, "volume_db", volume_to, fadeout_time)

	selected_music_player.playing = true
	other_music_player.playing = true

	current_music_player = other_index



func _process(_delta: float) -> void:
	for music_player in music_players:
		music_player.global_position = GameManager.get_player_position()

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
