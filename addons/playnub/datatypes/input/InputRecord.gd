# MIT License
# 
# Copyright (c) 2025 Ben Kurtin
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

class_name InputRecord
extends RefCounted

## A list of inputs being recorded or being processed.

const _PROP_BLACKLIST: Array[StringName] = [
	&"resource_local_to_scene",
	&"resource_name",
	&"script",
]

var _inputs: Array[InputEvent] = []
var _input_set: Dictionary[InputEvent, bool] = {}
var _input_times := PackedInt64Array()
var _action_whitelist: Dictionary[StringName, bool] = {}
var _read_only := false
var _start_time := Time.get_ticks_usec()

## Whether this input record should record new input events.
func can_record() -> bool:
	return not _read_only

## Authorizes only input events that relate to a given [param action]
## to be recorded. No calls to this means all input events are recorded.
func whitelist(action: StringName) -> void:
	_action_whitelist[action] = true

## Adds the given [param event] to the record, if it is allowed to,
## and at what tick it was processed at via [param tick_usec].
func add(event: InputEvent, tick_usec: int) -> void:
	if _read_only:
		return
	
	if not _action_whitelist.is_empty():
		var recording := false
		
		for action: StringName in _action_whitelist.keys():
			if event.is_action(action):
				recording = true
				break
		
		if not recording:
			return
	
	_inputs.push_back(event)
	_input_times.push_back(tick_usec)

## Records all the processed actions to a binary file at the given [param path].
func to_file(path: String) -> void:
	var file := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	
	if FileAccess.get_open_error() != OK:
		push_error("Automator.InputRecord.to_file: Could not open ", path, "!")
		assert(false)
		return
	
	var data: Array[Dictionary] = []
	
	for event: InputEvent in _inputs:
		data.push_back(_to_safe_dict(event))
	
	file.store_64(_start_time)
	file.store_var(_input_times, true)
	file.store_var(data, true)

## Retrieves all the recorded actions from a binary file at the given [param path].
func from_file(path: String) -> void:
	var file := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	
	if FileAccess.get_open_error() != OK:
		push_error("Automator.InputRecord.from_file: Could not open ", path, "!")
		assert(false)
		return
	
	var data: Array[Dictionary] = []
	
	_start_time = file.get_64()
	_input_times = file.get_var(true)
	data.assign(file.get_var(true))
	
	for dict: Dictionary in data:
		_inputs.push_back(_from_user_dict(dict))

## Returns an array of [Action]s for an [ActionList] to process that simulates
## all the recorded input events.
func to_actions() -> Array[Action]:
	var result: Array[Action] = []
	
	for index: int in _inputs.size():
		var delay := Playhead.new()
		var ticks_usec := _input_times[index] - _start_time
		var seconds_whole := ticks_usec / 1_000_000
		var seconds_fraction := float(ticks_usec % 1_000_000) / 1_000_000.0
		
		delay.set_precise(seconds_whole, seconds_fraction)
		
		result.push_back(
			FunctionCaller.new()
			.targets(Input.parse_input_event.bind(_inputs[index]))
			.after(delay)
		)
	
	return result

## Returns whether the given [param event] should be parsed by game logic.
## For example:
## [codeblock]
## var record := InputRecord.new()
## 
## # ...
## 
## func _input(input: InputEvent) -> void:
##     if record.event_ignored(event):
##         return
##     # Resume usual logic here.
## [/codeblock]
func event_ignored(event: InputEvent) -> bool:
	return event is not InputEventFaux

func _to_safe_dict(event: InputEvent) -> Dictionary[StringName, Variant]:
	var json_native := JSON.from_native(event, true) as Dictionary
	var result: Dictionary[StringName, Variant] = {}
	
	result.assign(json_native)
	
	for property: StringName in _PROP_BLACKLIST:
		var index = (result[&"props"] as Array).find(String(property))
		
		if index > -1:
			(result[&"props"] as Array).remove_at(index)
			(result[&"props"] as Array).remove_at(index)
	
	return result

func _from_user_dict(dict: Dictionary[StringName, Variant]) -> InputEventFaux:
	for property: StringName in _PROP_BLACKLIST:
		var index = (dict[&"props"] as Array).find(String(property))
		
		if index > -1:
			(dict[&"props"] as Array).remove_at(index)
			(dict[&"props"] as Array).remove_at(index)
	
	return InputEventFaux.new(dict)
