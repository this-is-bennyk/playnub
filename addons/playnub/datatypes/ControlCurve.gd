class_name ControlCurve
extends Resource

## Creates a curve for interpolations to use.
##
## (Technically, a control curve is three curves: an attack curve, a sustain line,
## and a release curve. However, this is the closest terminology that describes the
## function of this resource.)

enum InterpolationType
{
	LINEAR,
	CUBIC,
	CUBIC_WITH_TIME,
	BEZIER
}

enum EasingType
{
	  BUILT_IN
	, ARBITRARY
	, EXP_EASE
	, SMOOTHSTEP
}

@export_group("Interpolation")

@export
var interpolation_type: InterpolationType = InterpolationType.LINEAR

@export
var start: Box = null

@export
var end: Box = null

@export_subgroup("Cubic Interpolation (in Time)")

@export
var prestart: Box = null

@export
var prestart_time: float = 0.0

@export
var postend: Box = null

@export
var postend_time: float = 0.0

@export
var end_time: float = 0.0

@export_subgroup("Bézier Interpolation")

@export
var control_1: Box = null

@export
var control_2: Box = null

@export_subgroup("Spherical Interpolation")

@export
var spherical := false

@export
var use_slerpni_for_quats := false

@export_group("Easing")

@export
var easing_type: EasingType = EasingType.BUILT_IN

@export_subgroup("Built-in Easings", "built_in_")

@export
var built_in_transition: Tween.TransitionType = Tween.TRANS_LINEAR

@export
var built_in_easing: Tween.EaseType = Tween.EASE_IN

@export_subgroup("Arbitrary Curve Easing")

@export
var arbitrary_curve: Curve = null

@export
var dynamically_sample_curve := false

@export_subgroup("Exponential Easing")

@export_exp_easing
var exponential_easing_curve := 0.0

func at(percent: float) -> Variant:
	var xformed_percent := _get_transformed_percent(percent)
	
	if interpolation_type == InterpolationType.CUBIC:
		return _cubic_lerp(start.data, end.data, xformed_percent)
	elif interpolation_type == InterpolationType.CUBIC_WITH_TIME:
		return _cubic_lerp_in_time(start.data, end.data, xformed_percent)
	elif interpolation_type == InterpolationType.BEZIER:
		return _bezier_lerp(start.data, end.data, xformed_percent)
	
	return _lerp(start.data, end.data, xformed_percent)

func between(from: Box, to: Box) -> ControlCurve:
	start = from
	end = to
	return self

func _lerp(a: Variant, b: Variant, percent: float) -> Variant:
	if a is Transform2D:
		return (a as Transform2D).interpolate_with(b as Transform2D, percent)
	
	if a is Transform3D:
		return (a as Transform3D).interpolate_with(b as Transform3D, percent)
	
	if spherical:
		return _spherical_lerp(a, b, percent)
	
	return lerp(a, b, percent)

func _spherical_lerp(a: Variant, b: Variant, percent: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Quaternion and b is Quaternion)
		or (a is Basis and b is Basis)
		, "Cannot spherically interpolate these values!")
	
	if a is float:
		return lerp_angle(a as float, b as float, percent)
	
	elif a is Quaternion and use_slerpni_for_quats:
		return (a as Quaternion).slerpni(b as Quaternion, percent)
		
	return a.slerp(b, percent)

func _cubic_lerp(a: Variant, b: Variant, percent: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Vector4 and b is Vector4)
		or (a is Quaternion and b is Quaternion)
		, "Cannot cubically interpolate these values!")
	
	if a is float:
		if spherical:
			return cubic_interpolate_angle(a as float, b as float, prestart.floating_point, postend.floating_point, percent)
		
		return cubic_interpolate(a as float, b as float, prestart.floating_point, postend.floating_point, percent)
	
	elif a is Quaternion:
		return (a as Quaternion).spherical_cubic_interpolate(b as Quaternion, prestart.quaternion, postend.quaternion, percent)
	
	return a.cubic_interpolate(b, prestart.data, postend.data, percent)

func _cubic_lerp_in_time(a: Variant, b: Variant, percent: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		or (a is Vector4 and b is Vector4)
		or (a is Quaternion and b is Quaternion)
		, "Cannot cubically interpolate with respect to time with these values!")
	
	if a is float:
		if spherical:
			return cubic_interpolate_angle_in_time(a as float, b as float, prestart.floating_point, postend.floating_point, percent, end_time, prestart_time, postend_time)
		
		return cubic_interpolate_in_time(a as float, b as float, prestart.floating_point, postend.floating_point, percent, end_time, prestart_time, postend_time)
	
	elif a is Quaternion:
		return (a as Quaternion).spherical_cubic_interpolate_in_time(b as Quaternion, prestart.quaternion, postend.quaternion, percent, end_time, prestart_time, postend_time)
	
	return a.cubic_interpolate_in_time(b, prestart.data, postend.data, percent, end_time, prestart_time, postend_time)

func _bezier_lerp(a: Variant, b: Variant, percent: float) -> Variant:
	assert(
		   (a is float and b is float)
		or (a is Vector2 and b is Vector2)
		or (a is Vector3 and b is Vector3)
		, "Cannot Bezier interpolate these values!")
	
	if a is float:
		return bezier_interpolate(a as float, control_1.floating_point, control_2.floating_point, b as float, percent)
	
	return a.bezier_interpolate(control_1.data, control_2.data, b, percent)

func _get_transformed_percent(percent: float) -> float:
	match easing_type:
		EasingType.ARBITRARY:
			assert(arbitrary_curve, "No curve defined!")
			return arbitrary_curve.sample(percent) if dynamically_sample_curve else arbitrary_curve.sample_baked(percent)
		
		EasingType.EXP_EASE:
			return ease(percent, exponential_easing_curve)
		
		EasingType.SMOOTHSTEP:
			return smoothstep(0.0, 1.0, percent)
		
		_:
			return Tween.interpolate_value(0.0, 1.0, percent, 1.0, built_in_transition, built_in_easing)
