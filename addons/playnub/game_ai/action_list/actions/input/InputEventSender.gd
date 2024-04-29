class_name InputEventSender
extends Action

var _begin_event: InputEvent = null
var _end_event: InputEvent = null

func begins_with(event: InputEvent) -> InputEventSender:
	_begin_event = event
	return self

func ends_with(event: InputEvent) -> InputEventSender:
	_end_event = event
	return self

func enter() -> void:
	Input.parse_input_event(_begin_event)

func exit() -> void:
	Input.parse_input_event(_end_event)
