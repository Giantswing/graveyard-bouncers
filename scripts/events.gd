extends Node2D

@warning_ignore_start("unused_signal")

signal coins_changed(score: int)
signal level_restart
signal hp_changed(new_hp: int, change: int)
signal max_hp_changed(new_max_hp: int, change: int)
signal picked_up_powerup(powerup: PowerUp)
signal player_died
signal player_hit
signal player_parry
signal player_dash
signal round_counter_changed(round: int)
signal round_ended
signal round_started
signal round_time_changed(time: int)
signal score_changed(score: int)
signal ability_gained(ability: Ability)
signal game_paused(paused: bool)
signal enter_challenge_mode(player: PlayerCharacter)
signal exit_challenge_mode(player: PlayerCharacter)
signal set_up_challenge(challenge: Challenge)
signal on_shockwave(force: float, duration: float, size: float, decay_time: float)
signal ctarget_add(target: CameraTarget)
signal ctarget_remove(target: CameraTarget)
signal round_countdown_start(time: int)
signal enemy_died(enemy: Stats, from_parry: bool)
signal enemy_hit(enemy: Stats, from_parry: bool)
signal pickup_collected(pickup: Pickup)
signal custom_shockwave(force: float, duration: float, size: float, decay_time: float)
signal custom_inverse_shockwave(force: float, duration: float, size: float, decay_time: float)
signal soul_exchanger_activated(position: Vector2)
signal soul_remove_finished()
