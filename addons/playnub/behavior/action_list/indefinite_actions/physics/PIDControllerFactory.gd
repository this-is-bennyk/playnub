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
class_name PIDControllerFactory
extends Resource

## Derives continuous, dampened oscillating values for positional and rotational motion.
## 
## Organic and mechanical movement with continous variables is tough, even with [ControlCurve]s.
## This object provides a way to interpolate continuous data towards a target point (from 1D to 4D)
## with parameters for oscillation and dampening that can make procedural movement far easier.
## The PID controller comes from traditional engineering control theory and control systems, but instead
## of taking error out of a system, this system adds it in deliberately for game feel (source: @notanimposter's
## comment in the tutorial).
## 
## @tutorial(t3ssel8r: Giving Personality to Procedural Animations using Math): https://www.youtube.com/watch?v=KPoeNZZ6H4s

## How quickly the system oscillates. A value of [code]0[/code] means no oscillation at all.
## Larger values mean quicker oscillations.
@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:Hz")
var frequency := 1.0: # f
	set(value):
		frequency = value
		emit_changed()

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
var damping_coefficient := 1.0: # z
	set(value):
		damping_coefficient = value
		emit_changed()

## How the system reacts to a change to the target value.[br]
## A value of [code]0[/code] means the system will smoothly transition to the new target value.[br]
## A value of [code]1[/code] means the system will immediately begin transitioning
## towards the target value.[br]
## Values greater than [code]1[/code] means the system will overshoot the target value at first.
## (Example: a value of [code]2[/code] looks like a mechanical motion.)[br]
## Values less than [code]0[/code] means the system will anticipate the motion towards
## the target value at first.
@export_range(-1.0, 1.0, 0.0001, "hide_slider", "or_greater", "or_less")
var initial_response := 0.0: # r
	set(value):
		initial_response = value
		emit_changed()

## If enabled, makes the resulting motion more accurate (i.e. less jitter and less of a chance of 
## breaking permanently, especially when the motion is fast), with the tradeoff of being potentially
## more expensive to calculate.
@export
var accurate_motion_tracking := true

## Editor-only property that displays approximately what the oscillation curve looks like in real time.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var result_curve: Curve:
	get:
		if not Engine.is_editor_hint():
			return null
		
		const FAKE_DELTA := 1.0 / 20.0
		
		var curve := Curve.new()
		
		curve.clear_points()
		curve.min_value = 0.0
		curve.max_value = 1.0
		
		var controller := create().starts_at(Box.new(0.0)).follows_position(Box.new(1.0))
		controller.targets(Box.new(0.0))
		
		var x := 0.0
		var idx_array: Array[int] = []
		idx_array.assign(range(11))
		
		for i: int in idx_array:
			controller.process(FAKE_DELTA, 0, 0)
			var y := controller.target.data as float
			
			curve.min_value = minf(curve.min_value, y)
			curve.max_value = maxf(curve.max_value, y)
			curve.add_point(Vector2(x, y))
			
			x += 1.0 / 20.0
		
		for i: int in idx_array:
			controller.process(FAKE_DELTA, 0, 0)
			var y := controller.target.data as float
			
			curve.min_value = minf(curve.min_value, y)
			curve.max_value = maxf(curve.max_value, y)
			curve.add_point(Vector2(x, y))
			
			x += 1.0 / 20.0
		
		return curve

func create() -> PIDController:
	return PIDController.new().from_factory(self)
