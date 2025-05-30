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
# Actions that have already been processed this frame and the step they were executed at.
# Useful if the list is changed mid-processing.
var _processed_actions: Dictionary[Action, int] = {}
# The delta time given to us, adjusted by different scales.
var _delta := 0.0

# Internal flag to detect when a change was made to the action list. Useful for when this occurs mid-processing.
var _dirty := false

## Processes each action in order by progressing them by [param delta] times [member delta_multiplier] seconds.
func update(delta: float) -> void:
	var list_index := 0
	var execution_index := 0
	_delta = delta
	
	# Acknowledge changes from a previous call, if there was one
	_dirty = false
	# Remove all blocks for this frame
	_blocked_groups.clear()
	# Prepare to process all actions
	_processed_actions.clear()
	
	# For each action in the buffer currently being processed...
	while list_index < _actions.size():
		var action := _actions[list_index]
		
		# If this action wasn't already processed this frame or is not done executing...
		if not (_processed_actions.has(action) or action.done()):
			# Process the action if it isn't in a group that's being blocked
			if not action.participating_groups.any_bits_from(_blocked_groups):
				action.process(_get_adjusted_delta(), execution_index, list_index)
			
			# Mark this action as having been processed for this frame
			_processed_actions[action] = execution_index
			execution_index += 1
			
			if not action.done():
				# Add the groups the action is blocking to the block list, if it has any
				action.blocking_groups.merge_onto(_blocked_groups)
			
			# If the state of the action list has changed mid-processing,
			# restart to account for the changes
			if _dirty:
				# Restart the blocked group since we're going back to the beginning
				_blocked_groups.clear()
				# Restart the loop (-1 since list_index will increase to 0 at the end of the loop)
				list_index = -1
		
		list_index += 1

## Returns whether there are any actions to process.
func is_empty() -> bool:
	if _actions.is_empty():
		return true
	
	for action: Action in _actions:
		if not action.done():
			return false
	
	return true

## Returns the total amount of time this action list processes for, in seconds.
func get_total_processing_time() -> float:
	# Retrieve which actions are blocked and which groups they're blocked in
	
	var temp_blocking_groups := Bitset.new()
	var actions_blocked := Bitset.new()
	
	for index: int in _actions.size():
		var action := _actions[index]
		
		var blocked := action.participating_groups.any_bits_from(temp_blocking_groups)
		
		actions_blocked.set_bit(index, blocked)
		action.blocking_groups.merge_onto(temp_blocking_groups)
	
	var longest_time := 0.0
	var group_times := PackedFloat64Array()
	group_times.resize(temp_blocking_groups.size())
	
	# Get the total execution times of the blocked groups
	# and the longest execution time of non-blocked actions
	
	for index: int in _actions.size():
		var action := _actions[index]
		
		if actions_blocked.get_bit(index):
			for group_index: int in action.participating_groups.size():
				if temp_blocking_groups.get_bit(group_index):
					group_times[group_index] += action.get_total_processing_time()
		else:
			longest_time = maxf(longest_time, action.get_total_processing_time())
	
	# Get the longest time out of the groups and the non-blocked actions
	
	for time: float in group_times:
		longest_time = maxf(longest_time, time)
	
	return longest_time

## Adds an [param action] to the end of the action list.
func push_back(action: Action) -> void:
	_actions.append(action)
	_dirty = true

## Adds multiple [Action]s from a [param list] to the end of the action list.
func push_back_list(list: Array[Action]) -> void:
	_actions.append_array(list)
	_dirty = true

## Adds an [param action] to the start of the action list.
func push_front(action: Action) -> void:
	_actions.push_front(action)
	_dirty = true

## Adds multiple [Action]s from a [param list] to the start of the action list.
func push_front_list(list: Array[Action]) -> void:
	var new_list: Array[Action] = []
	
	new_list.append_array(list)
	new_list.append_array(_actions)
	
	_actions = new_list
	
	_dirty = true

## Clears the action list of any actions it may have.
func clear_all() -> void:
	_actions.clear()
	_dirty = true

## Clears only actions that are finished as indicated by [method Action.done].
func clear_finished() -> void:
	# REMARK: Processed in reverse order to avoid index invalidation
	# It is also faster since it's more likely there are fewer elements to move back an index
	for index: int in range(_actions.size() - 1, -1, -1):
		if _actions[index].done():
			_actions.remove_at(index)
	
	_dirty = true

## @experimental
## Makes the action list play in reverse order.
func reverse() -> void:
	_actions.reverse()
	
	for action: Action in _actions:
		action.reverse()
	
	_dirty = true

## Makes the list resets progress to its beginning,
## which is the [b]last[/b] action added if reversed and the [b]first[/b] action added if not.
func restart() -> void:
	for action: Action in _actions:
		action.restart()
	
	_dirty = true

## Instantly completes the processing of all remaining actions.
func skip() -> void:
	var list_index := 0
	var execution_index := 0
	
	for action: Action in _actions:
		if not action.done():
			# Force indefinite actions to finish cleanly
			if action is IndefiniteAction:
				action.finish()
				action.process(_get_adjusted_delta(), execution_index, list_index)
			# Force all actions to finish processing
			else:
				action.process(action.get_absolute_time_remaining(), execution_index, list_index)
			
			execution_index += 1
		
		list_index += 1
	
	_dirty = true

func _get_adjusted_delta() -> float:
	return _delta * delta_multiplier * (1.0 if ignore_engine_time_scale else Engine.time_scale)
