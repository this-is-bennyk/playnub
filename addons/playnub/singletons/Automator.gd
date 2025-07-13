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

class_name Automator
extends Node

const _PROP_BLACKLIST: Array[StringName] = [
	&"resource_local_to_scene",
	&"resource_name",
	&"script",
]

const _ARTIFICIAL_INPUT := &"artificial"

const _RECORD_SESSION_A := &"--record-session"
const _RECORD_SESSION_B := &"++record-session"

const _PLAYBACK_SESSION_A := &"--playback-session="
const _PLAYBACK_SESSION_B := &"++playback-session="

const _USR_DIR_STR := &"user://"
const _AUTOMATOR_HIGH_LVL_DIR_STR := &"Playnub/Automation"
const _SLASH_STR := &"/"
const _FILE_STR := &"Inputs.bin"

const _TIME_STR := &"T"
const _COLON_STR := &":"
const _HOUR_STR := &"_H"
const _MIN_STR := &"_M"
const _SEC_STR := &"_S"

enum Mode
{
	  DISABLED
	, RECORDING
	, PLAYBACK
}

var _mode: Mode = Mode.DISABLED
var _session_record := InputRecord.new()
var _session_list := ActionList.new()

var _automation_session_str := ""

func _ready() -> void:
	var custom_args := PackedStringArray()
	
	if OS.has_feature(&"editor"):
		custom_args = OS.get_cmdline_args()
	else:
		custom_args = OS.get_cmdline_user_args()
	
	set_process(false)
	
	for arg: String in custom_args:
		# Only one can be active at a time
		
		var x := arg.begins_with(_PLAYBACK_SESSION_A)
		
		if arg == _RECORD_SESSION_A or arg == _RECORD_SESSION_B:
			_mode = Mode.RECORDING
			
			var date_and_time := Time.get_datetime_string_from_system().split(_TIME_STR, false)
			var time_split := date_and_time[1].split(_COLON_STR, false)
			var time_str := date_and_time[0] + _HOUR_STR + time_split[0] + _MIN_STR + time_split[1] + _SEC_STR + time_split[2]
			
			var user_dir := DirAccess.open(_USR_DIR_STR)
			user_dir.make_dir_recursive(str(_AUTOMATOR_HIGH_LVL_DIR_STR, _SLASH_STR, time_str))
			
			_automation_session_str += _USR_DIR_STR
			_automation_session_str += _AUTOMATOR_HIGH_LVL_DIR_STR
			_automation_session_str += _SLASH_STR
			_automation_session_str += time_str
			_automation_session_str += _SLASH_STR
			_automation_session_str += _FILE_STR
			break
		
		elif arg.begins_with(_PLAYBACK_SESSION_A) or arg.begins_with(_PLAYBACK_SESSION_B):
			var path := ""
			
			if arg.begins_with(_PLAYBACK_SESSION_A):
				path = arg.trim_prefix(_PLAYBACK_SESSION_A)
			else:
				path = arg.trim_suffix(_PLAYBACK_SESSION_B)
			
			_session_record.from_file(path)
			
			_mode = Mode.PLAYBACK
			_session_list.push_back_list(_session_record.to_actions())
			set_process(true)
			break

func _notification(what: int) -> void:
	if _mode != Mode.RECORDING:
		return
	
	match what:
		NOTIFICATION_CRASH, NOTIFICATION_PREDELETE:
			_session_record.to_file(_automation_session_str)

func _input(event: InputEvent) -> void:
	var tick := Time.get_ticks_usec()
	
	match _mode:
		Mode.RECORDING:
			if _session_record.can_record():
				_session_record.add(event, tick)
			
		Mode.PLAYBACK:
			if event.get_meta(_ARTIFICIAL_INPUT, false):
				get_tree().root.set_input_as_handled()

func _process(delta: float) -> void:
	if _mode == Mode.PLAYBACK:
		_session_list.update(delta)

class InputRecord:
	var _inputs: Array[InputEvent] = []
	var _input_times := PackedInt64Array()
	var _action_whitelist: Dictionary[StringName, bool] = {}
	var _read_only := false
	var _start_time := Time.get_ticks_usec()
	
	func can_record() -> bool:
		return not _read_only
	
	func whitelist(action: StringName) -> void:
		_action_whitelist[action] = true
	
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
	
	func to_file(path: String) -> void:
		var file := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		
		if FileAccess.get_open_error() != OK:
			push_error("Automator.InputRecord.to_file: Could not open ", path)
			return
		
		var data: Array[Dictionary] = []
		
		for event: InputEvent in _inputs:
			data.push_back(_to_safe_dict(event))
		
		file.store_64(_start_time)
		file.store_var(_input_times, true)
		file.store_var(data, true)
	
	func from_file(path: String) -> void:
		var file := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
		
		if FileAccess.get_open_error() != OK:
			push_error("Automator.InputRecord.to_file: Could not open ", path)
			return
		
		var data: Array[Dictionary] = []
		
		_start_time = file.get_64()
		_input_times = file.get_var(true)
		data.assign(file.get_var(true))
		
		for dict: Dictionary in data:
			_inputs.push_back(_from_user_dict(dict))
			_inputs[_inputs.size() - 1].set_meta(_ARTIFICIAL_INPUT, true)
	
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
	
	func _from_user_dict(dict: Dictionary[StringName, Variant]) -> InputEvent:
		for property: StringName in _PROP_BLACKLIST:
			var index = (dict[&"props"] as Array).find(String(property))
			
			if index > -1:
				(dict[&"props"] as Array).remove_at(index)
				(dict[&"props"] as Array).remove_at(index)
		
		return JSON.to_native(dict, true) as InputEvent
