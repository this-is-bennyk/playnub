class_name ExtendedNode
extends Node

## An extension of the default [Node] with QoL features.
##
## This class acts as an interface for all [Node]s in the Standard BK Library.

var attached_script: Script:
	get:
		return get_script() as Script

var script_type: StringName = &"":
	get:
		if script_type.is_empty():
			script_type = attached_script.get_global_name()
		return script_type

var builtin_type: StringName = &"":
	get:
		if builtin_type.is_empty():
			builtin_type = get_class()
		return builtin_type

var upcasted: Node:
	get:
		return self as Node

func _ready() -> void:
	add_to_group(script_type)
	add_to_group(builtin_type)
