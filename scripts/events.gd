extends Node2D

@warning_ignore_start("unused_signal")

signal round_started
signal player_hit
signal score_changed(score: int)
signal player_parry
signal hp_changed(new_hp: int, change: int)
signal player_died
signal round_time_changed(time: int)
signal level_restarted
