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

class_name Box
extends Resource

## A reference-counted wrapper around a value by itself or inside an object.
##
## This class serves to act like a "reference" in GDScript. Primitive values
## are not passed by reference, and you cannot pass a reference to a member variable
## (except in certain situations, like with the [Tween]). This would mean duplicating
## code to pass around values of particular objects to other places, so the [Box]
## aims to avoid that, and add additional functionality to access specific parts of
## complex objects.

@export
var filler: BoxFiller = null

var data:
	get:
		if _key != null:
			if _is_container:
				return _actual_data[_key]
			elif _is_obj:
				if is_instance_valid(_actual_data):
					return (_actual_data as Object).get_indexed(_key)
				else:
					return null
			elif _is_callable and _key:
				return (_actual_data as Callable).call(false)
			else:
				assert(false, "Data cannot be indexed!")
		
		return _actual_data
	
	set(value):
		if _key != null:
			if _is_container:
				_actual_data[_key] = value
			elif _is_obj:
				if is_instance_valid(_actual_data):
					(_actual_data as Object).set_indexed(_key, value)
			elif _is_callable and _key:
				(_actual_data as Callable).call(true, value)
			else:
				assert(false, "Data cannot be indexed!")
		else:
			_actual_data = value

#region Built-in Types

var boolean: bool:
	get:
		return data as bool
	set(value):
		data = value

var integer: int:
	get:
		return data as int
	set(value):
		data = value

var floating_point: float:
	get:
		return data as float
	set(value):
		data = value

var string: String:
	get:
		return data as String
	set(value):
		data = value

var string_name: StringName:
	get:
		return data as StringName
	set(value):
		data = value

var nodepath: NodePath:
	get:
		return data as NodePath
	set(value):
		data = value

var vec2: Vector2:
	get:
		return data as Vector2
	set(value):
		data = value

var vec2i: Vector2i:
	get:
		return data as Vector2i
	set(value):
		data = value

var rect2: Rect2:
	get:
		return data as Rect2
	set(value):
		data = value

var vec3: Vector3:
	get:
		return data as Vector3
	set(value):
		data = value

var vec3i: Vector3i:
	get:
		return data as Vector3i
	set(value):
		data = value

var transform2D: Transform2D:
	get:
		return data as Transform2D
	set(value):
		data = value

var plane: Plane:
	get:
		return data as Plane
	set(value):
		data = value

var quaternion: Quaternion:
	get:
		return data as Quaternion
	set(value):
		data = value

var aabb: AABB:
	get:
		return data as AABB
	set(value):
		data = value

var basis: Basis:
	get:
		return data as Basis
	set(value):
		data = value

var transform3D: Transform3D:
	get:
		return data as Transform3D
	set(value):
		data = value

var color: Color:
	get:
		return data as Color
	set(value):
		data = value

var rid: RID:
	get:
		return data as RID
	set(value):
		data = value

var object: Object:
	get:
		return data as Object
	set(value):
		data = value

var array: Array:
	get:
		return data as Array
	set(value):
		data = value

var packed_byte_array: PackedByteArray:
	get:
		return data as PackedByteArray
	set(value):
		data = value

var packed_int32_array: PackedInt32Array:
	get:
		return data as PackedInt32Array
	set(value):
		data = value

var packed_int64_array: PackedInt64Array:
	get:
		return data as PackedInt64Array
	set(value):
		data = value

var packed_float32_array: PackedFloat32Array:
	get:
		return data as PackedFloat32Array
	set(value):
		data = value

var packed_float64_array: PackedFloat64Array:
	get:
		return data as PackedFloat64Array
	set(value):
		data = value

var packed_string_array: PackedStringArray:
	get:
		return data as PackedStringArray
	set(value):
		data = value

var packed_vec2_array: PackedVector2Array:
	get:
		return data as PackedVector2Array
	set(value):
		data = value

var packed_vec3_array: PackedVector3Array:
	get:
		return data as PackedVector3Array
	set(value):
		data = value

var packed_color_array: PackedColorArray:
	get:
		return data as PackedColorArray
	set(value):
		data = value

var dictionary: Dictionary:
	get:
		return data as Dictionary
	set(value):
		data = value

var signal_: Signal:
	get:
		return data as Signal
	set(value):
		data = value

var callable: Callable:
	get:
		return data as Callable
	set(value):
		data = value

#endregion

var _actual_data = null
var _key = null

var _is_container := false
var _is_obj := false
var _is_callable := false

func _init(_data_ = null, _key_ = null) -> void:
	if filler:
		rewrite(filler.data, filler.key)
	else:
		rewrite(_data_, _key_)

## Writes [param new_data] into the box. If the [param new_key] is not [code]null[/code], it will access a certain
## part of the object, depending on its type:[br]
## If the [param new_data] is a [Dictionary], the [param new_key] may be anything.[br]
## If the [param new_data] is an array type (ex. [Array], [PackedInt64Array], etc.), the [param new_key] must be an [int].[br]
## If the [param new_data] is a [PackedDataContainer], the [param new_key] must be an [int], a [String], or a [StringName].[br]
## If the [param new_data] is an [Object], the [param new_key] must be an [NodePath] (akin to [method Tween.tween_property]).[br]
## If the [param new_data] is a [Callable], the [param new_key] must be [code]true[/code] or [code]false[/code], and the
## signature of the [Callable] must match one of the following:[br]
## As a method:
## [codeblock]
## func box_setget(setting: bool, value = null) -> Variant:
##     # Recommended layout.
##     if setting:
##         pass # Use the value as you'd like.
##     return null # Return something here.
## [/codeblock]
## As a lambda:
## [codeblock]
## func(setting: bool, value = null) -> Variant:
##     # Recommended layout.
##     if setting:
##         pass # Use the value as you'd like.
##     return null # Return something here.
## [/codeblock]
func rewrite(new_data, new_key = null) -> void:
	_actual_data = new_data
	_key = new_key
	
	var is_array := (_actual_data is Array
				  or _actual_data is PackedByteArray
				  or _actual_data is PackedColorArray
				  or _actual_data is PackedFloat32Array
				  or _actual_data is PackedFloat64Array
				  or _actual_data is PackedInt32Array
				  or _actual_data is PackedInt64Array
				  or _actual_data is PackedStringArray
				  or _actual_data is PackedVector2Array
				  or _actual_data is PackedVector3Array)
	
	var is_packed_data_container := _actual_data is PackedDataContainer
	var is_generic_container := is_packed_data_container or _actual_data is Dictionary
	var is_object := _actual_data is Object
	var is_callable := _actual_data is Callable
	
	_is_container = is_array or is_generic_container
	_is_obj = is_object
	_is_callable = is_callable
	
	if _key != null:
		if is_array:
			assert(_key is int, "Key for array type is not int!")
		
		elif is_packed_data_container:
			assert(_key is int or _key is String or _key is StringName, "Key for PackedDataContainer type is not int/String/StringName!")
		
		elif is_object:
			assert(_key is NodePath or _key is String, "Key for object type is not NodePath!")
			
			if _key is String:
				_key = NodePath(_key as String)
			
		elif is_callable:
			assert(_key is bool, "Key for callable type is not bool!")
		
		else:
			assert(false, "Data cannot be indexed!")
