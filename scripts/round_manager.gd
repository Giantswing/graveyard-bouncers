extends Node2D

class_name RoundManager

@export var game_rounds: Array[GameRound]
@export var chance_decay_rate: float = 0.4
@export var difficulty_match_strictness: float = 10

@export var game_challenges: Array[Challenge]

func _ready() -> void:
    for game_round in game_rounds:
        game_round.init()


func get_challenge(difficulty: float) -> Challenge:
    for challenge in game_challenges:
        if challenge.debug == true:
            return challenge

    var weighted_chances := []
    var total_weighted_chance: float = 0

    for challenge in game_challenges:
        var difficulty_difference: float = abs(challenge.difficulty - difficulty)
        var difficulty_weight: float = exp(-difficulty_difference * difficulty_match_strictness)
        var weighted_chance: float = challenge.chance * difficulty_weight

        weighted_chances.append(weighted_chance)
        total_weighted_chance += weighted_chance

    var random_value := randf() * total_weighted_chance
    var cumulative_chance := 0.0

    for i in range(weighted_chances.size()):
        cumulative_chance += weighted_chances[i]
        if random_value <= cumulative_chance:
            game_challenges[i].chance *= chance_decay_rate
            return game_challenges[i]

    return game_challenges[0]

func get_round(difficulty: float) -> GameRound:
    # Calculate total weighted chance for all rounds
    for game_round in game_rounds:
        if game_round.debug == true:
            return game_round

    var weighted_chances := []
    var total_weighted_chance: float = 0

    for game_round in game_rounds:
        var difficulty_difference: float = abs(game_round.difficulty - difficulty)
        var difficulty_weight: float = exp(-difficulty_difference * difficulty_match_strictness)
        var weighted_chance: float = game_round.chance * difficulty_weight

        weighted_chances.append(weighted_chance)
        total_weighted_chance += weighted_chance

    var random_value := randf() * total_weighted_chance
    var cumulative_chance := 0.0

    for i in range(weighted_chances.size()):
        cumulative_chance += weighted_chances[i]
        if random_value <= cumulative_chance:
            game_rounds[i].chance *= chance_decay_rate
            return game_rounds[i]

    # Fallback in case no round is selected
    return game_rounds[0]
