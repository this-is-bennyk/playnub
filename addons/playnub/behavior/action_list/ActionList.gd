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

## Whether to enforce actions that added to the list to match the reversed state of the list.[br][br]
## When [code]true[/code], functions starting with [code]push_*[/code], [code]insert_*[/code],
## [code]pop_*[/code], and [code]remove_*[/code] will perform their operations with respect to the order of the list when not reversed.[br]
## Also, all actions' states of reversal are [b]guaranteed[/b] to be synchronized with the list's state of reversal.[br]
## For example, if an action is added via [method push_back] and the list is reversed, it instead gets added to the [b]front[/b] of the list
## and automatically gets reversed to match the list being reversed.[br][br]
## When [code]false[/code], functions functions starting with [code]push_*[/code], [code]insert_*[/code],
## [code]pop_*[/code], and [code]remove_*[/code] will perform their operations with respect to the current order of the list.[br]
## Also, any action's state of reversal is [b]not guaranteed[/b] to be synchronized with the list's state of reversal.[br]
## For example, if an action is added via [method push_back] and the list is reversed, it still gets added to the [b]back[/b] of the list
## and does not automatically get reversed, staying in whichever state it was in previously.[br][br]
## When changing this from [code]false[/code] to [code]true[/code], any actions that are not synchronized with the
## list's state of reversal are changed automatically to keep the synchronicity guaranteed. Their order, however, is
## unaffected from the way they were inserted or removed when the synchronicity wasn't being kept.[br][br]
## This property is for advanced use cases. Keep it to [code]true[/code] if the action list doesn't
## need to utilize mixed states of reversal.
var reversal_state_synchronized := true:
	set(value):
		var prev_value := reversal_state_synchronized
		
		reversal_state_synchronized = value
		
		if (not prev_value) and value:
			for action: Action in _actions:
				if action.is_reversed() != _reversed:
					action.reverse()

# The list of actions being processed in the current frame.
var _actions: Array[Action] = []

# The tags of actions that are currently being blocked each frame.
var _blocked_groups := Bitset.new()
# Actions that have already been processed this frame and the step they were executed at.
# Useful if the list is changed mid-processing.
var _processed_actions: Dictionary[Action, int] = {}
# The delta time given to us, adjusted by different scales.
var _delta := 0.0
# Whether the action list is reversed.
var _reversed := false
# The total amount of time that it takes to process the whole list. Cached for performance,
# updated only when a change occurs.
var _cached_total_processing_time := 0.0

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
		if not _processed_actions.has(action):
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
				# Restart the loop (-1 since list_index will increase to 0 at the end of the loop)
				list_index = -1
		
		list_index += 1

## Returns the number of actions currently in the list, regardless of whether they're processing.
func size_total() -> int:
	return _actions.size()

## Returns whether there are any actions in the list, regardless of whether they're processing.
func is_empty_total() -> bool:
	return _actions.is_empty()

## Returns the number of actions that are yet to be done processing.
func size_processable() -> int:
	if _actions.is_empty():
		return 0
	
	var result := 0
	
	for action: Action in _actions:
		result += int(not action.done())
	
	return result

## Returns whether there are any actions to process.
func is_empty_processable() -> bool:
	if _actions.is_empty():
		return true
	
	for action: Action in _actions:
		if not action.done():
			return false
	
	return true

## Returns the total amount of time this action list processes for, in seconds.
func get_total_processing_time() -> float:
	if _dirty:
		# Retrieve which actions are blocked and which groups they're blocked in
		
		var temp_blocking_groups := Bitset.new()
		var actions_blocked := Bitset.new()
		
		for index: int in _actions.size():
			var action := _actions[index]
			
			var blocked := action.participating_groups.any_bits_from(temp_blocking_groups)
			
			actions_blocked.set_bit(index, blocked)
			action.blocking_groups.merge_onto(temp_blocking_groups)
		
		var group_times := PackedFloat64Array()
		group_times.resize(temp_blocking_groups.size())
		
		# Get the total execution times of the blocked groups
		# and the longest execution time of non-blocked actions
		
		for index: int in _actions.size():
			var action := _actions[index]
			
			for group_index: int in action.participating_groups.size():
				if temp_blocking_groups.get_bit(group_index):
					group_times[group_index] += action.get_total_processing_time()
				else:
					group_times[group_index] = maxf(group_times[group_index], action.get_total_processing_time())
		
		# Get the longest time out of the groups and the non-blocked actions
		
		_cached_total_processing_time = 0.0
		
		for time: float in group_times:
			_cached_total_processing_time = maxf(_cached_total_processing_time, time)
	
	return _cached_total_processing_time

## Returns whether this action list is reversed.
func is_reversed() -> bool:
	return _reversed

## Adds an [param action] to the end of the action list.
func push_back(action: Action) -> void:
	_prepare_fresh_action(action)
	
	if _syncing_reversal():
		_actions.push_front(action)
	else:
		_actions.push_back(action)
	
	_dirty = true

## Adds multiple [Action]s from a [param list] to the end of the action list.
func push_back_list(list: Array[Action]) -> void:
	_prepare_fresh_list(list, false)
	
	if _syncing_reversal():
		_actions.reverse()
	
	_actions.append_array(list)
	
	if _syncing_reversal():
		_actions.reverse()
	
	_dirty = true

## Adds an [param action] to the start of the action list.[br]
## [b]NOTE[/b]: See [method Array.push_front] for performance risks associated with this method.
func push_front(action: Action) -> void:
	_prepare_fresh_action(action)
	
	if _syncing_reversal():
		_actions.push_back(action)
	else:
		_actions.push_front(action)
	
	_dirty = true

## Adds multiple [Action]s from a [param list] to the start of the action list.[br]
func push_front_list(list: Array[Action]) -> void:
	_prepare_fresh_list(list, true)
	
	# Allocating a new array is faster than using push_front() for each element in reverse order (O(N) < O(N^2))
	var new_list: Array[Action] = []
	var keeping_continuity := _syncing_reversal()
	
	new_list.append_array(list if keeping_continuity else _actions)
	new_list.append_array(_actions if keeping_continuity else list)
	
	_actions = new_list
	
	_dirty = true

## Inserts an [param action] at the given [param index] of the action list.
## If the [param index] is beyond the start or end of the list, it is treated
## like [method push_front] or [method push_back].[br]
## [b]NOTE[/b]: See [method Array.insert] and [method Array.push_front] for
## performance risks associated with this method.
func insert(index: int, action: Action) -> void:
	if index <= 0:
		push_front(action)
	elif index >= _actions.size():
		push_back(action)
	else:
		_prepare_fresh_action(action)
		
		_actions.insert(_actions.size() - 1 - index if _syncing_reversal() else index, action)
		_dirty = true

## Inserts a [param list] of actions at the given [param index] of the action list.
## If the [param index] is beyond the start or end of the list, it is treated
## like [method push_front_list] or [method push_back_list].
func insert_list(index: int, list: Array[Action]) -> void:
	if index < 0:
		push_front_list(list)
	elif index >= _actions.size():
		push_back_list(list)
	else:
		_prepare_fresh_list(list, true)
		
		# Allocating a new array is faster than using insert() for each element in reverse order (O(N) < O(N^2))
		var new_list: Array[Action] = []
		var keeping_continuity := _syncing_reversal()
		
		new_list.append_array(_actions.slice(0, _actions.size() - index) if keeping_continuity else _actions.slice(0, index))
		new_list.append_array(list)
		new_list.append_array(_actions.slice(_actions.size() - index) if keeping_continuity else _actions.slice(index))
		
		_actions = new_list
	
		_dirty = true

## Removes and returns the last action in the list, or [code]null[/code] if there are no actions.
func pop_back() -> Action:
	_dirty = true
	
	if _syncing_reversal():
		return _actions.pop_front() as Action
	return _actions.pop_back() as Action

## Removes and returns the first action in the list, or [code]null[/code] if there are no actions.
func pop_front() -> Action:
	_dirty = true
	
	if _syncing_reversal():
		return _actions.pop_back() as Action
	return _actions.pop_front() as Action

## Removes and returns the action at the given [param index] in the list, or [code]null[/code] if there are no actions.
func pop_at(index: int) -> Action:
	if index < 0 or index >= _actions.size():
		return null
	
	_dirty = true
	return _actions.pop_at(_actions.size() - 1 - index if _syncing_reversal() else index) as Action

## Removes the last action in the list, or does nothing if there are no actions.
func remove_back() -> void:
	remove_at(_actions.size() - 1)

## Removes the first action in the list, or does nothing if there are no actions.
func remove_front() -> void:
	remove_at(0)

## Removes the action at the given [param index] in the list, or does nothing if there are no actions.
func remove_at(index: int) -> void:
	if index < 0 or index >= _actions.size():
		return
	
	_actions.remove_at(_actions.size() - 1 - index if _syncing_reversal() else index)
	_dirty = true

## Removes all the actions between [param start] (inclusive) and [param end] (exclusive), i.e. in the range
## [code][start, end)[/code]. If [param start] equals [param end], nothing happens. If the range between
## [param start] and [param end] is greater than or equal to the length of the list, the entire list
## is cleared in an optimized manner.
func remove_range(start: int, end: int) -> void:
	if start == end:
		return
	
	# If the developer passed in start and end in the incorrect order, fix that
	if start > end:
		var temp := start
		start = end
		end = temp
	
	if start < 0:
		start = 0
	
	if end > _actions.size():
		end = _actions.size()
	
	if end - start >= _actions.size():
		clear_all()
	else:
		var syncing_reversal := _syncing_reversal()
		
		# REMARK: Processed in reverse order to avoid index invalidation
		# It is also faster since it's more likely there are fewer elements to move back an index
		for index: int in range(start if syncing_reversal else end - 1, end if syncing_reversal else start - 1, 1 if syncing_reversal else -1):
			remove_at(index)

## Clears the action list of any actions it may have.
func clear_all() -> void:
	_actions.clear()
	_reversed = false
	_dirty = true

## Clears only actions that are finished as indicated by [method Action.done].
func clear_finished() -> void:
	# REMARK: Processed in reverse order to avoid index invalidation
	# It is also faster since it's more likely there are fewer elements to move back an index
	for index: int in range(_actions.size() - 1, -1, -1):
		if _actions[index].done():
			_actions.remove_at(index)
	
	_dirty = true

## Makes the action list play in reverse order.
func reverse() -> void:
	var actions_to_restart := Bitset.new()
	var was_finished := is_empty_processable()
	
	# If the action list is still running during the reversal...
	if not was_finished:
		var temp_blocking_groups := Bitset.new()
		var list_index := 0
		
		for action: Action in _actions:
			# ...prevent actions we haven't reached yet from running
			if action.participating_groups.any_bits_from(temp_blocking_groups):
				action.finish()
				actions_to_restart.lower_bit(list_index)
				list_index += 1
				continue
			
			# ...fake a simulation for getting the blocking groups
			if not action.done():
				# Add the groups the action is blocking to the block list, if it has any
				action.blocking_groups.merge_onto(_blocked_groups)
			
			# ...mark which already-reached actions have already been previously completed
			actions_to_restart.set_bit(list_index, action.done())
			
			list_index += 1
	
	_actions.reverse()
	
	for action_index: int in _actions.size():
		var action := _actions[action_index]
		
		action.reverse()
		
		if actions_to_restart.get_bit(_actions.size() - 1 - action_index):
			action.restart()
	
	# If the action list was not running before the reversal, restart it
	if was_finished:
		restart()
	
	_reversed = not _reversed
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
			if action is IndefiniteAction:
				action.process(_get_adjusted_delta(), execution_index, list_index)
			else:
				action.process(action.get_absolute_time_remaining(), execution_index, list_index)
			
			# Force action to finish processing
			action.finish()
			
			# Mark this action as having been processed for this frame
			_processed_actions[action] = execution_index
			execution_index += 1
		
		list_index += 1
	
	_dirty = true

func _get_adjusted_delta() -> float:
	return _delta * delta_multiplier * (1.0 if ignore_engine_time_scale else Engine.time_scale)

func _syncing_reversal() -> bool:
	return _reversed and reversal_state_synchronized

func _prepare_fresh_action(action: Action) -> void:
	if _syncing_reversal():
		action.reverse()

func _prepare_fresh_list(list: Array[Action], autoreverse: bool) -> void:
	if _syncing_reversal():
		if autoreverse:
			list.reverse()
		
		for action: Action in list:
			action.reverse()
