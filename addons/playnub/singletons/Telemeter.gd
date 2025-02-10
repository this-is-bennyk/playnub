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

class_name Telemeter
extends Node

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
const _SQL_EXT_STR := &".sql"
const _TIME_STR := &"T"
const _COLON_STR := &":"
const _HOUR_STR := &"_H"
const _MIN_STR := &"_M"
const _SEC_STR := &"_S"

const _DB_CREATOR_FILE := &"telemetry_db_creator.sql"
const _DB_DROPPER_FILE := &"telemetry_db_dropper.sql"

const _DB_HEADER_TITLE := &"-- Telemetry DB: "
const _DB_HEADER_COMMENT := &"-- "

const _NEWLINE := &"\n"
const _TAB := &"\t"
const _SQL_TERMINATOR := &";\n"
const _SQL_ID_QUOTE := &"`"

const _SQL_VARCHAR_LIMIT := 65535

enum FileType
{
	  CSV
	, SQL
	, SQLITE
}

var enabled: bool:
	get:
		return PlaynubGlobals.get_proj_setting(&"telemeter/enabled") and (OS.has_feature(&"editor") or OS.has_feature(&"playnub_telemeter"))

var _telemetry_dir_str := ""
var _telemetry_session_str := ""
var _tables: Dictionary = {}
var _file_type := FileType.CSV

var _sqlite_db: SQLite = null

func _ready() -> void:
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
	
	_telemetry_session_str += _USR_DIR_STR
	_telemetry_session_str += _TELEMETRY_HIGH_LVL_DIR_STR
	_telemetry_session_str += _SLASH_STR
	_telemetry_session_str += time_str
	_telemetry_session_str += _SLASH_STR
	
	_file_type = PlaynubGlobals.get_proj_setting(&"telemeter/file_type") as FileType
	
	if _file_type == FileType.SQL or _file_type == FileType.SQLITE:
		_initialize_sql()

## Watches the boxed [param value] labeled as [param label] in the table with the name [param table_name].[br]
## This is used to [b]initialize[/b] a telemetry data table, so it should be called at the start of
## the game or the start of a certain scene, although it can be called at any time (ex. for recording
## PCG data).
func watch(label: StringName, value: Box, table: StringName) -> void:
	if not enabled:
		return
	
	watch_all([label], [value], table)

## Watches the boxed [param values] with the given [param labels] in the table with the name [param table_name].[br]
## This is used to [b]initialize[/b] a telemetry data table, so it should be called at the start of
## the game or the start of a certain scene, although it can be called at any time (ex. for recording
## PCG data).
func watch_all(labels: Array[StringName], values: Array[Box], table: StringName) -> void:
	if not enabled:
		return
	
	if not _tables.has(table):
		_create_table(table)
	
	(_tables[table] as DataTable).record(labels, values)

## Captures all the values of the given [param table] with the tickstamp and timestamp it was called at.
## Connect signals to this function with a binded [StringName] to automatically record values when
## certain events happen.
func update(table: StringName) -> void:
	if not enabled:
		return
	
	assert(_tables.has(table), "Table doesn't exist!")
	
	(_tables[table] as DataTable).update()

func _create_table(table: StringName) -> void:
	if not enabled:
		return
	
	if _file_type == FileType.SQLITE:
		_tables[table] = DataTable.new(null, _file_type, table, self)
		return
	
	var extension := _CSV_EXT_STR
	
	if _file_type == FileType.SQL:
		extension = _SQL_EXT_STR
	
	_tables[table] = DataTable.new(FileAccess.open(_telemetry_session_str + table + extension, FileAccess.WRITE), _file_type, table, self)

func _initialize_sql() -> void:
	if not enabled:
		return
	
	_create_database()

func _create_database() -> void:
	var app_name := (ProjectSettings.get_setting(&"application/config/name") as String).validate_filename().replace(" ", "")
	
	# Write to a SQL database
	# TODO: Make it independent of the SQLite plugin (either integrating directly into the project or trusting duck typing)
	if _file_type == FileType.SQLITE:
		_sqlite_db = SQLite.new()
		
		_sqlite_db.path = _telemetry_session_str + app_name + ".db"
		_sqlite_db.open_db()
	
	# Write to a SQL file
	else:
		var db_creator := FileAccess.open(_telemetry_dir_str + _DB_CREATOR_FILE, FileAccess.WRITE)
		
		_write_sql_header(db_creator, &"Creation Script")
		
		db_creator.store_string(_NEWLINE)
		
		db_creator.store_string(&"CREATE DATABASE IF NOT EXISTS ")
		db_creator.store_string(app_name)
		db_creator.store_string(_SQL_TERMINATOR)
		
		db_creator.store_string(&"USE ")
		db_creator.store_string(app_name)
		db_creator.store_string(_SQL_TERMINATOR)
		
		var db_dropper := FileAccess.open(_telemetry_dir_str + _DB_DROPPER_FILE, FileAccess.WRITE)
		
		_write_sql_header(db_dropper, &"Deletion Script")
		
		db_dropper.store_string(_NEWLINE)
		
		db_dropper.store_string(&"DROP DATABASE IF EXISTS ")
		db_dropper.store_string(app_name)
		db_dropper.store_string(_SQL_TERMINATOR)

func _write_sql_header(file: FileAccess, subtitle: StringName) -> void:
	file.store_string(_DB_HEADER_TITLE)
	file.store_string(ProjectSettings.get_setting(&"application/config/name"))
	file.store_string(_NEWLINE)
	file.store_string(_DB_HEADER_COMMENT)
	file.store_string(subtitle)
	file.store_string(_NEWLINE)
	file.store_string(_DB_HEADER_COMMENT)
	file.store_string(PlaynubGlobals.get_proj_setting(&"general/legal/copyright"))
	file.store_string(_NEWLINE)

class DataTable:
	const _COL_OFFSET := 2
	
	const _X_SUFFIX := &"_x"
	const _Y_SUFFIX := &"_y"
	const _Z_SUFFIX := &"_z"
	const _W_SUFFIX := &"_w"
	
	const _R_SUFFIX := &"_r"
	const _G_SUFFIX := &"_g"
	const _B_SUFFIX := &"_b"
	const _A_SUFFIX := &"_a"
	
	const _POS_SUFFIX := &"_pos"
	const _SIZE_SUFFIX := &"_size"
	const _END_SUFFIX := &"_end"
	
	const _COMMA_DELIMITER := &", "
	const _SQL_COLUMN_DELIMITER := &"`, `"
	const _DBL_QUOTE := &"\""
	const _BACKTICK := &"`"
	
	var labels: Array[StringName] = [&"Tickstamp", &"Timestamp"]
	var values: Array[Box] = []
	var stream: FileAccess = null
	var database: SQLite = null
	
	var label_indices := {}
	
	var file_type := Telemeter.FileType.CSV
	var table_name := &""
	var num_updates := 0
	
	func _init(stream_to_use: FileAccess, file_type_: Telemeter.FileType, table_name_: StringName, telemeter: Telemeter) -> void:
		stream = stream_to_use
		file_type = file_type_
		table_name = table_name_
		
		if file_type == Telemeter.FileType.SQL:
			_initialize_sql(telemeter)
		elif file_type == Telemeter.FileType.SQLITE:
			database = telemeter._sqlite_db
	
	func record(new_labels: Array[StringName], new_values: Array[Box]) -> void:
		_split_values(new_labels, new_values)
		
		var appended_start := labels.size()
		
		for label_idx in new_labels.size():
			var label := new_labels[label_idx]
			var value := new_values[label_idx]
			
			if label in label_indices:
				values[label_indices[label]] = value
			else:
				label_indices[label] = labels.size()
				labels.append(label)
				values.append(value)
		
		if num_updates > 0:
			_write_column_headers(appended_start)
	
	func update() -> void:
		if num_updates <= 0:
			_write_column_headers()
		
		var current_values := values.map(_retrieve)
		var datetime_string := Time.get_datetime_string_from_system(false, true)
		
		if file_type == Telemeter.FileType.SQL or file_type == Telemeter.FileType.SQLITE:
			datetime_string = _DBL_QUOTE + datetime_string + _DBL_QUOTE
		
		current_values.push_front(datetime_string)
		current_values.push_front(Time.get_ticks_usec())
		
		_write_row(current_values)
		
		num_updates += 1
	
	func _retrieve(datum: Box) -> Variant:
		if file_type == Telemeter.FileType.SQL or file_type == Telemeter.FileType.SQLITE:
			var content: Variant = datum.data
			
			match typeof(content):
				TYPE_BOOL:
					pass
				TYPE_INT:
					pass
				TYPE_FLOAT:
					pass
				TYPE_STRING, TYPE_STRING_NAME:
					return _DBL_QUOTE + content.c_escape() + _DBL_QUOTE
				_:
					return _DBL_QUOTE + var_to_str(content).c_escape() + _DBL_QUOTE
				
		return datum.data
	
	func _split_values(new_labels: Array[StringName], new_values: Array[Box]) -> void:
		var modded_labels: Array[StringName] = []
		var modded_values: Array[Box] = []
		
		for idx: int in new_labels.size():
			var label := new_labels[idx]
			var value := new_values[idx]
			
			var data: Variant = value.data
			var data_type := typeof(data)
			
			var matched := false
			
			match data_type:
				TYPE_VECTOR2, TYPE_VECTOR2I:
					if ((data_type == TYPE_VECTOR2 and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector2"))
					or  (data_type == TYPE_VECTOR2I and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector2i"))):
						modded_labels.append(label + _X_SUFFIX)
						modded_labels.append(label + _Y_SUFFIX)
						
						modded_values.append(Box.new(value, "data:x"))
						modded_values.append(Box.new(value, "data:y"))
						
						matched = true
				
				TYPE_RECT2, TYPE_RECT2I:
					if ((data_type == TYPE_RECT2 and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/rect2"))
					or  (data_type == TYPE_RECT2I and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/rect2i"))):
						
						if ((data_type == TYPE_RECT2 and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector2"))
						or  (data_type == TYPE_RECT2I and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector2i"))):
							modded_labels.append(label + _POS_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _POS_SUFFIX + _Y_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX + _Y_SUFFIX)
							modded_labels.append(label + _END_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _END_SUFFIX + _Y_SUFFIX)
							
							modded_values.append(Box.new(value, "data:position:x"))
							modded_values.append(Box.new(value, "data:position:y"))
							modded_values.append(Box.new(value, "data:size:x"))
							modded_values.append(Box.new(value, "data:size:y"))
							modded_values.append(Box.new(value, "data:end:x"))
							modded_values.append(Box.new(value, "data:end:y"))
						
						else:
							modded_labels.append(label + _POS_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX)
							modded_labels.append(label + _END_SUFFIX)
							
							modded_values.append(Box.new(value, "data:position"))
							modded_values.append(Box.new(value, "data:size"))
							modded_values.append(Box.new(value, "data:end"))
						
						matched = true
				
				TYPE_VECTOR3, TYPE_VECTOR3I:
					if ((data_type == TYPE_VECTOR3 and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector3"))
					or  (data_type == TYPE_VECTOR3I and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector3i"))):
						modded_labels.append(label + _X_SUFFIX)
						modded_labels.append(label + _Y_SUFFIX)
						modded_labels.append(label + _Z_SUFFIX)
						
						modded_values.append(Box.new(value, "data:x"))
						modded_values.append(Box.new(value, "data:y"))
						modded_values.append(Box.new(value, "data:z"))
						
						matched = true
				
				TYPE_VECTOR4, TYPE_VECTOR4I:
					if ((data_type == TYPE_VECTOR4 and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector4"))
					or  (data_type == TYPE_VECTOR4I and PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector4i"))):
						modded_labels.append(label + _X_SUFFIX)
						modded_labels.append(label + _Y_SUFFIX)
						modded_labels.append(label + _Z_SUFFIX)
						modded_labels.append(label + _W_SUFFIX)
						
						modded_values.append(Box.new(value, "data:x"))
						modded_values.append(Box.new(value, "data:y"))
						modded_values.append(Box.new(value, "data:z"))
						modded_values.append(Box.new(value, "data:w"))
						
						matched = true
				
				TYPE_AABB:
					if PlaynubGlobals.get_proj_setting(&"telemeter/splitting/aabb"):
						if PlaynubGlobals.get_proj_setting(&"telemeter/splitting/vector3"):
							modded_labels.append(label + _POS_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _POS_SUFFIX + _Y_SUFFIX)
							modded_labels.append(label + _POS_SUFFIX + _Z_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX + _Y_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX + _Z_SUFFIX)
							modded_labels.append(label + _END_SUFFIX + _X_SUFFIX)
							modded_labels.append(label + _END_SUFFIX + _Y_SUFFIX)
							modded_labels.append(label + _END_SUFFIX + _Z_SUFFIX)
							
							modded_values.append(Box.new(value, "data:position:x"))
							modded_values.append(Box.new(value, "data:position:y"))
							modded_values.append(Box.new(value, "data:position:z"))
							modded_values.append(Box.new(value, "data:size:x"))
							modded_values.append(Box.new(value, "data:size:y"))
							modded_values.append(Box.new(value, "data:size:z"))
							modded_values.append(Box.new(value, "data:end:x"))
							modded_values.append(Box.new(value, "data:end:y"))
							modded_values.append(Box.new(value, "data:end:z"))
						
						else:
							modded_labels.append(label + _POS_SUFFIX)
							modded_labels.append(label + _SIZE_SUFFIX)
							modded_labels.append(label + _END_SUFFIX)
							
							modded_values.append(Box.new(value, "data:position"))
							modded_values.append(Box.new(value, "data:size"))
							modded_values.append(Box.new(value, "data:end"))
						
						matched = true
				
				TYPE_COLOR:
					if PlaynubGlobals.get_proj_setting(&"telemeter/splitting/color"):
						modded_labels.append(label + _R_SUFFIX)
						modded_labels.append(label + _G_SUFFIX)
						modded_labels.append(label + _B_SUFFIX)
						modded_labels.append(label + _A_SUFFIX)
						
						modded_values.append(Box.new(value, "data:r8"))
						modded_values.append(Box.new(value, "data:g8"))
						modded_values.append(Box.new(value, "data:b8"))
						modded_values.append(Box.new(value, "data:a8"))
						
						matched = true
			
			if not matched:
				modded_labels.append(label)
				modded_values.append(value)
		
		new_labels.clear()
		new_values.clear()
		
		new_labels.assign(modded_labels)
		new_values.assign(modded_values)
	
	func _write_column_headers(appended_start := 0) -> void:
		if file_type == Telemeter.FileType.SQL or file_type == Telemeter.FileType.SQLITE:
			if num_updates <= 0:
				_create_sql_table()
			else:
				_alter_sql_table(appended_start)
		else:
			stream.store_csv_line(labels)
	
	func _write_row(current_values: Array) -> void:
		if file_type == Telemeter.FileType.SQL or file_type == Telemeter.FileType.SQLITE:
			_write_sql_tuple(current_values)
		else:
			stream.store_csv_line(current_values)
	
	func _initialize_sql(telemeter: Telemeter) -> void:
		table_name = Telemeter._SQL_ID_QUOTE + table_name + Telemeter._SQL_ID_QUOTE
		
		telemeter._write_sql_header(stream, table_name)
		stream.store_string(Telemeter._NEWLINE)
	
	func _create_sql_table() -> void:
		var query := ""
		
		query += &"CREATE TABLE IF NOT EXISTS "
		query += _SQL_ID_QUOTE
		query += table_name
		query += _SQL_ID_QUOTE
		query += _NEWLINE
		query += &"(\n"
		
		for idx: int in labels.size():
			query += _TAB
			query += _create_sql_column(idx)
			
			if idx < labels.size() - 1:
				query += &",\n"
			else:
				query += _NEWLINE
		
		query += &");\n"
		query += _NEWLINE
		
		if file_type == Telemeter.FileType.SQLITE:
			var success := database.query(query)
			assert(success, database.error_message)
			
		else:
			stream.store_string(query)
	
	func _alter_sql_table(appended_start: int) -> void:
		var query := ""
		
		query += _NEWLINE
		
		for idx: int in range(appended_start, labels.size()):
			query += &"ALTER TABLE "
			query += _SQL_ID_QUOTE
			query += table_name
			query += _SQL_ID_QUOTE
			query += _NEWLINE
			query += &"ADD COLUMN "
			query += _create_sql_column(idx)
			query += _SQL_TERMINATOR
		
		query += _NEWLINE
		
		if file_type == Telemeter.FileType.SQLITE:
			var success := database.query(query)
			assert(success, database.error_message)
			
		else:
			stream.store_string(query)
	
	func _create_sql_column(col_idx: int) -> String:
		var column := ""
		
		column += _SQL_ID_QUOTE + labels[col_idx] + _SQL_ID_QUOTE
		
		if col_idx < _COL_OFFSET:
			column += &" BIGINT" if col_idx == 0 else &" DATETIME"
			
			if col_idx == 0:
				column += &" PRIMARY KEY NOT NULL"
			
			return column
		
		col_idx -= _COL_OFFSET
		
		var data: Variant = values[col_idx].data
		var data_type := typeof(values[col_idx].data)
		
		match data_type:
			TYPE_BOOL:
				column += &" BOOL"
			TYPE_INT:
				column += &" BIGINT"
			TYPE_FLOAT:
				column += &" DOUBLE"
			TYPE_STRING, TYPE_STRING_NAME:
				column += &" VARCHAR("
				column += str(PlaynubGlobals.get_proj_setting(&"telemeter/SQL/string_varchar_initial_size"))
				column += &")"
			_:
				var string := var_to_str(data)
				column += &" VARCHAR("
				column += str(clampi(string.length() + PlaynubGlobals.get_proj_setting(&"telemeter/SQL/variant_varchar_padding_size"), 0, _SQL_VARCHAR_LIMIT))
				column += &")"
		
		return column
	
	func _write_sql_tuple(current_values: Array) -> void:
		var query := ""
		
		query += &"INSERT INTO "
		query += _SQL_ID_QUOTE
		query += table_name
		query += _SQL_ID_QUOTE
		query += _NEWLINE
		query += &"VALUES ("
		query += _COMMA_DELIMITER.join(current_values)
		query += &");\n"
		
		if file_type == Telemeter.FileType.SQLITE:
			database.query(query)
		else:
			stream.store_string(query)
