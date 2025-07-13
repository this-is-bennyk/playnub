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

@tool
class_name PlaynubPlugin
extends EditorPlugin

## Initializes the Playnub plugin.
## 
## Initializes the stuff Godot needs for Playnub to be functional in the editor.

func _enable_plugin() -> void:
	_add_singletons()
	print("Playnub has been enabled!")

func _disable_plugin() -> void:
	_remove_singletons()
	_remove_project_settings()
	print("Playnub has been disabled!")

func _enter_tree() -> void:
	_create_project_settings()

func _exit_tree() -> void:
	pass

func _create_project_settings() -> void:
	for prop_def: Array in PlaynubGlobals._SETTINGS_PROPERTY_DEFS:
		if prop_def.size() <= PlaynubGlobals._SETTING_INFO_SIZE:
			_create_setting(prop_def[0], prop_def[1], prop_def[2])
		elif prop_def.size() <= PlaynubGlobals._SETTING_W_HINT_INFO_SIZE:
			_create_setting(prop_def[0], prop_def[1], prop_def[2], prop_def[3])
		else:
			_create_setting(prop_def[0], prop_def[1], prop_def[2], prop_def[3], prop_def[4])
	
	ProjectSettings.save()

func _remove_project_settings() -> void:
	for prop_def: Array in PlaynubGlobals._SETTINGS_PROPERTY_DEFS:
		_remove_setting(prop_def[0])
	
	ProjectSettings.save()

func _create_setting(
	  property_path: StringName
	, property_initial_value: Variant
	, basic: bool
	, property_hint := PROPERTY_HINT_NONE
	, property_hint_string := ""
) -> void:
	var property_info := {
		name = property_path,
		type = typeof(property_initial_value),
		hint = property_hint,
		hint_string = property_hint_string
	}
	
	var initial_setup := not ProjectSettings.has_setting(property_path)
	
	if initial_setup:
		ProjectSettings.set_setting(property_path, property_initial_value)
	else:
		ProjectSettings.set_setting(property_path, ProjectSettings.get_setting(property_path))
	
	ProjectSettings.set_initial_value(property_path, property_initial_value)
	ProjectSettings.set_as_basic(property_path, basic)
	ProjectSettings.add_property_info(property_info)

func _remove_setting(property_path: StringName) -> void:
	ProjectSettings.set_setting(property_path, null)

func _add_singletons() -> void:
	add_autoload_singleton(&"PlaynubTelemeter", &"res://addons/playnub/singletons/Telemeter.gd")
	add_autoload_singleton(&"PlaynubRandomizer", &"res://addons/playnub/singletons/Randomizer.gd")
	add_autoload_singleton(&"PlaynubAutomator", &"res://addons/playnub/singletons/Automator.gd")

func _remove_singletons() -> void:
	remove_autoload_singleton(&"PlaynubTelemeter")
	remove_autoload_singleton(&"PlaynubRandomizer")
	remove_autoload_singleton(&"PlaynubAutomator")
