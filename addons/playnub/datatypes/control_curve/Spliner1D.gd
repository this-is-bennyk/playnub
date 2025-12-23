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
class_name Spliner1D
extends Spliner

## Generates a 1-dimensional spline.

## The list of points to create a spline out of.
@export
var points := PackedFloat64Array():
	set(value):
		points = value
		ratios = ratios
		_dirty = true
		emit_changed()

## See [method Spliner.evaluate_position].
func evaluate_position(t: float) -> float:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.POSITION)

## See [method Spliner.evaluate_velocity].
func evaluate_velocity(t: float) -> float:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.VELOCITY)

## See [method Spliner.evaluate_acceleration].
func evaluate_acceleration(t: float) -> float:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.ACCELERATION)

## See [method Spliner.evaluate_jerk].
func evaluate_jerk(t: float) -> float:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.JERK)

## See [method Spliner.get_control_point_count].
func get_control_point_count() -> int:
	return points.size()

## See [method Spliner.get_control_point].
func get_control_point(index: int) -> float:
	return points[index]

func _set_control_point_direct(index: int, pos: float) -> void:
	points[index] = pos

func _evaluate_segment_length(index_t: float, use_params_t: bool) -> float:
	assert(
		not (spline_type == PlaynubSplines.SplineType.BIARC_UNCACHED or spline_type == PlaynubSplines.SplineType.BIARC_CACHED),
		"Incompatible spline type!"
	)
	
	var params := get_evaluation_parameters(index_t)
	
	return PlaynubSplines.length_rational_1D(
			  spline_type
			, params.t if use_params_t else 1.0
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, ratios[params.x0], ratios[params.x1], ratios[params.x2], ratios[params.x3]
			, params.e1, params.e2, params.e3
		) if rationalization_enabled else PlaynubSplines.length_1D(
			  spline_type
			, params.t if use_params_t else 1.0
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, params.e1, params.e2, params.e3
		)

func _eval_spline(t: float, eval: PlaynubSplines.SplineEvaluation) -> float:
	assert(
		not (spline_type == PlaynubSplines.SplineType.BIARC_UNCACHED or spline_type == PlaynubSplines.SplineType.BIARC_CACHED),
		"Incompatible spline type!"
	)
	
	_recache()
	
	var params := get_evaluation_parameters(t)
	
	return PlaynubSplines.eval_rational_1D(
			  spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, ratios[params.x0], ratios[params.x1], ratios[params.x2], ratios[params.x3]
			, params.e1, params.e2, params.e3
		) if rationalization_enabled else PlaynubSplines.eval_1D(spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, params.e1, params.e2, params.e3
		)
