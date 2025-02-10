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
class_name DrivenHarmonicOscillator
extends Resource

## Derives continuous, dampened oscillating values for positional and rotational motion.
## 
## TODO
## 
## @tutorial(t3ssel8r: Giving Personality to Procedural Animations using Math): https://www.youtube.com/watch?v=KPoeNZZ6H4s

## How quickly the system oscillates. A value of [code]0[/code] means no oscillation at all.
## Larger values mean quicker oscillations.
@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:Hz")
var frequency := 1.0 # f

## How quickly the system transitions from oscillating to settling at the target value.[br]
## A value of [code]0[/code] represents no damping, meaning the system will never stop
## oscillating.[br]
## Values in the range [code](0, 1)[/code] represent an underdamped system,
## meaning the system will oscillate with some strength at first, then settle sometime later.[br]
## A value of [code]1[/code] represents critical damping, meaning the system does not oscillate,
## but instead smoothly settles at the target at the fastest possible speed.
## (Example: Unity uses critical damping in their SmoothDamp function.)[br]
## Values greater than [code]1[/code] represent overdamping, meaning the system will settle
## at the target slower.
@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater")
var damping_coefficient := 1.0 # z

## How the system reacts to a change to the target value.[br]
## A value of [code]0[/code] means the system will smoothly transition to the new target value.[br]
## A value of [code]1[/code] means the system will immediately begin transitioning
## towards the target value.[br]
## Values greater than [code]1[/code] means the system will overshoot the target value at first.
## (Example: a value of [code]2[/code] looks like a mechanical motion.)[br]
## Values less than [code]0[/code] means the system will anticipate the motion towards
## the target value at first.
@export_range(-1.0, 1.0, 0.0001, "hide_slider", "or_greater", "or_less")
var initial_response := 0.0 # r

## If enabled, makes the resulting motion more accurate (i.e. less jitter and less of a chance of 
## breaking permanently, especially when the motion is fast), with the tradeoff of being potentially
## more expensive to calculate.
@export
var accurate_motion_tracking := true

## Displays approximately what the oscillation curve looks like in real time.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var result_curve: Curve:
	get:
		var curve := Curve.new()
		
		curve.clear_points()
		curve.min_value = 0.0
		curve.max_value = 1.0
		
		start(0.0)
		
		var x := 0.0
		var idx_array: Array[int] = []
		idx_array.assign(range(11))
		
		for i: int in idx_array:
			var y := update(1.0 / 20.0, 1.0)
			
			curve.min_value = minf(curve.min_value, y)
			curve.max_value = maxf(curve.max_value, y)
			curve.add_point(Vector2(x, y))
			
			x += 1.0 / 20.0
		
		for i: int in idx_array:
			var y := update(1.0 / 20.0, 1.0)
			
			curve.min_value = minf(curve.min_value, y)
			curve.max_value = maxf(curve.max_value, y)
			curve.add_point(Vector2(x, y))
			
			x += 1.0 / 20.0
		
		return curve

var _system_velocity_factor := 0.0 # k1
var _system_acceleration_factor := 0.0 # k2
var _target_velocity_factor := 0.0 # k3

var _angular_frequency := 0.0 # _w
var _laplance_pole_range := 0.0 # _d

var _prev_target_pos: Variant = null # xp
var _system_position: Variant = null # y
var _system_velocity: Variant = null # yd

## Sets the values of the constants used in calculating the motion of the system.
func initialize_constants() -> void:
	_angular_frequency = TAU * frequency
	_laplance_pole_range = _angular_frequency * sqrt(absf(damping_coefficient * damping_coefficient - 1.0))
	
	_system_velocity_factor = damping_coefficient / (PI * frequency)
	_system_acceleration_factor = 1.0 / (_angular_frequency * _angular_frequency)
	_target_velocity_factor = initial_response * damping_coefficient / _angular_frequency

## Sets the initial state of the oscillator before calculating the motion of the system.
func start(start_position: Variant) -> void:
	initialize_constants()
	
	assert(
		start_position is float
		or start_position is Vector2
		or start_position is Vector3
		or start_position is Vector4
		, "Cannot perform physics operations on this value!"
	)
	
	_prev_target_pos = start_position
	_system_position = start_position
	
	if start_position is Vector2:
		_system_velocity = Vector2()
	elif start_position is Vector3:
		_system_velocity = Vector3()
	elif start_position is Vector4:
		_system_velocity = Vector4()
	else:
		_system_velocity = 0.0

## Calculates the motion of the system going towards the [param target_position] that is
## (optionally) moving at [param target_velocity] over [param delta] seconds.
## If [param target_velocity] is not provided, it is calculated based on the previous
## position of the target.
func update(delta: float, target_position: Variant, target_velocity: Variant = null) -> Variant:
	if target_velocity == null:
		target_velocity = (target_position - _prev_target_pos) / delta
		_prev_target_pos = target_position
	
	var stable_sys_vel_factor := 0.0
	var stable_sys_accel_factor := 0.0
	
	if (not accurate_motion_tracking) or (_angular_frequency * delta < damping_coefficient):
		stable_sys_vel_factor = _system_velocity_factor
		# Clamp acceleration for stability without jitter
		stable_sys_accel_factor = maxf(_system_acceleration_factor, maxf(delta * delta / 2 + delta * _system_velocity_factor / 2.0, delta * _system_velocity_factor))
	else:
		# Use pole matching to get accurate values when the system is very fast
		var z_domain_pole := exp(-damping_coefficient * _angular_frequency * delta)
		var trace_char_poly := 2.0 * z_domain_pole * (cos(_laplance_pole_range * delta) if damping_coefficient <= 1.0 else cosh(_laplance_pole_range * delta))
		var det_char_poly := z_domain_pole * z_domain_pole
		var system_motion_factor := delta / (1.0 + det_char_poly - trace_char_poly)
		
		stable_sys_vel_factor = (1.0 - det_char_poly) * system_motion_factor
		stable_sys_accel_factor = system_motion_factor * delta
	
	_system_position += _system_velocity * delta
	_system_velocity += (target_position + _target_velocity_factor * target_velocity - _system_position - stable_sys_vel_factor * _system_velocity) / stable_sys_accel_factor * delta
	
	return _system_position
