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
@icon("uid://xd23mhkvyjsx")
class_name IntBoxFiller
extends BoxFiller

## Fills the associated [Box] with an [int].

## The integral number to fill into the box.
@export
var value := 0:
	set(new_value):
		match limits_type:
			Limits.OR_LESSER:
				value = mini(new_value, limits_maximum)
			Limits.OR_GREATER:
				value = maxi(new_value, limits_minimum)
			Limits.HARD:
				value = clampi(new_value, limits_minimum, limits_maximum)
			_:
				value = new_value

@export_group("Limits", "limits_")

## Whether to have designer-controlled limits on the [member value].
@export
var limits_type := Limits.SOFT:
	set(new_value):
		limits_type = new_value
		
		if limits_type != Limits.SOFT:
			value = value

## The number the [member value] can't be lower than.
@export
var limits_minimum := 0:
	set(new_value):
		limits_minimum = mini(new_value, limits_maximum)
		
		if limits_type != Limits.SOFT:
			value = value

## The number the [member value] can't be higher than.
@export
var limits_maximum := 0:
	set(new_value):
		limits_maximum = maxi(new_value, limits_minimum)
		
		if limits_type != Limits.SOFT:
			value = value

## See [method Box.setup].
func setup() -> void:
	data = value
