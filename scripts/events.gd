extends Node2D

@warning_ignore_start("unused_signal")

signal coins_changed(score: int)
signal hp_changed(new_hp: int, change: int)
signal max_hp_changed(new_max_hp: int, change: int)
signal picked_up_powerup(powerup: PowerUp)
signal player_died
signal player_hit
signal player_parry
signal round_counter_changed(round: int)
signal round_ended
signal round_started
signal round_time_changed(time: int)
signal game_started
signal score_changed(score: int)
