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
@icon("uid://cl2fok6ir63m4")
class_name Vector3BoxFiller
extends BoxFiller

## Fills the associated [Box] with a [Vector3].

## The 3D vector to fill into the box.
@export_custom(PROPERTY_HINT_LINK, "")
var value := Vector3():
	set(new_value):
		value = new_value
		
		match limits_x_type:
			Limits.OR_LESSER:
				value.x = minf(value.x, limits_x_maximum)
			Limits.OR_GREATER:
				value.x = maxf(value.x, limits_x_minimum)
			Limits.HARD:
				value.x = clampf(value.x, limits_x_minimum, limits_x_maximum)
		
		match limits_y_type:
			Limits.OR_LESSER:
				value.y = minf(value.y, limits_y_maximum)
			Limits.OR_GREATER:
				value.y = maxf(value.y, limits_y_minimum)
			Limits.HARD:
				value.y = clampf(value.y, limits_y_minimum, limits_y_maximum)
		
		match limits_z_type:
			Limits.OR_LESSER:
				value.z = minf(value.z, limits_z_maximum)
			Limits.OR_GREATER:
				value.z = maxf(value.z, limits_z_minimum)
			Limits.HARD:
				value.z = clampf(value.z, limits_z_minimum, limits_z_maximum)

@export_group("Limits", "limits_")

@export_subgroup("X", "limits_x_")

## Whether to have designer-controlled limits on the x-axis of the [member value].
@export
var limits_x_type := Limits.SOFT:
	set(new_value):
		limits_x_type = new_value
		
		if limits_x_type != Limits.SOFT:
			value = value

## The number the x-axis of the [member value] can't be lower than.
@export
var limits_x_minimum := 0.0:
	set(new_value):
		limits_x_minimum = minf(new_value, limits_x_maximum)
		
		if limits_x_type != Limits.SOFT:
			value = value

## The number the x-axis of the [member value] can't be higher than.
@export
var limits_x_maximum := 0.0:
	set(new_value):
		limits_x_maximum = maxf(new_value, limits_x_minimum)
		
		if limits_x_type != Limits.SOFT:
			value = value

@export_subgroup("Y", "limits_y_")

## Whether to have designer-controlled limits on the y-axis of the [member value].
@export
var limits_y_type := Limits.SOFT:
	set(new_value):
		limits_y_type = new_value
		
		if limits_y_type != Limits.SOFT:
			value = value

## The number the y-axis of the [member value] can't be lower than.
@export
var limits_y_minimum := 0.0:
	set(new_value):
		limits_y_minimum = minf(new_value, limits_y_maximum)
		
		if limits_y_type != Limits.SOFT:
			value = value

## The number the y-axis of the [member value] can't be higher than.
@export
var limits_y_maximum := 0.0:
	set(new_value):
		limits_y_maximum = maxf(new_value, limits_y_minimum)
		
		if limits_y_type != Limits.SOFT:
			value = value

@export_subgroup("Z", "limits_z_")

## Whether to have designer-controlled limits on the z-axis of the [member value].
@export
var limits_z_type := Limits.SOFT:
	set(new_value):
		limits_z_type = new_value
		
		if limits_z_type != Limits.SOFT:
			value = value

## The number the z-axis of the [member value] can't be lower than.
@export
var limits_z_minimum := 0.0:
	set(new_value):
		limits_z_minimum = minf(new_value, limits_z_maximum)
		
		if limits_z_type != Limits.SOFT:
			value = value

## The number the z-axis of the [member value] can't be higher than.
@export
var limits_z_maximum := 0.0:
	set(new_value):
		limits_z_maximum = maxf(new_value, limits_z_minimum)
		
		if limits_z_type != Limits.SOFT:
			value = value

## See [method Box.setup].
func setup() -> void:
	data = value
