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
class_name NodePropertyBoxFiller
extends BoxFiller

## Fills the associated [Box] with a node and a property path.

## The group of nodes to look for.
@export
var node_group := &"":
	set(value):
		node_group = value
		emit_changed()

## The index of the specific node in the [member node_group].
@export_range(0, 1, 1, "or_greater")
var group_index := 0:
	set(value):
		group_index = value
		emit_changed()

## Optional path to a specific property on the selected node.
@export
var property_path := &"":
	set(value):
		property_path = value
		emit_changed()

## Editor-only pseudo-console to let the designer know if there's any issues with retrieving
## the node and its specific value.
@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var compilation := "":
	get:
		if (not Engine.is_editor_hint()) or node_group.is_empty():
			return "ERROR: No group specified."
		
		var node := _get_node()
		
		if not node:
			return "ERROR: No node found in group " + node_group + " at index " + str(group_index) + "."
		
		var result := "Node \"" + node.name + "\" found with type " \
				+ str(node.get_class()) \
				+ str( \
					"" if not node.get_script() else  " (" + \
					( \
						(node.get_script() as Script).resource_path if (node.get_script() as Script).get_global_name().is_empty() else \
						(node.get_script() as Script).get_global_name() \
					) \
					+ ")" \
				) \
				+ "."
		
		if property_path.is_empty():
			return result
		
		var property = node.get_indexed(str(property_path))
		
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

@export_group("Group Assignment")

@export_custom(PROPERTY_HINT_NODE_TYPE, "", PROPERTY_USAGE_EDITOR)
var picked_node: Node = null

@export_tool_button("Assign Picked Node to Group", "Groups")
var assign_picked_node_to_group := func() -> void:
	if node_group.is_empty():
		printerr("No group name specificed in node_group!")
		return
	
	picked_node.add_to_group(node_group, true)

func setup() -> void:
	data = _get_node()
	key = String(property_path)

# Returns either the node found at the desired path or null if not found.
func _get_node() -> Node:
	# REMARK: This is a limitation of the plugin. I have no idea how often
	# people replace the MainLoop with something that doesn't inherit from
	# SceneTree. Dear reader, if you're part of that niche, I would recommend
	# replacing this BoxFiller with something custom
	var scene_tree := Engine.get_main_loop() as SceneTree
	
	if node_group.is_empty() or scene_tree.get_node_count_in_group(node_group) <= 0:
		return null
	
	var group_count := scene_tree.get_node_count_in_group(node_group)
	
	if group_index < 0 or group_index >= group_count:
		return null
	
	return scene_tree.get_nodes_in_group(node_group)[group_index]
