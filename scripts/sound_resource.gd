extends Resource

class_name SoundResource

enum SEQ_TYPES {
	SECUENTIAL,
	RANDOM,
}

@export var key_name: String = ""
@export var streams: Array[AudioStream] = []
@export var seq_type: SEQ_TYPES = SEQ_TYPES.SECUENTIAL
@export var volume_db: float = 0.0

@export var base_pitch: float = 1.0
@export var pitch_range: float = 0.0

var current_stream: int = 0

func select_stream() -> AudioStream:
	match seq_type:
		SEQ_TYPES.SECUENTIAL:
			current_stream += 1
			if current_stream >= streams.size():
				current_stream = 0
		SEQ_TYPES.RANDOM:
			current_stream = randi() % streams.size()
	
	return streams[current_stream]
