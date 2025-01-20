extends Node2D

@warning_ignore_start("unused_signal")

signal coins_changed(score: int)
signal hp_changed(new_hp: int, change: int)
signal level_restarted
signal player_died
signal player_hit
signal player_parry
signal round_ended
signal round_started
signal round_time_changed(time: int)
signal round_counter_changed(round: int)
signal score_changed(score: int)
