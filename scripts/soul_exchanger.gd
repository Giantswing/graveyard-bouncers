extends Node2D

@onready var activate_area: Area2D = $Area2D
@onready var cost_label: Label = %SoulExchangerCost

@export var heart_reward: PackedScene

var time_with_player_inside: float = 0
var trigger_time: float = 1
var subsequent_trigger_time: float = 0.08
var cost_increase: int = 5

var holding_souls: int = 0
var max_holding_souls: int = 15
var can_charge: bool = true 

func _ready() -> void:
	Events.soul_remove_finished.connect(add_holding_soul)
	Events.round_ended.connect(on_round_ended)
	on_round_ended()
	update_cost_label()

func on_round_ended() -> void:
	if cost_label == null:
		cost_label = %SoulExchangerCost

	cost_label.modulate = Color(1, 1, 1, 0)
	get_tree().create_timer(2).timeout.connect(func() -> void:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(cost_label, "modulate:a", 1, 2)
	)

func add_holding_soul() -> void:
	holding_souls += 1

	if holding_souls >= max_holding_souls:
		on_max_holding_souls_reached()

	update_cost_label()

func on_max_holding_souls_reached() -> void:
	holding_souls = 0
	max_holding_souls += cost_increase
	cost_increase += cost_increase
	var new_reward: Node2D = heart_reward.instantiate()
	new_reward.global_position = global_position
	get_parent().add_child(new_reward)

	update_cost_label()


func update_cost_label() -> void:
	cost_label.text = str(holding_souls) + "/" + str(max_holding_souls)

func _process(delta: float) -> void:
	if activate_area.get_overlapping_bodies().size() > 0:
		time_with_player_inside += delta

		if time_with_player_inside > trigger_time:
			time_with_player_inside = trigger_time - subsequent_trigger_time
			var remaining_souls: int = 0
			remaining_souls = GameManager.get_instance().score - FxSystem.get_negative_soul_count()

			if remaining_souls > 0:
				Events.soul_exchanger_activated.emit(global_position)

			var future_souls: int = holding_souls + FxSystem.get_negative_soul_count()
			if future_souls >= max_holding_souls:
				time_with_player_inside = -1.75
	else:
		time_with_player_inside = 0
