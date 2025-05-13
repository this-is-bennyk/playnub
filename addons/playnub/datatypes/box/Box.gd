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

## A resource that automatically writes its contents to the box's [member data].
## Useful for designer variables in the editor, but not so much in code.
## For procedural or dynamic data, it is recommended to instantiate a new box
## or use the [method rewrite] method; for example:
## [codeblock]
## var box_for_dynamic_obj := Box.new(my_object, "property:subproperty")
## box_for_dynamic_obj.rewrite(other_data)
## [/codeblock]
@export
var filler: BoxFiller = null:
	set(value):
		filler = value
		
		if filler != null:
			filler.setup()
			rewrite(filler.data, filler.key)

## The interface to the information or object stored.
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
				return (_actual_data as Callable).call()
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
			elif _is_callable:
				if (_key as Callable).is_null():
					assert(false, "Data cannot be set!")
				else:
					(_key as Callable).call(value)
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

## Writes [param new_data] into the box. If the [param new_key] is [code]null[/code], the box will access
## the data as it is.[br][br]
## If the [param new_key] is not [code]null[/code], the box will instead access a certain
## part of the object, depending on its type:[br][br]
## · If the [param new_data] is a [Dictionary], the [param new_key] must be a non-[code]null[/code] value.[br]
## · If the [param new_data] is an array type (ex. [Array], [PackedInt64Array], etc.), the [param new_key] must be an [int].[br]
## · If the [param new_data] is a [PackedDataContainer], the [param new_key] must be an [int], a [String], or a [StringName].[br]
## · If the [param new_data] is an [Object], the [param new_key] must be an [NodePath] (akin to [method Tween.tween_property]).[br]
## · If the [param new_data] is a [Callable], the [param new_key] must be a [Callable]. The signatures of the [Callable]s must match
## one of the following function styles (or binded using [method Callable.bind] or [method Callable.bindv] such that the remaining
## parameters match the following):[br][br]
## [i]As methods:[/i]
## [codeblock]
## func box_get() -> Variant: # A set type can be returned.
##     return null # Return something here.
## [/codeblock]
## [codeblock]
## func box_set(value: Variant) -> void: # The parameter can have a set type.
##     pass # Use the value as you'd like.
## [/codeblock]
## [i]As lambdas:[/i]
## [codeblock]
## func() -> Variant: # A set type can be returned.
##     return null # Return something here.
## [/codeblock]
## [codeblock]
## func(value: Variant) -> void: # The parameter can have a set type.
##     pass # Use the value as you'd like.
## [/codeblock]
## To emulate a constant variable, pass the empty callable [code]Callable()[/code] as the [param new_key].
## An error will be thrown in editor builds if the user attempts to set the value the box is referencing.
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
	
	if _is_callable:
		assert((_actual_data as Callable).is_valid(), "Boxed Callable is not valid!")
		assert((_actual_data as Callable).get_argument_count() == 0, "Boxed Callable is not (acting as) a getter function!")
	
	if _key != null:
		if is_array:
			assert(_key is int, "Key for array type is not int!")
		
		elif _actual_data is Dictionary:
			return
		
		elif is_packed_data_container:
			assert(_key is int or _key is String or _key is StringName, "Key for PackedDataContainer type is not int/String/StringName!")
		
		elif is_object:
			assert(_key is NodePath or _key is String, "Key for Object type is not NodePath!")
			
			if _key is String:
				_key = NodePath(_key as String)
		
		# The bool key determines if you can set the value the callable manipulates
		elif is_callable:
			assert(_key is Callable, "Key for Callable type is not Callable!")
			assert((_key as Callable).is_null() or ((_key as Callable).is_valid() and (_key as Callable).get_argument_count() == 1), "Key for Callable type is neither an empty Callable nor (acting as) a setter function!")
		
		else:
			assert(false, "Data cannot be indexed!")
