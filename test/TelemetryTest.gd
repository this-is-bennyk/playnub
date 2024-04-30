class_name TelemetryTest
extends UniqueComponent

@export
var to_track: Node2D = null

@export
var timer: Timer = null

func _ready():
	Playnub.telemeter.watch_single_datum(&"Position", Box.new(to_track, "position"), &"MovementData")
	
	timer.timeout.connect(
		func() -> void:
			Playnub.telemeter.update(&"MovementData")
			timer.start()
			)
