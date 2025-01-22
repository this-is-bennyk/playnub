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

class_name ControlCurve
extends Resource

## Creates a curve for interpolating data.
##
## Unlike traditional software, almost all, if not all, data and events in a game
## benefit from progressing or changing in an arc-like manner, with the design patterns
## setup-hook-development-turn-resolution arcs and attack-(delay-)sustain-release for short ones.
## The [ControlCurve] allows one to define these arcs for any kind of continuous data.[br]
## (Technically, a control curve is three curves: an attack curve, a sustain line,
## and a release curve. However, this is the closest terminology that describes the
## function of this resource.)

## The methods of interpolation between any two values.
enum InterpolationType
{
	## Interpolates between a straight line from the start to the end.
	  LINEAR
	## Interpolates between a curve from the start to the end, defined by prestart and postend values.
	, CUBIC
	## Interpolates between a curve from the start to the end within a given time, defined by prestart and postend values and times.
	, CUBIC_IN_TIME
	## Interpolates between a curve defined by the start, the end, and two control points.
	, BEZIER
}

## The behaviors of interpolation between any two values.
enum EasingType
{
	## Uses the easing curves defined by the [Tween] class.
	  BUILT_IN
	## Uses a [Curve] drawn by the designer.
	, CURVE
	## Uses a math equation via an [InterpolationEquation] defined by the designer.
	, EQUATION
	## Uses the [method @GlobalScope.ease] function.
	, EASE_FUNC
}

@export_group("Interpolation")

## Defines what method of interpolation to use.
@export
var interpolation_type: InterpolationType = InterpolationType.LINEAR

## The starting value of the interpolation.
@export
var start: Box = null

## The ending value of the interpolation.
@export
var end: Box = null

@export_subgroup("Cubic Interpolation (in Time)")

## The value before the start, curving the beginning of the interpolation.
@export
var prestart: Box = null

## The time value before the beginning time of the interpolation.
@export
var prestart_time: float = 0.0

## The value after the end, curving the end of the interpolation.
@export
var postend: Box = null

## The time value after the end time of the interpolation.
@export
var postend_time: float = 0.0

## The end time of the interpolation.
@export
var end_time: float = 0.0

@export_subgroup("Bézier Interpolation")

## The first handle of the interpolation.
@export
var control_1: Box = null

## The second handle of the interpolation.
@export
var control_2: Box = null

@export_subgroup("Spherical Interpolation")

## If enabled and the interpolation is a 2D angle or a 3D quaternion, interpolate
## to the nearest angle instead using the absolute numerical value.
@export
var spherical := false

## If enabled and the interpolation is a 3D quaternion, interpolate
## to the nearest angle instead using the absolute numerical value, but don't check
## if the rotation is greater than 90 degrees. See [method Quaternion.slerpni] for
## more information.
@export
var use_slerpni_for_quats := false

@export_group("Easing")

## Defines what behavior the interpolation to use.
## The weight returned by the easing type will be relative to the range
## [code][0, 1][/code] unless the designer specifies something custom using
## [enum EasingType.CURVE] or [enum EasingType.EQUATION].
@export
var easing_type: EasingType = EasingType.BUILT_IN

@export_subgroup("Built-in", "built_in_")

## The native Godot transition type to use. See [Tween] for more information.
@export
var built_in_transition: Tween.TransitionType = Tween.TRANS_LINEAR

## The native Godot easing type to use. See [Tween] for more information.
@export
var built_in_easing: Tween.EaseType = Tween.EASE_IN

@export_subgroup("Arbitrary Curve")

## The curve to use, drawable in-editor by a designer. As of Godot 4.4, the [Curve]'s
## domain (x-axis) can be extended beyond [code][0, 1][/code]. Please do not change
## this, as only x-values between [code][0, 1][/code] will be evaluated.
@export
var arbitrary_curve: Curve = null

## Whether to evaluate the state of this curve every time it is sampled for an
## interpolation. Useful if the curve changes as the interpolation is occurring.
@export
var dynamically_sample_curve := false

@export_subgroup("Arbitrary Equation")

## The equation to evaluate for the interpolation.
@export
var equation: InterpolationEquation = null

@export_subgroup("ease()")

## The curve that [method @GlobalScope.ease] should use for the interpolation.
@export_exp_easing
var ease_function_curve := 0.0

## Returns the interpolated value at the given [param weight].
## [param weight] must be in the range [code][0, 1][/code].
func at(weight: float) -> Variant:
	var xformed_weight := _get_transformed_weight(weight)
	
	if interpolation_type == InterpolationType.CUBIC:
		return _cubic_lerp(start.data, end.data, xformed_weight)
	elif interpolation_type == InterpolationType.CUBIC_IN_TIME:
		return _cubic_lerp_in_time(start.data, end.data, xformed_weight)
	elif interpolation_type == InterpolationType.BEZIER:
		return _bezier_lerp(start.data, end.data, xformed_weight)
	
	return _lerp(start.data, end.data, xformed_weight)

## Creates and returns a copy of this curve. [param deep] determines whether to
## fully copy the nested resources of this curve.
func clone(deep: bool = false) -> ControlCurve:
	return duplicate(deep) as ControlCurve

func between(from: Box, to: Box) -> ControlCurve:
	start = from
	end = to
	return self

func towards(to: Box) -> ControlCurve:
	end = to
	return self

func reversed() -> ControlCurve:
	var temp := start
	start = end
	end = temp
	return self

func uses_builtin_easing(easing: Tween.EaseType) -> ControlCurve:
	built_in_easing = easing
	return self

func _lerp(a: Variant, b: Variant, weight: float) -> Variant:
	if a is Transform2D:
		return (a as Transform2D).interpolate_with(b as Transform2D, weight)
	
	if a is Transform3D:
		return (a as Transform3D).interpolate_with(b as Transform3D, weight)
	
	if spherical:
		return _spherical_lerp(a, b, weight)
	
	return lerp(a, b, weight)

func _spherical_lerp(a: Variant, b: Variant, weight: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Quaternion and b is Quaternion)
		or (a is Basis and b is Basis)
		, "Cannot spherically interpolate these values!")
	
	if a is float:
		return lerp_angle(a as float, b as float, weight)
	
	elif a is Quaternion and use_slerpni_for_quats:
		return (a as Quaternion).slerpni(b as Quaternion, weight)
		
	return a.slerp(b, weight)

func _cubic_lerp(a: Variant, b: Variant, weight: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Vector4 and b is Vector4)
		or (a is Quaternion and b is Quaternion)
		, "Cannot cubically interpolate these values!")
	
	if a is float:
		if spherical:
			return cubic_interpolate_angle(a as float, b as float, prestart.data as float, postend.data as float, weight)
		
		return cubic_interpolate(a as float, b as float, prestart.data as float, postend.data as float, weight)
	
	elif a is Quaternion:
		return (a as Quaternion).spherical_cubic_interpolate(b as Quaternion, prestart.data as Quaternion, postend.data as Quaternion, weight)
	
	return a.cubic_interpolate(b, prestart.data, postend.data, weight)

func _cubic_lerp_in_time(a: Variant, b: Variant, weight: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Vector4 and b is Vector4)
		or (a is Quaternion and b is Quaternion)
		, "Cannot cubically interpolate with respect to time with these values!")
	
	if a is float:
		if spherical:
			return cubic_interpolate_angle_in_time(a as float, b as float, prestart.data as float, postend.data as float, weight, end_time, prestart_time, postend_time)
		
		return cubic_interpolate_in_time(a as float, b as float, prestart.data as float, postend.data as float, weight, end_time, prestart_time, postend_time)
	
	elif a is Quaternion:
		return (a as Quaternion).spherical_cubic_interpolate_in_time(b as Quaternion, prestart.data as Quaternion, postend.data as Quaternion, weight, end_time, prestart_time, postend_time)
	
	return a.cubic_interpolate_in_time(b, prestart.data, postend.data, weight, end_time, prestart_time, postend_time)

func _bezier_lerp(a: Variant, b: Variant, weight: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		, "Cannot Bezier interpolate these values!")
	
	if a is float:
		return bezier_interpolate(a as float, control_1.data as float, control_2.data as float, b as float, weight)
	
	return a.bezier_interpolate(control_1.data, control_2.data, b, weight)

func _get_transformed_weight(weight: float) -> float:
	match easing_type:
		EasingType.CURVE:
			assert(arbitrary_curve, "No curve defined!")
			return arbitrary_curve.sample(weight) if dynamically_sample_curve else arbitrary_curve.sample_baked(weight)
		
		EasingType.EQUATION:
			assert(equation, "No equation defined!")
			return equation.evaluate(weight)
		
		EasingType.EASE_FUNC:
			return ease(weight, ease_function_curve)
		
		_:
			return Tween.interpolate_value(0.0, 1.0, weight, 1.0, built_in_transition, built_in_easing)
