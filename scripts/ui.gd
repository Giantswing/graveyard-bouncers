extends Control

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var heart_container: HBoxContainer = %HeartContainer
@onready var death_screen: Control = %DeathScreen
@onready var death_score_label: Label = %DeathScoreLabel
@onready var coins_label: Label = %CoinsLabel
@onready var round_label: Label = %RoundLabel

@onready var ability_sprite: AnimatedSprite2D = %AbilitySprite
@onready var ability_name: Label = %AbilityName
@onready var ability_uses: Label = %AbilityAmount

@export var ui_heart_scene: PackedScene

@onready var pause_screen: Control = %PauseScreen

var hearts: Array[ui_heart] = []

func _ready() -> void:
	death_screen.visible = false
	pause_screen.visible = false

	Events.score_changed.connect(on_score_changed)
	Events.hp_changed.connect(on_hp_changed)
	Events.max_hp_changed.connect(on_max_hp_changed)
	Events.round_time_changed.connect(on_round_time_changed)
	Events.player_died.connect(on_player_died)
	Events.coins_changed.connect(on_coins_changed)
	Events.round_counter_changed.connect(on_round_counter_changed)
	Events.ability_gained.connect(on_ability_gained)
	Events.game_paused.connect(on_game_paused)

func on_game_paused(paused: bool) -> void:
	pause_screen.visible = paused

func on_ability_gained(ability: Ability) -> void:
	if ability == null:
		ability_sprite.visible = false
		ability_name.text = ""
		ability_uses.text = ""
		return

	ability_sprite.visible = true
	ability_sprite.sprite_frames = ability.frames
	ability_sprite.play("default")
	ability_name.text = ability.name
	ability_uses.text = str(ability.uses)


func on_round_counter_changed(new_round: int) -> void:
	round_label.text = "Round: " + str(new_round)

func on_coins_changed(new_coins: int) -> void:
	coins_label.text = str(new_coins)

func on_round_time_changed(new_time: int) -> void:
	time_label.text = "Time: " + str(new_time)

func on_player_died() -> void:
	death_score_label.text = str(GameManager.get_instance().score)
	death_screen.visible = true
	
func on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func on_max_hp_changed(new_max_hp: int) -> void:
	for i in range(hearts.size()):
		hearts[i].queue_free()

	hearts.clear()

	for i in range(new_max_hp):
		var heart := ui_heart_scene.instantiate() as ui_heart
		heart_container.add_child(heart)
		heart.set_heart_state(true)
		hearts.append(heart)

func on_hp_changed(new_hp: int, _change: int) -> void:
	for i in range(hearts.size()):
		if i < new_hp:
			hearts[i].set_heart_state(true)
		else:
			hearts[i].set_heart_state(false)
	
