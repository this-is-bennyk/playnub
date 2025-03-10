extends Node2D

@export
var oscillator: PIDController = null

@onready
var icon := $Icon

func _ready() -> void:
	oscillator.start(icon.global_position)

func _process(delta: float) -> void:
	icon.global_position = oscillator.update(delta, get_global_mouse_position())
