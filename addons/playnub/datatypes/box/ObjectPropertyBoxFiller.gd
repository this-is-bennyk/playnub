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
class_name ObjectPropertyBoxFiller
extends BoxFiller

## Fills the associated [Box] with an object and a property path.
## 
## [b]NOTE[/b]: This [BoxFiller] is most useful for capturing objects and/or properties that are in
## [b]global scope[/b] and are designed to be [b]set with minimal interface changes[/b], i.e. [b]hardcoded[/b].
## This [BoxFiller] is [b]not[/b] useful for capturing objects and/or properties local to a scene.
## That should be done in code with a dynamically created [Box]; for example:
## [codeblock]
## var box_for_dynamic_obj := Box.new(my_object, "property:subproperty")
## [/codeblock]

## The ways in which an object can be identified.
enum IdentificationType
{
	## Selects a node from a group.[br]
	## [b]NOTE[/b]: Remember that nodes in groups are organized in scene hierarcy order,
	## according to [method SceneTree.get_nodes_in_group], so use this approach with caution
	## and test that nodes in the group will spawn in the correct order.
	GROUP,
	## Selects an autoloaded (custom singleton) node.
	AUTOLOAD,
	## Selects a singleton from the [Engine]'s list.
	GLOBAL_SINGLETON,
}

@export_group("Data")

## The name of the object or group to look for.
@export
var global_identifier := &"":
	set(value):
		global_identifier = value
		emit_changed()

## The index of the specific object in the [member global_identifier],
## if searching for a group.
@export_range(0, 1, 1, "or_greater")
var identifier_index := 0:
	set(value):
		identifier_index = value
		emit_changed()

## How to identify the object using the [member global_identifier] and, optionally,
## the [member identifier_index].
@export
var identification_type := IdentificationType.GROUP

## Optional path to a specific property on the selected object.
@export
var property_path := &"":
	set(value):
		property_path = value
		emit_changed()

## Editor-only pseudo-console to let the designer know if there's any issues with retrieving
## the object and its specific value.[br]
## [b]NOTE[/b]: This does not verify that the object and/or property will be found or not found
## as expected at runtime, so take this output with a grain of salt and test thoroughly.
@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var verification := "":
	get:
		if (not Engine.is_editor_hint()) or global_identifier.is_empty():
			return "ERROR: No identifier specified."
		
		var obj := _get_object()
		
		if not obj:
			match identification_type:
				IdentificationType.AUTOLOAD:
					return "CAUTION: Autoload nodes cannot be verified in-editor currently."
				
				IdentificationType.GLOBAL_SINGLETON:
					return "ERROR: No global singleton found with name " + global_identifier + "."
				
				_:
					return "ERROR: No node found in group " + global_identifier + " at index " + str(identifier_index) + "."
		
		var name := String(global_identifier)
		
		if obj is Node:
			name = obj.name
		
		var result := "Object \"" + name + "\" found with type " \
				+ str(obj.get_class()) \
				+ str( \
					"" if not obj.get_script() else  " (" + \
					( \
						(obj.get_script() as Script).resource_path if (obj.get_script() as Script).get_global_name().is_empty() else \
						(obj.get_script() as Script).get_global_name() \
					) \
					+ ")" \
				) \
				+ "."
		
		if property_path.is_empty():
			return result
		
		var property = obj.get_indexed(str(property_path))
		
		if property == null:
			result += "\nWARNING: Property \"" + property_path + "\" returned null."
		else:
			result += "\nProperty \"" + property_path + "\" found with type " \
						+ type_string(typeof(property)) \
						+ str(
							"" if typeof(property) != TYPE_OBJECT else " (" + \
							( \
								(property as Object).get_class() if not (property as Object).get_script() else \
								( \
									((property as Object).get_script() as Script).resource_path if ((property as Object).get_script() as Script).get_global_name().is_empty() else \
									((property as Object).get_script() as Script).get_global_name() \
								) \
							) \
							+ ")"
						) \
						+ " and current value " + var_to_str(property) + "."
		
		return result

@export_group("Identification Tools")

## Editor-only information about what singletons exist in the engine.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var available_global_singletons: PackedStringArray:
	get:
		return Engine.get_singleton_list()

## The node to assign to a group with name [member global_identifier].
@export_custom(PROPERTY_HINT_NODE_TYPE, "", PROPERTY_USAGE_EDITOR)
var picked_node: Node = null

## Assigns a given node to a group with name [member global_identifier].
@export_tool_button("Assign Picked Node to Group", "Groups")
var assign_picked_node_to_group := func() -> void:
	if global_identifier.is_empty():
		printerr("No identifier name specificed in global_identifier!")
		return
	
	picked_node.add_to_group(global_identifier, true)

func setup() -> void:
	data = _get_object()
	key = String(property_path)

# Returns either the node found at the desired path or null if not found.
func _get_object() -> Object:
	if global_identifier.is_empty():
		return null
	
	# REMARK: This is a limitation of the plugin. I have no idea how often
	# people replace the MainLoop with something that doesn't inherit from
	# SceneTree. Dear reader, if you're part of that niche, I would recommend
	# replacing this BoxFiller with something custom
	var scene_tree := Engine.get_main_loop() as SceneTree
	
	match identification_type:
		IdentificationType.AUTOLOAD:
			return scene_tree.root.get_node_or_null(str(&"/root/", global_identifier))
		
		IdentificationType.GLOBAL_SINGLETON:
			if Engine.has_singleton(global_identifier):
				return Engine.get_singleton(global_identifier)
			return null
	
	# Default to finding in a group
	
	if scene_tree.get_node_count_in_group(global_identifier) <= 0:
		return null
	
	var group_count := scene_tree.get_node_count_in_group(global_identifier)
	
	if identifier_index < 0 or identifier_index >= group_count:
		return null
	
	return scene_tree.get_nodes_in_group(global_identifier)[identifier_index]
