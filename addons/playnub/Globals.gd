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

class_name PlaynubGlobals

const _BASIC_SETTING := true
const _ADVANCED_SETTING := false

const _SETTING_INFO_SIZE := 3
const _SETTING_W_HINT_INFO_SIZE := 4
const _SETTING_W_HINT_STRING_INFO_SIZE := 5

const _SETTINGS_DEFAULT_VALUES := {
	  &"playnub/general/versioning/major_number": 0
	, &"playnub/general/versioning/minor_number": 0
	, &"playnub/general/versioning/patch_number": 0
	, &"playnub/general/versioning/build_label":  0
	
	, &"playnub/general/legal/copyright": ""
	
	, &"playnub/telemeter/enabled": true
	, &"playnub/telemeter/file_type": Telemeter.FileType.CSV
	
	, &"playnub/telemeter/splitting/vector2": true
	, &"playnub/telemeter/splitting/vector2i": true
	, &"playnub/telemeter/splitting/rect2": true
	, &"playnub/telemeter/splitting/rect2i": true
	, &"playnub/telemeter/splitting/vector3": true
	, &"playnub/telemeter/splitting/vector3i": true
	, &"playnub/telemeter/splitting/transform2D": false
	, &"playnub/telemeter/splitting/vector4": true
	, &"playnub/telemeter/splitting/vector4i": true
	, &"playnub/telemeter/splitting/plane": false
	, &"playnub/telemeter/splitting/quaternion": false
	, &"playnub/telemeter/splitting/aabb": true
	, &"playnub/telemeter/splitting/basis": false
	, &"playnub/telemeter/splitting/transform3D": false
	, &"playnub/telemeter/splitting/projection": false
	, &"playnub/telemeter/splitting/color": true
	
	, &"playnub/telemeter/SQL/create_database": true
	, &"playnub/telemeter/SQL/string_varchar_initial_size": 256
	, &"playnub/telemeter/SQL/variant_varchar_padding_size": 64
	
	, &"playnub/automator/enabled": true
	, &"playnub/randomizer/enabled": true
}

const _SETTINGS_PROPERTY_DEFS := [
	  [&"playnub/general/versioning/major_number", _SETTINGS_DEFAULT_VALUES[&"playnub/general/versioning/major_number"], _BASIC_SETTING, PROPERTY_HINT_RANGE, "0,1,1,or_greater"]
	, [&"playnub/general/versioning/minor_number", _SETTINGS_DEFAULT_VALUES[&"playnub/general/versioning/minor_number"], _BASIC_SETTING, PROPERTY_HINT_RANGE, "0,1,1,or_greater"]
	, [&"playnub/general/versioning/patch_number", _SETTINGS_DEFAULT_VALUES[&"playnub/general/versioning/patch_number"], _BASIC_SETTING, PROPERTY_HINT_RANGE, "0,1,1,or_greater"]
	, [&"playnub/general/versioning/build_label",  _SETTINGS_DEFAULT_VALUES[&"playnub/general/versioning/build_label"], _BASIC_SETTING, PROPERTY_HINT_ENUM, "Dev,Alpha,Beta,Release Candidate,Stable"]
	
	, [&"playnub/general/legal/copyright", _SETTINGS_DEFAULT_VALUES[&"playnub/general/legal/copyright"], _BASIC_SETTING]
	
	, [&"playnub/telemeter/enabled", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/enabled"], _BASIC_SETTING]
	, [&"playnub/telemeter/file_type", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/file_type"], _BASIC_SETTING, PROPERTY_HINT_ENUM, "CSV,SQL,SQLite"]
	# TODO: Commented out splitting properties, if there's a valid use case for them
	, [&"playnub/telemeter/splitting/vector2", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector2"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/vector2i", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector2i"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/rect2", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/rect2"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/rect2i", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/rect2i"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/vector3", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector3"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/vector3i", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector3i"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/transform2D", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/transform2D"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/vector4", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector4"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/vector4i", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/vector4i"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/plane", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/plane"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/quaternion", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/quaternion"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/aabb", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/aabb"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/basis", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/basis"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/transform3D", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/transform3D"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/splitting/projection", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/projection"], _ADVANCED_SETTING]
	, [&"playnub/telemeter/splitting/color", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/splitting/color"], _ADVANCED_SETTING]
	#, [&"playnub/telemeter/SQL/create_database", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/SQL/create_database"], _BASIC_SETTING]
	, [&"playnub/telemeter/SQL/string_varchar_initial_size", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/SQL/string_varchar_initial_size"], _BASIC_SETTING, PROPERTY_HINT_RANGE, "0,65535,1,or_greater"]
	, [&"playnub/telemeter/SQL/variant_varchar_padding_size", _SETTINGS_DEFAULT_VALUES[&"playnub/telemeter/SQL/variant_varchar_padding_size"], _BASIC_SETTING, PROPERTY_HINT_RANGE, "0,65535,1,or_greater"]
	
	, [&"playnub/automator/enabled", _SETTINGS_DEFAULT_VALUES[&"playnub/automator/enabled"], _BASIC_SETTING]
	, [&"playnub/randomizer/enabled", _SETTINGS_DEFAULT_VALUES[&"playnub/randomizer/enabled"], _BASIC_SETTING]
]

## Returns the project setting at [param relative_path]. Don't include the [code]playnub/[/code] that's in front of the project setting path.
static func get_proj_setting(relative_path: StringName) -> Variant:
	return ProjectSettings.get_setting(&"playnub/" + relative_path, _SETTINGS_DEFAULT_VALUES[&"playnub/" + relative_path])
