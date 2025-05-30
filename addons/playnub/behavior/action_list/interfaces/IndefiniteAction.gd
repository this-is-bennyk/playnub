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
## 
## Notoriously, systems like physics and particles, i.e. systems or behaviors with no defined
## end, are difficult to split into separate pieces, especially ones that can be manipulated
## with operations like event re-arrangement and reversal. Since the [IndefiniteAction]
## is part of the action list system, this capability is built-in, allowing logic
## that would normally be difficult to adjust to be much simpler.[br][br]
## [b]NOTE[/b]: Like many things with computers, this action is not truly indefinite.
## It will wrap around in about [b]292 billion years[/b].

# REMARK: The reason for this is because the below numbers represent seconds with a whole part
# (64-bit integer by default) and a decimal part (0-1, 64-bit floating point). With the integer
# increasing once per second (unmodified), it'll wrap around in LLONG_MAX seconds, which is greater
# than what can be calculated by looking up "9223372036854775807 seconds to years."
# [Default search engine] rounds up the number to 9223372036854776000 due to floating-point error,
# giving us ~292.5B years. Your mileage may vary in single-precision mode, but not by any meaningful amount.
# TL;DR: Don't sweat it. :D

# Tracks the position in time, in seconds, this indefinite action has been processed at.
var _timeline_position_whole := 0
var _timeline_position_fraction := 0.0

# Tracks the farthest position in time, in seconds, this indefinite action has been processed
# when going forward. Think of it like the end of the timeline, and moves forward when a keyframe is added
# (or in this case, when the position has gone beyond the end of the timeline).
var _timeline_end_whole := 0
var _timeline_end_fraction := 0.0

## See [method Action.lasts]. Overriden to not affect [member Action.duration].
func lasts(_duration_sec: float = 0.0) -> Action:
	return self

## Use [method indefinite_enter] instead.
func enter() -> void:
	# Only reset duration if starting from the beginning of forward progress
	if not is_reversed():
		duration = 0.0
		
		_timeline_position_whole = 0
		_timeline_position_fraction = 0.0
		
		_timeline_end_whole = 0
		_timeline_end_fraction = 0.0
	
	indefinite_enter()

## Use [method indefinite_update] instead.
func update() -> void:
	_instrument_duration()
	indefinite_update()

## Use [method indefinite_exit] instead.
func exit() -> void:
	indefinite_exit()

## Performs logic upon this indefinite action being encountered for the first time.
## Override this method to customize the behavior of the action.
## Replaces the regular [method enter] for actions deriving from this interface.
func indefinite_enter() -> void:
	pass

## Performs continuous logic for an indefinite amount of time.
## Override this method to customize the behavior of the action.
## Replaces the regular [method update] for actions deriving from this interface.
func indefinite_update() -> void:
	pass

## Performs logic upon this indefinite action being encountered for the last time.
## Override this method to customize the behavior of the action.
## Replaces the regular [method exit] for actions deriving from this interface.
func indefinite_exit() -> void:
	pass

## See [method Action.done].
func done() -> bool:
	return _done or (_reversed and _time_passed <= 0.0)

func _instrument_duration() -> void:
	_timeline_position_fraction += get_delta_time()
	
	if is_reversed():
		if _timeline_position_fraction <= 0.0:
			_timeline_position_whole = maxi(_timeline_position_whole - fmod(_timeline_position_fraction, 1.0), 0)
			_timeline_position_fraction = wrapf(_timeline_position_fraction, 0.0, 1.0)
	else:
		if _timeline_position_fraction >= 1.0:
			_timeline_position_whole = maxi(_timeline_position_whole + fmod(_timeline_position_fraction, 1.0), 0)
			_timeline_position_fraction = wrapf(_timeline_position_fraction, 0.0, 1.0)
	
	if \
		_timeline_position_whole > _timeline_end_whole \
		or \
		(
			_timeline_position_whole == _timeline_end_whole \
			and _timeline_position_fraction > _timeline_end_fraction
		) \
	:
		_timeline_end_whole = _timeline_position_whole
		_timeline_end_fraction = _timeline_position_fraction
	
	# By manually producing higher-accuracy FPs and leaving addition at the last possible moment,
	# the recorded duration should hopefully not drift too much from the expected amount of
	# simulation time (in reasonable scenarios)
	duration = float(_timeline_end_whole) + _timeline_end_fraction
