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

class_name Box
extends Resource

## A reference-counted wrapper around a value by itself or inside an object.
##
## This class serves to act like a "reference" in GDScript. Primitive values
## are not passed by reference, and you cannot pass a reference to a member variable
## (except in certain situations, like with the [Tween]). This would mean duplicating
## code to pass around values of particular objects to other places, so the [Box]
## lets one do this, and adds additional functionality to access specific parts of
## complex objects.

@export
var filler: BoxFiller = null:
	set(value):
		filler = value
		
		if filler != null:
			filler.setup()
			rewrite(filler.data, filler.key)

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
			elif _is_callable:
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
			# If the data is a callable and you're allowed to set the data...
			elif _is_callable and _key:
				# Set it via the callable
				(_actual_data as Callable).call(true, value)
			else:
				assert(false, "Data cannot be indexed!")
		else:
			_actual_data = value

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
## · If the [param new_data] is a [Dictionary], the [param new_key] may be anything.[br]
## · If the [param new_data] is an array type (ex. [Array], [PackedInt64Array], etc.), the [param new_key] must be an [int].[br]
## · If the [param new_data] is a [PackedDataContainer], the [param new_key] must be an [int], a [String], or a [StringName].[br]
## · If the [param new_data] is an [Object], the [param new_key] must be an [NodePath] (akin to [method Tween.tween_property]).[br]
## · If the [param new_data] is a [Callable], the [param new_key] must be [code]true[/code] or [code]false[/code] to specify
## whether to allow writing / setting the data manipulated by the [Callable], and the signature of the [Callable] must match one of the following
## (or binded such that the remaining parameters match the following):[br]
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
		
		elif _actual_data is Dictionary:
			return
		
		elif is_packed_data_container:
			assert(_key is int or _key is String or _key is StringName, "Key for PackedDataContainer type is not int/String/StringName!")
		
		elif is_object:
			assert(_key is NodePath or _key is String, "Key for object type is not NodePath!")
			
			if _key is String:
				_key = NodePath(_key as String)
		
		# The bool key determines if you can set the value the callable manipulates
		elif is_callable:
			assert(_key is bool, "Key for callable type is not bool!")
		
		else:
			assert(false, "Data cannot be indexed!")
