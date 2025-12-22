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
class_name Spliner3D
extends Spliner

## Generates a 3-dimensional spline.

## The list of points to create a spline out of.
@export
var points := PackedVector3Array():
	set(value):
		points = value
		ratios = ratios
		_dirty = true
		emit_changed()

var _cached_biarcs: Array[PlaynubSplines.Biarc3D] = []

## See [method Spliner.evaluate_position].
func evaluate_position(t: float) -> Vector3:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.POSITION)

## See [method Spliner.evaluate_velocity].
func evaluate_velocity(t: float) -> Vector3:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.VELOCITY)

## See [method Spliner.evaluate_acceleration].
func evaluate_acceleration(t: float) -> Vector3:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.ACCELERATION)

## See [method Spliner.evaluate_jerk].
func evaluate_jerk(t: float) -> Vector3:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.JERK)

## See [Spliner.get_control_point_count].
func get_control_point_count() -> int:
	return points.size()

## See [Spliner.get_control_point].
func get_control_point(index: int) -> Vector3:
	return points[index]

func _set_control_point_direct(index: int, pos: Vector3) -> void:
	points[index] = pos

func _evaluate_segment_length(index_t: float, use_params_t: bool) -> float:
	var params := get_evaluation_parameters(index_t)
	
	if use_params_t and spline_type == PlaynubSplines.SplineType.BIARC_CACHED:
		params.e1 = _cached_biarcs[params.x0]
	
	return PlaynubSplines.length_rational_3D(spline_type
			, params.t if use_params_t else 1.0
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, ratios[params.x0], ratios[params.x1], ratios[params.x2], ratios[params.x3]
			, params.e1, params.e2, params.e3
		) if rationalization_enabled else PlaynubSplines.length_3D(
			  spline_type if use_params_t or spline_type != PlaynubSplines.SplineType.BIARC_CACHED else PlaynubSplines.SplineType.BIARC_UNCACHED
			, params.t if use_params_t else 1.0
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, params.e1, params.e2, params.e3
		)

func _perform_additional_recache() -> void:
	if spline_type != PlaynubSplines.SplineType.BIARC_CACHED:
		return
	
	_cached_biarcs.resize(get_control_point_count())
	
	var i := 0
	var size := float(get_control_point_count())
	
	while i < get_control_point_count():
		var params := get_evaluation_parameters(float(i) / size)
		
		if _cached_biarcs[i]:
			_cached_biarcs[i].calculate(
				  points[params.x0]
				, points[params.x1] - points[params.x0] * params.relative_tangents_mult
				, points[params.x2]
				, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			)
		else:
			_cached_biarcs[i] = PlaynubSplines.Biarc3D.new(
				  points[params.x0]
				, points[params.x1] - points[params.x0] * params.relative_tangents_mult
				, points[params.x2]
				, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			)
		
		i += 1

func _eval_spline(t: float, eval: PlaynubSplines.SplineEvaluation) -> Vector3:
	_recache()
	
	var params := get_evaluation_parameters(t)
	
	if spline_type == PlaynubSplines.SplineType.BIARC_CACHED:
		params.e1 = _cached_biarcs[params.x0]
	
	return PlaynubSplines.eval_rational_3D(spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, ratios[params.x0], ratios[params.x1], ratios[params.x2], ratios[params.x3]
			, params.e1, params.e2, params.e3
		) if rationalization_enabled else PlaynubSplines.eval_3D(spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * params.relative_tangents_mult
			, points[params.x2]
			, points[params.x3] - points[params.x2] * params.relative_tangents_mult
			, params.e1, params.e2, params.e3
		)
