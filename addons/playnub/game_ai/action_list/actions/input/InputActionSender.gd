class_name InputActionSender
extends InputEventSender

func sends(action_name: StringName) -> InputActionSender:
	var begin := InputEventAction.new()
	var end := InputEventAction.new()
	
	begin.action = action_name
	end.action = action_name
	
	begin.pressed = true
	end.pressed = false
	
	begins_with(begin).ends_with(end)
	
	return self

func enter() -> void:
	Input.action_press((_begin_event as InputEventAction).action)
	super()

func exit() -> void:
	Input.action_release((_end_event as InputEventAction).action)
	super()
