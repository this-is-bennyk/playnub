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
class_name IntBoxFiller
extends BoxFiller

@export
var value := 0:
	set(new_value):
		if limits_enabled:
			value = clampi(new_value, limits_minimum, limits_maximum)
		else:
			value = new_value

@export_group("Limits", "limits_")

@export
var limits_enabled := false:
	set(new_value):
		limits_enabled = new_value
		
		if limits_enabled:
			value = value

@export
var limits_minimum := 0:
	set(new_value):
		limits_minimum = mini(new_value, limits_maximum)
		
		if limits_enabled:
			value = value

@export
var limits_maximum := 0:
	set(new_value):
		limits_maximum = maxi(new_value, limits_minimum)
		
		if limits_enabled:
			value = value

func setup() -> void:
	data = value
