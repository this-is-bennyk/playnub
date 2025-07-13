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

## Records and plays back all inputs captured by the game.
## 
## One task normal to traditional software development, but foreign to game
## development, is the idea of automated testing of game features and content.
## The idea of doing so is especially inaccessible to independent developers.
## The [Automator] provides an interface to recording a player's inputs and
## playing them in order them such that their session is accurately recreated,
## allowing for simpler bug replication, automated playthroughs for verification
## and bug hunting, and even for other features such as in-game match recording.[br][br]
## To record input for a given session, run your game and pass one of the following
## command-line arguments: [code]--record-session[/code] or [code]++record-session[/code].[br][br]
## To play back a session, pass one of the following command-line arguments:
## [code]--playback-session="/your/path/here"[/code] or [code]++playback-session="/your/path/here"[/code].[br][br]
## In editor, either of this commands can be passed in [b]Project Settings > Editor > Run > Main Run Args[/b].

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

## Returns whether the given [param event] should be parsed by game logic.[br]
## For example:
## [codeblock]
## func _input(input: InputEvent) -> void:
##     if PlaynubAutomator.event_ignored(event):
##         return
##     # Resume usual logic here.
## [/codeblock]
func event_ignored(event: InputEvent) -> bool:
	return _mode == Mode.PLAYBACK and _session_record.event_ignored(event)

## Returns an [int] from a variable with the name [param key] of the given [param event].[br]
## Provides a simpler interface when using the automator in input logic. A general example
## is shown below:
## [codeblock]
## # After checking PlaynubAutomator.event_ignored()...
## if event is [intended_type] or event is InputEventFaux:
##     var data := PlaynubAutomator.get_int_from(event, &"property_of_intended_type")
## [/codeblock]
func get_int_from(event: InputEvent, key: StringName) -> int:
	if event is InputEventFaux:
		return (event as InputEventFaux).get_int(key)
	return event.get(key) as int

## Returns a [float] from a variable with the name [param key] of the given [param event].[br]
## Provides a simpler interface when using the automator in input logic. A general example
## is shown below:
## [codeblock]
## # After checking PlaynubAutomator.event_ignored()...
## if event is [intended_type] or event is InputEventFaux:
##     var data := PlaynubAutomator.get_float_from(event, &"property_of_intended_type")
## [/codeblock]
func get_float_from(event: InputEvent, key: StringName) -> float:
	if event is InputEventFaux:
		return (event as InputEventFaux).get_float(key)
	return event.get(key) as float

## Returns a [bool] from a variable with the name [param key] of the given [param event].[br]
## Provides a simpler interface when using the automator in input logic. A general example
## is shown below:
## [codeblock]
## # After checking PlaynubAutomator.event_ignored()...
## if event is [intended_type] or event is InputEventFaux:
##     var data := PlaynubAutomator.get_int_from(event, &"property_of_intended_type")
## [/codeblock]
func get_bool_from(event: InputEvent, key: StringName) -> bool:
	if event is InputEventFaux:
		return (event as InputEventFaux).get_bool(key)
	return event.get(key) as bool

## Returns a [Vector2] from a variable with the name [param key] of the given [param event].[br]
## Provides a simpler interface when using the automator in input logic. A general example
## is shown below:
## [codeblock]
## # After checking PlaynubAutomator.event_ignored()...
## if event is [intended_type] or event is InputEventFaux:
##     var data := PlaynubAutomator.get_vec2_from(event, &"property_of_intended_type")
## [/codeblock]
func get_vec2_from(event: InputEvent, key: StringName) -> Vector2:
	if event is InputEventFaux:
		return (event as InputEventFaux).get_vec2(key)
	return event.get(key) as Vector2

## Returns a [StringName] from a variable with the name [param key] of the given [param event].[br]
## Provides a simpler interface when using the automator in input logic. A general example
## is shown below:
## [codeblock]
## # After checking PlaynubAutomator.event_ignored()...
## if event is [intended_type] or event is InputEventFaux:
##     var data := PlaynubAutomator.get_string_name_from(event, &"property_of_intended_type")
## [/codeblock]
func get_string_name_from(event: InputEvent, key: StringName) -> StringName:
	if event is InputEventFaux:
		return (event as InputEventFaux).get_string_name(key)
	return event.get(key) as StringName

func _ready() -> void:
	var custom_args := PackedStringArray()
	
	if OS.has_feature(&"editor"):
		custom_args = OS.get_cmdline_args()
	else:
		custom_args = OS.get_cmdline_user_args()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	
	for arg: String in custom_args:
		# Only one can be active at a time...
		# ...either recording...
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
		
		# ...or playing back.
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
	
	if _mode == Mode.RECORDING and event is not InputEventFaux:
		_session_record.add(event, tick)

func _process(delta: float) -> void:
	if _mode == Mode.PLAYBACK:
		_session_list.update(delta)
