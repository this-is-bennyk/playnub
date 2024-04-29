class_name Component
extends ExtendedNode

var parent: Entity:
	get:
		return get_parent() as Entity

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_register()
		
		NOTIFICATION_UNPARENTED:
			_unregister()

func _register() -> void:
	assert(false, "Virtual function!")

func _unregister() -> void:
	assert(false, "Virtual function!")
