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

@tool
@icon("uid://cikyi3pb8dm5c")
class_name PIDController
extends IndefiniteAction

## Derives continuous, dampened oscillating values for positional and rotational motion.
## 
## Organic and mechanical movement with continous variables is tough, even with [ControlCurve]s.
## This action provides a way to interpolate continuous data towards a target point (from 1D to 4D)
## with parameters for oscillation and dampening that can make procedural movement far easier.
## The PID controller comes from traditional engineering control theory and control systems, but instead
## of taking error out of a system, this system adds it in deliberately for game feel (source: @notanimposter's
## comment in the tutorial).
## 
## @tutorial(t3ssel8r: Giving Personality to Procedural Animations using Math): https://www.youtube.com/watch?v=KPoeNZZ6H4s

var _factory: PIDControllerFactory = null

var _start_pos: Box = null
var _target_pos: Box = null
var _target_vel: Box = null

var _system_velocity_factor := 0.0 # k1
var _system_acceleration_factor := 0.0 # k2
var _target_velocity_factor := 0.0 # k3

var _angular_frequency := 0.0 # _w
var _laplance_pole_range := 0.0 # _d

var _prev_target_pos: Variant = null # xp
var _system_position: Variant = null # y
var _system_velocity: Variant = null # yd

## Sets the [PIDControllerFactory] to retrieve the settings of the motion that
## the PID controller generates from, via [param factory].
func from_factory(factory: PIDControllerFactory) -> PIDController:
	_factory = factory
	_initialize_constants()
	_factory.changed.connect(_initialize_constants)
	return self

## Sets the initial state of the oscillator before calculating the motion of the system.
func starts_at(start_position: Box) -> PIDController:
	_start_pos = start_position
	return self

## Sets the target value to follow as given by [param target_position].[br]
## [param target_position] [b]must[/b] be a [float], [Vector2], [Vector3], or [Vector4].
func follows_position(target_position: Box) -> PIDController:
	_target_pos = target_position
	return self

## Sets the velocity of target value to follow as given by [param target_velocity].[br]
## [param target_velocity] [b]must[/b] be a [float], [Vector2], [Vector3], or [Vector4].
func follows_velocity(target_velocity: Box = null) -> PIDController:
	_target_vel = target_velocity
	return self

func indefinite_enter() -> void:
	assert(
		   (_start_pos.data is float and _target_pos.data is float)
		or (_start_pos.data is Vector2 and _target_pos.data is Vector2)
		or (_start_pos.data is Vector3 and _target_pos.data is Vector3)
		or (_start_pos.data is Vector4 and _target_pos.data is Vector4)
		, "Cannot perform physics operations with either start or target position (or both)!"
	)
	
	if _target_vel and _target_vel.data != null:
		assert(
			   _target_vel.data is float
			or _target_vel.data is Vector2
			or _target_vel.data is Vector3
			or _target_vel.data is Vector4
			, "Cannot perform physics operations with target velocity!"
		)
	
	_prev_target_pos = _start_pos.data
	_system_position = _start_pos.data
	
	if _start_pos.data is Vector2:
		_system_velocity = Vector2()
	elif _start_pos.data is Vector3:
		_system_velocity = Vector3()
	elif _start_pos.data is Vector4:
		_system_velocity = Vector4()
	else:
		_system_velocity = 0.0

## Calculates the motion of the system going towards the [param target_position] that is
## (optionally) moving at [param target_velocity] over [param delta] seconds.
## If [param target_velocity] is not provided, it is calculated based on the previous
## position of the target.
func indefinite_update() -> void:
	var delta := get_delta_time()
	var target_velocity: Variant = null
	
	if _target_vel and _target_vel.data != null:
		target_velocity = _target_vel.data
	
	else:
		if delta == 0.0:
			target_velocity = target.data * 0.0
		else:
			target_velocity = (_target_pos.data - _prev_target_pos) / delta
		
		_prev_target_pos = _target_pos.data
	
	var stable_sys_vel_factor := 0.0
	var stable_sys_accel_factor := 0.0
	
	if (not _factory.accurate_motion_tracking) or (_angular_frequency * delta < _factory.damping_coefficient):
		stable_sys_vel_factor = _system_velocity_factor
		# Clamp acceleration for stability without jitter
		stable_sys_accel_factor = maxf(_system_acceleration_factor, maxf(delta * delta / 2 + delta * _system_velocity_factor / 2.0, delta * _system_velocity_factor))
	else:
		# Use pole matching to get accurate values when the system is very fast
		var z_domain_pole := exp(-_factory.damping_coefficient * _angular_frequency * delta)
		var trace_char_poly := 2.0 * z_domain_pole * (cos(_laplance_pole_range * delta) if _factory.damping_coefficient <= 1.0 else cosh(_laplance_pole_range * delta))
		var det_char_poly := z_domain_pole * z_domain_pole
		var system_motion_factor := delta / (1.0 + det_char_poly - trace_char_poly)
		
		stable_sys_vel_factor = (1.0 - det_char_poly) * system_motion_factor
		stable_sys_accel_factor = system_motion_factor * delta
	
	_system_position += _system_velocity * delta
	_system_velocity += (_target_pos.data + _target_velocity_factor * target_velocity - _system_position - stable_sys_vel_factor * _system_velocity) / stable_sys_accel_factor * delta
	
	target.data = _system_position

func _initialize_constants() -> void:
	_angular_frequency = TAU * _factory.frequency
	_laplance_pole_range = _angular_frequency * sqrt(absf(_factory.damping_coefficient * _factory.damping_coefficient - 1.0))
	
	_system_velocity_factor = _factory.damping_coefficient / (PI * _factory.frequency)
	_system_acceleration_factor = 1.0 / (_angular_frequency * _angular_frequency)
	_target_velocity_factor = _factory.initial_response * _factory.damping_coefficient / _angular_frequency
