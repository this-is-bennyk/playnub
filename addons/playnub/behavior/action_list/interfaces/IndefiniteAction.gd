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

@icon("uid://b3eltima01jdp")
class_name IndefiniteAction
extends Action

## An action that lasts for a user-defined (i.e. indeterminate) amount of time.
## 
## Notoriously, systems like physics and particles, i.e. systems or behaviors with no defined
## end, are difficult to split into separate pieces, especially ones that can be manipulated
## with operations like event re-arrangement and reversal. Since the [IndefiniteAction]
## is part of the action list system, this capability is built-in, allowing logic
## that would normally be difficult to manipulate and reuse to be much simpler.

# Tracks the farthest position in time, in seconds, this indefinite action has been processed
# when going forward. Think of it like the end of the timeline, and moves forward when a keyframe is added
# (or in this case, when the position has gone beyond the end of the timeline).
var _timeline_end := Playhead.new()

## Overrides [method Action.lasts] to not affect [member Action.duration].
func lasts(_duration_sec: Playhead = null) -> Action:
	return self

## Use [method indefinite_enter] instead.
func enter() -> void:
	# Only reset duration if starting from the beginning of forward progress
	if not is_reversed():
		duration.reset()
		_timeline_end.reset()
	
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

## Overrides [method Action.done] to only be done if the user says so or if the action
## has been reversed and has reached the beginning again.
func done() -> bool:
	return _done or (_reversed and _time_passed.is_zero())

func _instrument_duration() -> void:
	_timeline_end.max(_time_passed, _timeline_end)
	duration.assign(_timeline_end)
