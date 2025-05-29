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

class_name IndefiniteAction
extends Action

## An action that lasts for a user-defined (i.e. indeterminate) amount of time.

var _start_ticks_msec := -1

## See [method Action.lasts]. Overriden to not affect [member Action.duration].
func lasts(_duration_sec: float = 0.0) -> Action:
	return self

## Use [method indefinite_enter] instead.
func enter() -> void:
	_start_ticks_msec = Time.get_ticks_msec()
	duration = 0.0
	indefinite_enter()

## Use [method indefinite_update] instead.
func update() -> void:
	if not is_reversed():
		duration = float(Time.get_ticks_msec() - _start_ticks_msec) / 1000.0
	
	indefinite_update()

func indefinite_enter() -> void:
	pass

func indefinite_update() -> void:
	pass

func done() -> bool:
	return _done or (_reversed and _time_passed <= 0.0)
