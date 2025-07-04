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

class_name KnockbackEffector
extends Action

## Applies a knockback force to a [RigidBody2D], [RigidBody3D], or [PhysicalBone3D].
## 
## A knockback force is a very good feedback mechanism for demonstrating power or
## strength, as well as a pseudo-haptic technique for engagement. The [KnockbackEffector]
## is the tool to employ this idea on 2D and 3D rigid bodies.

var _force_vector := Vector3()
var _force_percent := 1.0
var _last_interpolation := 0.0

## Sets the [param force] to knock the [member Action.target] back with, as well as the
## strength of the rebounding force that attempts to set it back to its original position
## as a [param percentage] of the original force.
func with_force(force: Vector3, percentage := 1.0) -> KnockbackEffector:
	_force_vector = force
	_force_percent = percentage
	return self

## Knocks back the target.
func enter() -> void:
	if target is RigidBody2D:
		(target as RigidBody2D).apply_central_force(Vector2(_force_vector.x, _force_vector.y))
	elif target is PhysicalBone3D:
		(target as PhysicalBone3D).apply_central_impulse(_force_vector)
	else:
		(target as RigidBody3D).apply_central_force(_force_vector)

## Attempts to rebound the target to its original position.
func update() -> void:
	if target is RigidBody2D:
		var negated_force := -Vector2(_force_vector.x, _force_vector.y) * (get_interpolation() - _last_interpolation) * _force_percent
		(target as RigidBody2D).apply_central_force(negated_force)
	
	else:
		var negated_force := -_force_vector * (get_interpolation() - _last_interpolation) * _force_percent
		
		if target is PhysicalBone3D:
			(target as PhysicalBone3D).apply_central_force(negated_force)
		else:
			(target as RigidBody3D).apply_central_force(negated_force)
	
	_last_interpolation = get_interpolation()
