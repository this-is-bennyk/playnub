# MIT License
# 
# Copyright (c) 2024 Ben Kurtin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends UniqueComponent

## Performs custom automation with given game inputs.
## 
## TODO

class_name Automator

@export
var automation_list: ActionList = null

## Whether to let the automation run or not.
@export
var enabled := true

## Whether to allow automation upon release of the game. Games where inputs can
## be recorded and played back by users may benefit from leaving this on.
@export
var disable_on_release := true

@export_group("Input Recording")

@export
var record_inputs := false

@export
var actions_to_record: Array[StringName] = []

const _INPUT_TABLE := &"InputRecording"
const _ACTION_TYPE := &"action"
const _ACTION_SEND := &"send_action"

var _input_strings := {}
var _input_objs := {}

var _no_inputs_done := true

func _ready() -> void:
	super()
	
	if record_inputs:
		var telemeter := Playnub.get_component(Telemeter) as Telemeter
		
		for action_name: StringName in actions_to_record:
			_input_strings[action_name] = ""
			_input_objs[action_name] = null
			
			telemeter.watch_multiple_data(
				  [StringName(action_name + " (Human-Readable)"), StringName(action_name + " (Serialized)")]
				, [Box.new(_input_strings, action_name), Box.new(_input_objs, action_name)]
				, _INPUT_TABLE)
		
		telemeter.update(_INPUT_TABLE)
	
	else:
		set_process(false)

func _process(_delta: float) -> void:
	if _no_inputs_done:
		return
	
	for action_name: StringName in actions_to_record:
		_input_strings[action_name] = ""
		_input_objs[action_name] = null
	
	_no_inputs_done = true

func send_action(action_name: StringName, duration: float, delay := 0.0, blocking := false) -> void:
	var action := InputActionSender.new() \
		.sends(action_name) \
		.targets(self) \
		.lasts(duration) \
		.after(delay) \
		.in_groups([0])
	
	if blocking:
		action.blocks_own_groups()
	
	automation_list.push(action)

#func send_mouse_move(from: Vector2, to: Vector2, duration: float, delay := 0.0, blocking := false) -> void:
	#pass
#
#func send_mouse_click(button: MouseButton, delay := 0.0, blocking := false) -> void:
	#pass

func parse_input(type: StringName, arguments: Array) -> void:
	match type:
		_ACTION_TYPE:
			callv(_ACTION_SEND, arguments)

func _input(event: InputEvent) -> void:
	if not record_inputs:
		return
	
	if event.is_action_type():
		for action_name: StringName in actions_to_record:
			if event.is_action(action_name):
				_input_strings[action_name] = event.to_string()
				_input_objs[action_name] = var_to_bytes(event)
				
				Playnub.telemeter.update(_INPUT_TABLE)
				_no_inputs_done = false
				break
