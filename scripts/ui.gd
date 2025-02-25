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
@export var ui_pickup_scene: PackedScene

@onready var pause_screen: Control = %PauseScreen
@onready var powerup_list: Control = %PowerUpList

@onready var countdown_screen: Control = %CountdownScreen
@onready var countdown_label: Label = %CountdownLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var countdown_timer: Timer = %CountdownTimer

@onready var top_left_container: Control = %TopLeft
@onready var top_right_container: Control = %TopRight
@onready var bottom_left_container: Control = %BottomLeft
@onready var bottom_right_container: Control = %BottomRight

var hearts: Array[ui_heart] = []
var selected_menu_option: int = 0
var menu_options: Array[Node] = []
var current_countdown_time: int = 0

var objective_show_position: Vector2 = Vector2(115, 247)
var objective_hide_position: Vector2 = Vector2(363, 61)

func _ready() -> void:
	menu_options = %MenuOptions.get_children()

	death_screen.visible = false
	pause_screen.visible = false
	countdown_screen.visible = false
	objective_label.visible = false
	Events.score_changed.connect(on_score_changed)
	Events.hp_changed.connect(on_hp_changed)
	Events.max_hp_changed.connect(on_max_hp_changed)
	Events.round_time_changed.connect(on_round_time_changed)
	Events.player_died.connect(on_player_died)
	Events.coins_changed.connect(on_coins_changed)
	Events.round_counter_changed.connect(on_round_counter_changed)
	Events.ability_gained.connect(on_ability_gained)
	Events.game_paused.connect(on_game_paused)
	Events.picked_up_powerup.connect(on_picked_up_powerup)
	Events.round_countdown_start.connect(start_countdown)
	Events.round_ended.connect(on_round_ended)

	var original_countdown_font_size: float = countdown_label.label_settings.font_size
	var increased_countdown_font_size: int = roundi(original_countdown_font_size * 1.5)
	countdown_timer.timeout.connect(func() -> void:
		current_countdown_time -= 1

		countdown_label.label_settings.font_size = increased_countdown_font_size
		var tween2: Tween = get_tree().create_tween()
		tween2.tween_property(countdown_label.label_settings, "font_size", original_countdown_font_size, 0.25)

		countdown_label.text = str(current_countdown_time)
		if current_countdown_time <= 0:
			countdown_screen.visible = false
			countdown_timer.stop()
			var tween := get_tree().create_tween()
			
			tween.set_parallel(true)
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(objective_label, "position", objective_hide_position, 0.3)
			tween.tween_property(objective_label, "label_settings:font_size", 12, 0.3)
	)

func on_round_ended() -> void:
	objective_label.visible = false
	objective_label.position = objective_show_position
	objective_label.label_settings.font_size = 30

func start_countdown(time: int) -> void:
	var original_countdown_font_size: float = countdown_label.label_settings.font_size
	var increased_countdown_font_size: int = roundi(original_countdown_font_size * 1.5)
	objective_label.visible = true
	objective_label.position = Vector2(124.5, 226)
	objective_label.label_settings.font_size = 30

	var objective: String = ""
	var mode: int = GameManager.get_instance().round_data.mode

	match mode:
		GameRound.ROUND_MODES.TIME_LIMIT:
			objective = "Survive for " + str(GameManager.get_instance().round_data.time_limit) + " seconds"

		GameRound.ROUND_MODES.ENEMY_COUNT:
			objective = "Defeat " + str(GameManager.get_instance().round_data.enemy_count) + " enemies"

		GameRound.ROUND_MODES.COLLECT:
			objective = "Collect " + str(GameManager.get_instance().round_data.collect_amount) + " soul cubes"

	objective_label.text = objective

	countdown_label.label_settings.font_size = increased_countdown_font_size
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(countdown_label.label_settings, "font_size", original_countdown_font_size, 0.25)
	countdown_timer.start()
	countdown_timer.wait_time = 1
	countdown_screen.visible = true
	current_countdown_time = time
	countdown_label.text = str(current_countdown_time)



func on_picked_up_powerup(powerup: PowerUp) -> void:
	var pickup: Control =  ui_pickup_scene.instantiate()
	var pickup_sprite: AnimatedSprite2D = pickup.get_node("AnimatedSprite2D") as AnimatedSprite2D
	pickup_sprite.sprite_frames = powerup.frames
	powerup_list.add_child(pickup)


func update_menu_options() -> void:
	for i in range(menu_options.size()):
		if i == selected_menu_option:
			menu_options[i].modulate = Color(1, 1, 1, 1)
		else:
			menu_options[i].modulate = Color(1, 1, 1, 0.3)
	

func _process(_delta: float) -> void:
	update_ui_transparency()

	if GameManager.instance.game_paused == false:
		return

	if Input.is_action_just_pressed("Up"):
		selected_menu_option -= 1
		if selected_menu_option < 0:
			selected_menu_option = menu_options.size() - 1
		update_menu_options()

	if Input.is_action_just_pressed("Down"):
		selected_menu_option += 1
		if selected_menu_option >= menu_options.size():
			selected_menu_option = 0
		update_menu_options()

	if Input.is_action_just_pressed("Jump"):
		process_menu_option(selected_menu_option)

func process_menu_option(option: int) -> void:
	match option:
		0:
			GameManager.get_instance().pause_game(false)
		1:
			GameManager.get_instance().restart_level()
		2:
			GameManager.get_instance().exit_game()

func on_game_paused(paused: bool) -> void:
	pause_screen.visible = paused

func on_ability_gained(ability: Ability) -> void:
	if ability == null:
		ability_sprite.visible = false
		ability_name.text = ""
		ability_uses.text = ""
		return

	if ability.uses <= 0:
		ability_sprite.modulate = Color(1, 1, 1, 0.3)
	else:
		ability_sprite.modulate = Color(1, 1, 1, 1)

	ability_sprite.visible = true
	ability_sprite.sprite_frames = ability.frames
	ability_sprite.play("default")
	ability_name.text = ability.name
	ability_uses.text = str(ability.uses)


func on_round_counter_changed(new_round: int) -> void:
	round_label.text = "Round " + str(new_round)

func on_coins_changed(new_coins: int) -> void:
	coins_label.text = str(new_coins)

func on_round_time_changed(new_time: int) -> void:
	time_label.text = "Time " + str(new_time)

func on_player_died() -> void:
	death_score_label.text = str(GameManager.get_instance().score)
	death_screen.visible = true
	
func on_score_changed(new_score: int) -> void:
	score_label.text = "Souls " + str(new_score)


func update_ui_transparency() -> void:
	var player_screen_pos: Vector2 = GameManager.instance.player_screen_pos
	var x_offset: float = 0.3
	var y_offset: float = 0.4
	var faded_color: Color = Color(1, 1, 1, 0.1)
	var full_color: Color = Color(1, 1, 1, 0.7)

	if player_screen_pos.x < x_offset && player_screen_pos.y < y_offset:
		top_left_container.modulate = lerp(top_left_container.modulate, faded_color, 0.1)
	else:
		top_left_container.modulate = lerp(top_left_container.modulate, full_color, 0.1)

	if player_screen_pos.x > 1 - x_offset && player_screen_pos.y < y_offset:
		top_right_container.modulate = lerp(top_right_container.modulate, faded_color, 0.1)
	else:
		top_right_container.modulate = lerp(top_right_container.modulate, full_color, 0.1)
	
	if player_screen_pos.x < x_offset && player_screen_pos.y > 1 - y_offset:
		bottom_left_container.modulate = lerp(bottom_left_container.modulate, faded_color, 0.1)
	else:
		bottom_left_container.modulate = lerp(bottom_left_container.modulate, full_color, 0.1)

	if player_screen_pos.x > 1 - x_offset && player_screen_pos.y > 1 - y_offset:
		bottom_right_container.modulate = lerp(bottom_right_container.modulate, faded_color, 0.1)
	else:
		bottom_right_container.modulate = lerp(bottom_right_container.modulate, full_color, 0.1)


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
	
