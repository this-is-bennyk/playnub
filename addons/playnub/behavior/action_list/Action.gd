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

class_name Action
extends RefCounted

## Performs logic grouped as a singular unit.
##
## TODO

## Time in seconds this action lasts.
var duration := 0.0:
	set(value):
		duration = maxf(0.0, value)

## Time in seconds before this action starts.
var delay := 0.0:
	set(value):
		delay = maxf(0.0, value)

## The object to enact logic on.
var target = null

## The set of groups this action belongs to.
var participating_groups := Bitset.new([0])
## The set of groups this action is blocking from executing before it is finished.
var blocking_groups := Bitset.new()

# The current delta time elasped.
var _dt := 0.0
# The amount of time that has elapsed. Starts at 0, ends at get_total_processing_time().
var _time_passed := 0.0
# The zero-based index of when this action is being executed relative to others
# in the parent action list, i.e. this is the nth action to be executed.
var _execution_index := 0
# The zero-based index of where this action is in its parent action list, i.e.
# this is the nth action in the list.
var _list_index := 0

# Whether this action has already been entered.
var _entered := false
# Whether this action has already been finished.
var _done := false
# Whether this action counts down to 0.0 or up to get_total_processing_time().
var _reversed := false

## Sets the object to act upon.
func targets(_target) -> Action:
	target = _target
	return self

## Sets the duration of this action.
func lasts(_duration_sec: float = 0.0) -> Action:
	duration = _duration_sec
	return self

## Sets the delay of this action.
func after(_delay_sec: float = 0.0) -> Action:
	delay = _delay_sec
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

## Performs logic and increases the amount of time taken by this action by
## [param delta] seconds. Override [method enter], [method update], and/or [method exit]
## to customize the behavior of this action.
func process(delta: float, execution_index: int, list_index: int) -> void:
	if done() or (target is Object and (not target or not is_instance_valid(target))):
		_done = true
		return
	
	_dt = delta
	_time_passed += get_delta_time()
	_execution_index = execution_index
	_list_index = list_index
	
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
		(_reversed and _time_passed <= 0.0) or
		(not _reversed and _time_passed >= get_total_processing_time()))

## Whether this action is being delayed.
func delayed() -> bool:
	return _time_passed < delay

## Prematurely finishes the action.
func finish() -> void:
	_done = true

## Makes the action resets progress to its beginning,
## which is [method get_total_processing_time] if reversed and [code]0.0[/code] if not.
func restart() -> void:
	_entered = false
	_done = false
	
	if _reversed:
		_time_passed = get_total_processing_time()
	else:
		_time_passed = 0.0

## Toggles the direction of time that this action is processed in.
func reverse() -> void:
	_reversed = not _reversed

## Returns whether this action is being processed in reverse.
func is_reversed() -> bool:
	return _reversed

## Returns how many seconds have passed since the action was entered.
func get_relative_time_passed() -> float:
	var result := clampf(_time_passed - delay, 0.0, duration)
	
	if is_reversed():
		result = duration - result
	
	return result

## Returns how many seconds are left to process relative to the [member duration].
func get_relative_time_remaining() -> float:
	var result := clampf(duration - get_relative_time_passed(), 0.0, duration)
	
	if is_reversed():
		result = duration - result
	
	return result

## Returns how many seconds have passed since the action was first processed.
func get_absolute_time_passed() -> float:
	var result := clampf(_time_passed, 0.0, get_total_processing_time())
	
	if is_reversed():
		result = get_total_processing_time() - result
	
	return result

## Returns how many seconds are left to process relative to the total time,
## as seen in [method get_total_processing_time].
func get_absolute_time_remaining() -> float:
	if is_reversed():
		return clampf(_time_passed, 0.0, get_total_processing_time())
	return clampf(get_total_processing_time() - get_absolute_time_passed(), 0.0, get_total_processing_time())

## Returns the total time this action is processed for, in seconds.
func get_total_processing_time() -> float:
	return duration + delay

## Returns how far into the action we are as a percent of the [member duration] that's been completed.
func get_interpolation() -> float:
	if duration == 0.0:
		return 0.0
	return clampf(inverse_lerp(0.0, duration, _time_passed - delay), 0.0, 1.0)

## Returns the delta time for the current frame.
func get_delta_time() -> float:
	return _dt * (-1.0 if _reversed else 1.0)

## Returns the zero-based index of when this action is being executed relative to others
## in the parent action list, i.e. this is the nth action to be executed.[br]
## [b]NOTE[/b]: This is affected by reversal and blocking.
func get_execution_index() -> int:
	return _execution_index

## Returns the zero-based index of when this action is located relative to others
## in the parent action list, i.e. this is the nth action in the list.[br]
## [b]NOTE[/b]: This is affected by reversal, but NOT by blocking.
func get_list_index() -> int:
	return _list_index
