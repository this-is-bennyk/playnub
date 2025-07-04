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

class_name RigidBodyActor
extends ActionProcessor

## Manages the collection and processing of [ActionList]s in update loops, including
## custom integration loops for [RigidBody2D], [RigidBody3D], and [PhysicalBone3D].
## 
## Same as the [ActionProcessor], but accounts for manipulating logic in
## [method RigidBody2D._integrate_forces], [method RigidBody3D._integrate_forces],
## and [method PhysicalBone3D._integrate_forces].

var _state2D: PhysicsDirectBodyState2D = null
var _state3D: PhysicsDirectBodyState3D = null

## Returns the current [PhysicsDirectBodyState2D] of the underlying [RigidBody2D].
func get_state_2D() -> PhysicsDirectBodyState2D:
	return _state2D

## Returns the current [PhysicsDirectBodyState3D] of the underlying [RigidBody3D]
## or [PhysicalBone3D].
func get_state_3D() -> PhysicsDirectBodyState3D:
	return _state3D

## See [method ModularityInterface.get_strong_uniqueness_mode].
func get_strong_uniqueness_mode(super_level: int) -> UniquenessMode:
	if super_level == 0:
		return UniquenessMode.REPLACE_ONLY
	return super(super_level - 1)

## See [method ModularityInterface.is_strongly_unique].
func is_strongly_unique(super_level: int) -> bool:
	if super_level == 0:
		return false
	return super(super_level - 1)

func _integrate_forces(state: Variant) -> void:
	if (not _update_loop_flags.has(_integrate_forces)) or _update_loop_flags[_integrate_forces].num_raised() <= 0:
		return
	
	var delta := 0.0
	
	if base is Node2D:
		_state2D = state
		delta = _state2D.step
	else:
		_state3D = state
		delta = _state3D.step
	
	_process_lists(delta, _update_loop_flags[_integrate_forces])
