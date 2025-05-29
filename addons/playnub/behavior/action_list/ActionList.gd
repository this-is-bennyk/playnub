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

## A general-purpose command pattern system.
## 
## The command pattern is extremely important to game development. Many actions
## in games are done in discrete sequences, which is painful to define manually in code.
## [AnimationPlayer]s and [Tween]s serves this purpose somewhat, but are not flexible enough
## for complex behaviors. The [ActionList] is a solution for executing any game logic in
## any order desired, with methods for manipulating and organizing game logic in
## separable [Action]s in ways that are not possible with [AnimationPlayer]s or
## [Tween]s alone.

const FAST_FORWARD_TIME := 999999.0

## A number to multiply the delta time by to speed up or slow down the action list.
## Must be greater than or equal to 0.
var delta_multiplier := 1.0:
	set(value):
		delta_multiplier = maxf(0.0, value)

## Whether [member Engine.time_scale] affects the speed of the action list.
var ignore_engine_time_scale := false

# The list of actions being processed in the current frame.
var _actions: Array[Action] = []

# The tags of actions that are currently being blocked each frame.
var _blocked_groups := Bitset.new()

# Whether the action list is currently processing the actions.
var _processing := false
# List of calls that were made to modify the action list, executed after the list has been processed.
var _mid_update_modifications: Array[Callable] = []

# Internal flag to stop updating the action list if it was reversed mid-update.
var _dirty_by_reverse := false

## Processes each action in order by progressing them by [param delta] times [member delta_multiplier] seconds.
func update(delta: float) -> void:
	# Acknowledge reversal from a previous call, if there was one
	_dirty_by_reverse = false
	# Remove all blocks for this frame
	_blocked_groups.clear()
	
	var execution_index := 0
	var list_index := -1
	var adjusted_dt := delta_multiplier * delta
	
	if ignore_engine_time_scale:
		adjusted_dt *= Engine.time_scale
	
	# Lock the action list from modifications
	_processing = true
	
	# For each action in the buffer currently being processed...
	for action: Action in _actions:
		list_index += 1
		
		if action.done():
			continue
		
		# Process the action if it isn't in a group that's being blocked
		if not action.participating_groups.any_bits_from(_blocked_groups):
			action.process(adjusted_dt, execution_index, list_index)
		
		if not action.done():
			# Add the groups the action is blocking to the block list, if it has any
			action.blocking_groups.merge_onto(_blocked_groups)
			push_back(action)
		
		# If we reversed the list midway through processing, stop processing
		# since the state of the list has changed
		if _dirty_by_reverse:
			break
		
		execution_index += 1
	
	# Unlock the action list for modifications
	_processing = false
	
	# Apply modifications after the fact
	
	for modification: Callable in _mid_update_modifications:
		modification.call()
	
	_mid_update_modifications.clear()

## Adds an [param action] to the end of the action list.
func push_back(action: Action) -> void:
	if _processing:
		_mid_update_modifications.push_back(push_back.bind(action))
		return
	
	_actions.append(action)

## Adds multiple [Action]s from a [param list] to the end of the action list.
func push_back_list(list: Array[Action]) -> void:
	if _processing:
		_mid_update_modifications.push_back(push_back_list.bind(list))
		return
	
	_actions.append_array(list)

## Adds an [param action] to the start of the action list.
func push_front(action: Action) -> void:
	if _processing:
		_mid_update_modifications.push_back(push_front.bind(action))
		return
	
	_actions.push_front(action)

## Adds multiple [Action]s from a [param list] to the start of the action list.
func push_front_list(list: Array[Action]) -> void:
	if _processing:
		_mid_update_modifications.push_back(push_front_list.bind(list))
		return
	
	var new_list: Array[Action] = []
	
	new_list.append_array(list)
	new_list.append_array(_actions)
	
	_actions = new_list

## Clears the action list of any actions it may have.
func clear(only_done_actions := false) -> void:
	if _processing:
		_mid_update_modifications.push_back(clear)
		return
	
	if only_done_actions:
		for index: int in range(_actions.size() - 1, -1, -1):
			if _actions[index].done():
				_actions.remove_at(index)
	else:
		_actions.clear()
		_blocked_groups.clear()

## @experimental
## Makes the action list play in reverse order.[br]
## If [param restart] is [code]true[/code], the list resets progress to its new beginning,
## which is the [b]last[/b] action added if reversed and the [b]first[/b] action added if not.[br]
## Otherwise, the list reverses progress from the current amount of time passed to its new end,
## which is the [b]first[/b] action added if reversed and the [b]last[/b] action added if not.
func reverse(restart: bool) -> void:
	_actions.reverse()
	
	for action: Action in _actions:
		action.reverse(restart)
	
	_dirty_by_reverse = true

## Returns whether there are any actions being processed.
func is_empty() -> bool:
	return _actions.is_empty()

#func get_total_processing

## @experimental
## Instantly processes all actions up until the end.
func fast_forward() -> void:
	update(FAST_FORWARD_TIME)
