extends Control

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var heart_container: HBoxContainer = %HeartContainer
@onready var death_screen: Control = %DeathScreen
@onready var death_score_label: Label = %DeathScoreLabel
@onready var coins_label: Label = %CoinsLabel
@onready var round_label: Label = %RoundLabel

@export var ui_heart_scene: PackedScene

var hearts: Array[ui_heart] = []

func _ready() -> void:
	death_screen.visible = false

	for i in range(GameManager.player_hp_max):
		var heart = ui_heart_scene.instantiate() as ui_heart
		heart_container.add_child(heart)
		heart.set_heart_state(true)
		hearts.append(heart)

	Events.score_changed.connect(on_score_changed)
	Events.hp_changed.connect(on_hp_changed)
	Events.round_time_changed.connect(on_round_time_changed)
	Events.player_died.connect(on_player_died)
	Events.coins_changed.connect(on_coins_changed)
	Events.round_counter_changed.connect(on_round_counter_changed)

	Events.round_time_changed.emit(0)
	Events.score_changed.emit(0)
	Events.hp_changed.emit(GameManager.player_hp_max, 0)
	Events.coins_changed.emit(1)
	Events.round_counter_changed.emit(0)

func on_round_counter_changed(new_round: int) -> void:
	round_label.text = "Round: " + str(new_round)

func on_coins_changed(new_coins: int) -> void:
	coins_label.text = str(new_coins)

func on_round_time_changed(new_time: int) -> void:
	time_label.text = "Time: " + str(new_time)

func on_player_died() -> void:
	death_score_label.text = str(GameManager.score)
	death_screen.visible = true
	
func on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func on_hp_changed(new_hp: int, _change: int) -> void:
	for i in range(hearts.size()):
		if i < new_hp:
			hearts[i].set_heart_state(true)
		else:
			hearts[i].set_heart_state(false)
	
