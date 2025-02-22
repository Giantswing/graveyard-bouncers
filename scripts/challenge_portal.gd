extends Node2D

class_name ChallengePortal

@onready var enter_area: Area2D = $EnterArea
@onready var activate_area: Area2D = $ActivateArea
@onready var sprite: AnimatedSprite2D = $PortalInside
@onready var light: Light2D = %Light

@export var enter: bool = true
@export var active: bool = true
@export var portal_color: Color = Color(1, 1, 1, 1)
@onready var master_material: ShaderMaterial = load("res://shaders/materials/MasterMaterial.tres")

var timer: float = 0.0
var light_position: Vector2 = Vector2.ZERO
var light_energy: float = 0.0
var is_open: int = 0 #0 closed, 1 transitioning, 2 open
var tween: Tween

var time_open: float = 0.0
var max_time_open: float = 0.5
var closed_size: Vector2 = Vector2(3, 0.05)

func _ready() -> void:
	tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "scale", closed_size, 0.5)
	sprite.material = master_material.duplicate()
	Events.round_ended.connect(func() -> void:
		if enter:
			active = true
	)

func _process(delta: float) -> void:
	timer += delta
	light.color = portal_color

	if activate_area.get_overlapping_bodies().size() > 0:
		time_open += delta
		sprite.rotation = randf_range(-0.1, 0.1)
		time_open = min(time_open, max_time_open)
	else:
		sprite.rotation = 0.0
		time_open -= delta
		time_open = max(time_open, 0.0)

	if time_open >= max_time_open and is_open == 0:
		is_open = 1
		tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "scale", Vector2(0.5, 1.5), 0.15)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.35)
		tween.finished.connect(func() -> void:
			is_open = 2
		)

	if time_open <= 0 and is_open != 0:
		is_open = 0
		tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(sprite, "scale", closed_size, 0.5)
		sprite.rotation = 0.0

	if enter_area.get_overlapping_bodies().size() > 0:
		transition(enter_area.get_overlapping_bodies()[0])

	if is_open == 2 and active:
		if timer > 0.3:
			timer = 0.0
			light_position = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			light_energy = randf_range(1.2, 3.5)
	elif is_open == 0 and active:
		light_position = Vector2.ZERO
		light_energy = 0.4

	light.position = lerp(light.position, light_position, 0.1 * delta * 60.0)
	light.energy = lerp(light.energy, light_energy, 0.1 * delta * 60.0)
	sprite.material.set_shader_parameter("master_tint", Color(portal_color.r, portal_color.g, portal_color.b, portal_color.a))

	if active:
		sprite.modulate = lerp(sprite.modulate, Color(portal_color.r, portal_color.g, portal_color.b, 1), 0.1 * delta * 60.0)
		light.show()
	else:
		sprite.modulate = lerp(sprite.modulate, Color(portal_color.r, portal_color.g, portal_color.b, 0), 0.1 * delta * 60.0)
		light.hide()

func transition(body: Node) -> void:
	if !active or is_open != 2:
		return

	if body is PlayerCharacter:
		active = false
		Events.custom_inverse_shockwave.emit(-10, 1.3, 0.3, 0.45, Vector2(0, 10))
		body.modulate = Color(0, 0, 0, 0)

		get_tree().create_timer(0.20).timeout.connect(func() -> void:

			get_tree().create_timer(0.25).timeout.connect(func() -> void:
				SoundSystem.play_audio("portal-enter")
				body.modulate = Color(1, 1, 1, 1)
			)

			if enter:
				Events.enter_challenge_mode.emit(body as PlayerCharacter)
			else:
				Events.exit_challenge_mode.emit(body as PlayerCharacter)
		)

	
