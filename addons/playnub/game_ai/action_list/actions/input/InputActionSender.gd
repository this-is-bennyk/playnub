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

extends InputEventSender

## Simulates a certain [InputEventAction], as if a user did the action.

class_name InputActionSender

func sends(action_name: StringName) -> InputActionSender:
	var begin := InputEventAction.new()
	var end := InputEventAction.new()
	
	begin.action = action_name
	end.action = action_name
	
	begin.pressed = true
	end.pressed = false
	
	begins_with(begin).ends_with(end)
	
	return self

func enter() -> void:
	Input.action_press((_begin_event as InputEventAction).action)
	super()

func exit() -> void:
	Input.action_release((_end_event as InputEventAction).action)
	super()
