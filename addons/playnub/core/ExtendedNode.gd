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

class_name ExtendedNode

## An extension of the default [Node] with QoL features.
##
## This class acts as an interface for all [Node]s in the Playnub plugin.

extends Node

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
	if not script_type.is_empty():
		add_to_group(script_type)
	add_to_group(builtin_type)
