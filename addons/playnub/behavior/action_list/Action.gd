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

@icon("uid://p2wndulkd6hm")
class_name Action
extends RefCounted

## Performs logic grouped as a singular unit.
##
## Grouping logic in software development, let alone game development, is a
## non-trivial task. A lot of logic is also shared between different elements
## that otherwise are nothing alike. The [Action] allows for code to be separated
## into individual tasks for simplicity, reusability, and flexibility in game logic,
## UI logic, and more.

## Time in seconds this action lasts.
var duration := Playhead.new()

## Time in seconds before this action starts.
var delay := Playhead.new()

## The object to enact logic on.
var target = null

## The set of groups this action belongs to.
var participating_groups := Bitset.new([0])
## The set of groups this action is blocking from executing before it is finished.
var blocking_groups := Bitset.new()

var _dt := 0.0
# The amount of time that has elapsed. Starts at 0, ends at get_total_processing_time().
var _time_passed := Playhead.new()
# The zero-based index of when this action is being executed relative to others
# in the parent action list, i.e. this is the nth action to be executed.
var _execution_index := 0
# The zero-based index of where this action is in its parent action list, i.e.
# this is the nth action in the list.
var _list_index := 0

var _entered := false
var _done := false
var _breakpoint_before_logic := false
var _breakpoint_condition := Callable()
# Whether this action counts down to 0.0 or up to get_total_processing_time().
var _reversed := false

# Various stats about the action, recorded in cached playheads for efficiency.
# REMARK: Why store these in objects? For accurate time-tracking and automatic
# limitations on the internal numbers to be positive only, which is useful when
# imagining actions as keyframe and action lists as timelines, or for certain
# actions like any IndefiniteAction.
var _relative_time_passed := Playhead.new()
var _relative_time_remaining := Playhead.new()
var _absolute_time_passed := Playhead.new()
var _absolute_time_remaining := Playhead.new()
var _total_processing_time := Playhead.new()
var _interpolation_time_passed := Playhead.new()

## Sets the object to act upon.
func targets(_target) -> Action:
	target = _target
	return self

## Sets the duration of this action in seconds.
func lasts(_duration_sec: Playhead = null) -> Action:
	duration.assign(_duration_sec)
	return self

## Sets the delay of this action in seconds.
func after(_delay_sec: Playhead = null) -> Action:
	delay.assign(_delay_sec)
	return self

## Sets the groups that this action belongs to.[br]
## [b]NOTE[/b]: All actions belong to the [b]0th group[/b], so use indices in the range [code][1, ∞)[/code].
func in_groups(_groups: PackedInt64Array = PackedInt64Array()) -> Action:
	if not _groups.has(0):
		var groups_copy := _groups.duplicate()
		
		groups_copy.append(0)
		
		participating_groups = Bitset.new(groups_copy)
		return self
	
	participating_groups = Bitset.new(_groups)
	return self

## Blocks the groups that this action belongs to from executing.
## Pass [code]true[/code] to [param override] to override the groups being blocked
## instead of adding to them.
func blocks_own_groups(override: bool = false) -> Action:
	# If we're overriding the groups to block, erase the previously blocking groups
	if override:
		blocking_groups.clear()
	
	participating_groups.merge_onto(blocking_groups)
	
	return self

## Blocks an arbitrary collection of groups from executing.
## Each index in [param indices] refers to the bit at the index.
## Pass [code]true[/code] to [param override] to override the groups being blocked
## instead of adding to them.
func blocks(indices: PackedInt64Array, override: bool = false) -> Action:
	# If we're overriding the groups to block, erase the previously blocking groups
	if override:
		blocking_groups.clear()
	
	var blocking_bits := Bitset.new(indices)
	
	blocking_bits.merge_onto(blocking_groups)
	
	return self

## Sets whether to hit a breakpoint before executing the logic of this action as
## determined by [param breaks]. If [param condition] is not an empty [code]Callable()[/code],
## the breakpoint will only trigger when the [param condition] returns [code]true[/code].
## Useful for debugging specific actions.[br][br]
## [b]NOTE[/b]: If [param condition] is not an empty [code]Callable()[/code], it [b]must[/b]
## take no arguments (or have its parameters binded so that it can be called without passing
## arguments) and return a [bool] (example signature: [code]func() -> bool[/code]).
func debug_breaks(breaks := true, condition := Callable()) -> Action:
	_breakpoint_before_logic = breaks
	_breakpoint_condition = condition
	return self

## Performs logic and increases the amount of time taken by this action by
## [param delta] seconds. Override [method enter], [method update], and/or [method exit]
## to customize the behavior of this action.
func process(delta: float, execution_index: int, list_index: int) -> void:
	if done() or (target is Object and (not target or not is_instance_valid(target))):
		_done = true
		return
	
	_dt = delta
	_time_passed.move(get_delta_time())
	_execution_index = execution_index
	_list_index = list_index
	
	if _breakpoint_before_logic and \
	   ((not _breakpoint_condition.is_valid()) or _breakpoint_condition.call() as bool):
		breakpoint
	
	if not delayed():
		if not entered():
			if is_reversed():
				exit()
			else:
				enter()
			
			_entered = true
		
		update()
		
		if done():
			_done = true
			
			if is_reversed():
				enter()
			else:
				exit()

## Performs logic upon this action being encountered for the first time.
## Override this method to customize the behavior of the action.
func enter() -> void:
	pass

## Performs continuous logic.
## Override this method to customize the behavior of the action.
func update() -> void:
	pass

## Performs logic upon this action being encountered for the last time.
## Override this method to customize the behavior of the action.
func exit() -> void:
	pass

## Whether this function has already been encountered.
func entered() -> bool:
	return _entered

## Whether the action has finished execution.
func done() -> bool:
	return (_done or
		(_reversed and _time_passed.is_zero()) or
		(not _reversed and _time_passed.greater_than_or_equals(get_total_processing_time())))

## Whether this action is being delayed.
func delayed() -> bool:
	return _time_passed.less_than(delay)

## Prematurely finishes the action.
func finish() -> void:
	_done = true

## Makes the action resets progress to its beginning,
## which is [method get_total_processing_time] if reversed and [code]0.0[/code] if not.
func restart() -> void:
	_entered = false
	_done = false
	
	if _reversed:
		_time_passed.assign(get_total_processing_time())
	else:
		_time_passed.reset()

## Toggles the direction of time that this action is processed in.
func reverse() -> void:
	_reversed = not _reversed

## Returns whether this action is being processed in reverse.
func is_reversed() -> bool:
	return _reversed

## Returns how many seconds have passed since the action was entered.
func get_relative_time_passed() -> Playhead:
	_time_passed.sub(delay, _relative_time_passed).clamp(Playhead.zero(), duration, _relative_time_passed)
	
	if is_reversed():
		duration.sub(_relative_time_passed, _relative_time_passed)
	
	return _relative_time_passed

## Returns how many seconds are left to process relative to the [member duration].
func get_relative_time_remaining() -> Playhead:
	duration.sub(get_relative_time_passed(), _relative_time_remaining).clamp(Playhead.zero(), duration, _relative_time_remaining)
	
	if is_reversed():
		duration.sub(_relative_time_remaining, _relative_time_remaining)
	
	return _relative_time_remaining

## Returns how many seconds have passed since the action was first processed.
func get_absolute_time_passed() -> Playhead:
	_time_passed.clamp(Playhead.zero(), get_total_processing_time(), _absolute_time_passed)
	
	if is_reversed():
		_absolute_time_passed.sub(get_total_processing_time(), _absolute_time_passed)
	
	return _absolute_time_passed

## Returns how many seconds are left to process relative to the total time,
## as seen in [method get_total_processing_time].
func get_absolute_time_remaining() -> Playhead:
	if is_reversed():
		_time_passed.clamp(Playhead.zero(), get_total_processing_time(), _absolute_time_remaining)
	else:
		get_total_processing_time().sub(get_absolute_time_passed(), _absolute_time_remaining).clamp(Playhead.zero(), get_total_processing_time(), _absolute_time_remaining)
	
	return _absolute_time_remaining

## Returns the total time this action is processed for, in seconds.
func get_total_processing_time() -> Playhead:
	duration.add(delay, _total_processing_time)
	return _total_processing_time

## Returns how far into the action we are as a percent of the [member duration] that's been completed.
func get_interpolation() -> float:
	if duration.is_zero():
		# Since a duration of zero means we're instantly at the end of the action,
		# it is appropriate to indicate as much via the interpolation value
		return 1.0
	
	_time_passed.sub(delay, _interpolation_time_passed)
	
	return clampf(inverse_lerp(0.0, duration.to_float(), _interpolation_time_passed.to_float()), 0.0, 1.0)

## Returns the delta time for the current frame.
func get_delta_time() -> float:
	return _dt * (-1.0 if _reversed else 1.0)

## Returns the zero-based index of when this action is being executed relative to others
## in the parent action list, i.e. this is the n-th action to be executed.[br]
## [b]NOTE[/b]: This is affected by reversal and blocking.
func get_execution_index() -> int:
	return _execution_index

## Returns the zero-based index of when this action is located relative to others
## in the parent action list, i.e. this is the n-th action in the list.[br]
## [b]NOTE[/b]: This is affected by reversal, but NOT by blocking.
func get_list_index() -> int:
	return _list_index
