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

class_name Telemeter
extends UniqueComponent

## Performs custom telemetry with given game data.
##
## ... Note that telemetry is [b]not[/b] the same as save data. Save data is
## player-facing data; it records progress for players over long durations of time.
## Telemetry is developer-facing data; it records real-time data of the state of
## the game in temporary logs for design analysis.

const _USR_DIR_STR := &"user://"
const _TELEMETRY_HIGH_LVL_DIR_STR := &"Playnub/Telemetry"
const _SLASH_STR := &"/"
const _CSV_EXT_STR := &".csv"
const _SESSION_END_STR := &"END OF SESSION"
const _TIME_STR := &"T"
const _COLON_STR := &":"
const _HOUR_STR := &"_H"
const _MIN_STR := &"_M"
const _SEC_STR := &"_S"

## Whether to stop recording telemetry data upon release of the game. Multiplayer
## and/or live-service games may want to continue recording telemetry to evaluate
## and change the game over time.
@export
var disable_on_release := true

## Whether to let the telemetry run or not.
var enabled := true

var _telemetry_dir_str := ""

var _tables: Dictionary = {}

func _ready() -> void:
	super()
	
	if disable_on_release:
		enabled = enabled and OS.has_feature("editor")
	
	if not enabled:
		return
	
	var date_and_time := Time.get_datetime_string_from_system().split(_TIME_STR, false)
	var time_split := date_and_time[1].split(_COLON_STR, false)
	var time_str := date_and_time[0] + _HOUR_STR + time_split[0] + _MIN_STR + time_split[1] + _SEC_STR + time_split[2]
	
	var user_dir := DirAccess.open(_USR_DIR_STR)
	user_dir.make_dir_recursive(str(_TELEMETRY_HIGH_LVL_DIR_STR, _SLASH_STR, time_str))
	
	_telemetry_dir_str += _USR_DIR_STR
	_telemetry_dir_str += _TELEMETRY_HIGH_LVL_DIR_STR
	_telemetry_dir_str += _SLASH_STR
	_telemetry_dir_str += time_str
	_telemetry_dir_str += _SLASH_STR

func _exit_tree() -> void:
	if not enabled:
		return
	
	var end_signal := PackedStringArray([_SESSION_END_STR])
	for table: DataTable in _tables.values():
		table.stream.store_csv_line(end_signal)

## Watches the boxed [param value] labeled as [param label] in the table with the name [param table_name].[br]
## This is used to [b]initialize[/b] a telemetry data table, so it should be called at the start of
## the game or the start of a certain scene, although it can be called at any time (ex. for recording
## PCG data).[br]
func watch_single_datum(label: StringName, value: Box, table_name: StringName) -> void:
	if not enabled:
		return
	
	watch_multiple_data([label], [value], table_name)

## Watches the boxed [param values] with the given [param labels] in the table with the name [param table_name].[br]
## This is used to [b]initialize[/b] a telemetry data table, so it should be called at the start of
## the game or the start of a certain scene, although it can be called at any time (ex. for recording
## PCG data).[br]
func watch_multiple_data(labels: Array[StringName], values: Array[Box], table: StringName) -> void:
	if not enabled:
		return
	
	if not _tables.has(table):
		_create_table(table)
	
	(_tables[table] as DataTable).record(labels, values)

## Captures all the values of the given [param table] with an exact timestamp.
## Connect signals to this function to automatically record certain values when
## certain events happen.
func update(table: StringName) -> void:
	if not enabled:
		return
	
	assert(_tables.has(table), "Table doesn't exist!")
	
	(_tables[table] as DataTable).update()

func _create_table(table: StringName) -> void:
	if not enabled:
		return
	
	_tables[table] = DataTable.new(FileAccess.open(_telemetry_dir_str + table + _CSV_EXT_STR, FileAccess.WRITE))

class DataTable:
	var labels: Array[StringName] = [&"Timestamp"]
	var values: Array[Box] = []
	var stream: FileAccess = null
	
	var num_updates := 0
	
	func _init(stream_to_use: FileAccess) -> void:
		stream = stream_to_use
	
	func record(new_labels: Array[StringName], new_values: Array[Box]) -> void:
		labels.append_array(new_labels)
		values.append_array(new_values)
		
		if num_updates > 0:
			stream.store_csv_line(labels)
	
	func update() -> void:
		if num_updates <= 0:
			stream.store_csv_line(labels)
		
		var values := values.map(_retrieve)
		values.push_front(Time.get_datetime_string_from_system())
		
		stream.store_csv_line(values)
		
		num_updates += 1
	
	func _retrieve(datum: Box) -> Variant:
		return datum.data
