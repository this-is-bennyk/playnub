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

class_name ActionList
extends RefCounted

## A general-purpose command pattern data structure.
## 
## TODO

const FAST_FORWARD_TIME := 999999.0

## A number to multiply the delta time by to speed up or slow down the action list.
## Must be greater than or equal to 0.
var delta_multiplier := 1.0:
	set(value):
		delta_multiplier = maxf(0.0, value)

## Whether [member Engine.time_scale] affects the speed of the action list.
var ignore_engine_time_scale := false

## The list of actions being processed in the current frame.
var front_buffer: Array[Action]:
	get:
		return _action_buffer_1 if _buffer_1_is_front else _action_buffer_2

## The list of actions to process during the next frame.
var back_buffer: Array[Action]:
	get:
		return _action_buffer_2 if _buffer_1_is_front else _action_buffer_1

# The tags of actions that are currently being blocked each frame.
var _blocked_groups := Bitset.new()

# Two lists that are swapped between to allow for complex actions such as
# adding actions midframe or creating a new set entirely.
var _action_buffer_1: Array[Action] = []
var _action_buffer_2: Array[Action] = []

# If true, use the first action buffer as the one currently being processed
# and the second as the list of actions the next frame should process.
# Vice versa otherwise.
var _buffer_1_is_front := false

# Internal flag to stop updating the action list if it was reversed mid-update.
var _dirty_by_reverse := false

## Processes each action in order by progressing them by [param dt] times [member delta_multiplier] seconds.
func update(dt: float) -> void:
	# Swap to the buffer with actions accumulated from the last frame
	_buffer_1_is_front = not _buffer_1_is_front
	
	_dirty_by_reverse = false
	# Remove all blocks for this frame
	_blocked_groups.clear()
	# Clean out the back buffer to handle the next frame's actions
	back_buffer.clear()
	
	var execution_index := 0
	var list_index := -1
	var adjusted_dt := delta_multiplier * dt
	
	if ignore_engine_time_scale:
		adjusted_dt *= Engine.time_scale
	
	# For each action in the buffer currently being processed...
	for action: Action in front_buffer:
		list_index += 1
		
		# Process the action if it isn't in a group that's being blocked
		if not action.participating_groups.any_bits_from(_blocked_groups):
			action.process(adjusted_dt, execution_index, list_index)
		
		if not action.done():
			# Add the groups the action is blocking to the block list, if it has any
			action.blocking_groups.merge_onto(_blocked_groups)
			push(action)
		
		if _dirty_by_reverse:
			return
		
		execution_index += 1

## Adds an [param action] to the end of the [member back_buffer].
func push(action: Action) -> void:
	back_buffer.append(action)

## Adds multiple [Action]s from a [param list] to the end of the [member back_buffer].
func push_list(list: Array[Action]) -> void:
	back_buffer.append_array(list)

func push_front(action: Action) -> void:
	back_buffer.push_front(action)

func push_front_list(list: Array[Action]) -> void:
	for idx: int in range(list.size() - 1, -1, -1):
		back_buffer.push_front(list[idx])

## Clears the action list of any actions it may have.
func clear() -> void:
	_blocked_groups.clear()
	back_buffer.clear()
	front_buffer.clear()

func reverse() -> void:
	back_buffer.reverse()
	
	for action: Action in back_buffer:
		action.reverse()
	
	_dirty_by_reverse = true

func is_empty() -> bool:
	return back_buffer.is_empty()

func fast_forward() -> void:
	update(FAST_FORWARD_TIME)
