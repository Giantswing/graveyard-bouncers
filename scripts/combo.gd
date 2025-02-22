extends Control

@onready var combo_counter: Label = %ComboCounter

var current_combo: int = 0
var combo_countdown: float = 0
var decrease_speed: float = 0.5

func _ready() -> void:	
	modulate = Color(1, 1, 1, 0)
	Events.picked_up_powerup.connect(on_picked_up_powerup)
	Events.combo_changed.connect(func(new_combo: int) -> void:
		update_combo_counter(new_combo)
	)

	hide()
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		update_combo_counter(0)
	)
	show()

func on_picked_up_powerup(powerup: PowerUp) -> void:
	if powerup.power_up_name == "combo-length":
		decrease_speed *= 0.5

func update_combo_counter(new_combo: int) -> void:
	combo_counter.text = str(new_combo)

	if new_combo >= current_combo and new_combo > 0:
		combo_countdown = 1

	if new_combo == 0:
		combo_countdown = 0

	current_combo = new_combo



func _process(delta: float) -> void:
	combo_countdown -= delta * decrease_speed
	combo_countdown = clamp(combo_countdown, 0, 1)

	if combo_countdown <= 0 and current_combo > 0:
		Events.combo_changed.emit(0)

	modulate.a = combo_countdown
	combo_counter.scale = lerp(combo_counter.scale, Vector2(1 + combo_countdown * 0.3, 1 + combo_countdown * 0.3), 0.1)
