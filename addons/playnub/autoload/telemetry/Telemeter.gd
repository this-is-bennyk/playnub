class_name Telemeter
extends UniqueComponent

## Performs custom telemetry with given game data.
##
## ... Note that telemetry is [b]not[/b] the same as save data. Save data records
## progress for players over long durations of time; telemetry records real-time
## data in temporary logs for design analysis.

const _USR_DIR_STR := &"user://"
const _TELEMETRY_HIGH_LVL_DIR_STR := &"Playnub/Telemetry"
const _SLASH_STR := &"/"
const _CSV_EXT_STR := &".csv"
const _SESSION_END := &"END OF SESSION"

## Whether to stop recording telemetry data upon release of the game. Multiplayer
## and/or live-service games may want to continue recording telemetry to evaluate
## and change the game over time.
@export
var disable_on_release := true

var enabled := true

var _telemetry_dir_str := ""

var _tables: Dictionary = {}

func _ready() -> void:
	super()
	
	if disable_on_release:
		enabled = OS.has_feature("editor")
	
	if not enabled:
		return
	
	var time_str := Time.get_datetime_string_from_system()
	
	var user_dir := DirAccess.open(_USR_DIR_STR)
	
	user_dir.make_dir_recursive(str(_TELEMETRY_HIGH_LVL_DIR_STR, _SLASH_STR, time_str))
	
	_telemetry_dir_str += _USR_DIR_STR
	_telemetry_dir_str += _TELEMETRY_HIGH_LVL_DIR_STR
	_telemetry_dir_str += _SLASH_STR
	_telemetry_dir_str += time_str.lstrip(":")
	_telemetry_dir_str += _SLASH_STR

func _exit_tree() -> void:
	if not enabled:
		return
	
	var end_signal := PackedStringArray([_SESSION_END])
	for table: DataTable in _tables.values():
		table.stream.store_csv_line(end_signal)

func record_single_datum(label: StringName, value: Box, table_name: StringName) -> void:
	if not enabled:
		return
	
	record_multiple_data([label], [value], table_name)

func record_multiple_data(labels: Array[StringName], values: Array[Box], table: StringName) -> void:
	if not enabled:
		return
	
	if not _tables.has(table):
		_create_table(table)
	
	(_tables[table] as DataTable).record(labels, values)

func update(table: StringName) -> void:
	if not enabled:
		return
	
	(_tables[table] as DataTable).update()

func create_update_interval(table: StringName, time_sec: float) -> void:
	if not enabled:
		return
	
	assert(time_sec > 0.0, "Cannot update telemetry data infinitely!")
	
	# TODO: Replace w cancelable signal
	get_tree().create_timer(time_sec, true, false, true).timeout.connect(
		func() -> void:
			update(table)
			create_update_interval(table, time_sec)
		
			, CONNECT_ONE_SHOT)

func _create_table(table: StringName) -> void:
	if not enabled:
		return
	
	_tables[table] = DataTable.new(FileAccess.open(_telemetry_dir_str + table + _CSV_EXT_STR, FileAccess.WRITE))

class DataTable:
	var labels: Array[StringName] = []
	var values: Array[Box] = []
	var stream: FileAccess = null
	
	var num_updates := 0
	
	func _init(stream_to_use: FileAccess) -> void:
		stream = stream_to_use
	
	func record(labels: Array[StringName], values: Array[Box]) -> void:
		labels.append_array(labels)
		values.append_array(values)
		
		if num_updates > 0:
			stream.store_csv_line(labels)
	
	func update() -> void:
		if num_updates <= 0:
			stream.store_csv_line(labels)
		
		stream.store_csv_line(values.map(_retrieve))
		
		num_updates += 1
	
	func _retrieve(datum: Box) -> Variant:
		return datum.data
