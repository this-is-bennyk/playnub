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
class_name Spliner2D
extends Spliner

@export
var points := PackedVector2Array():
	set(value):
		points = value
		emit_changed()

func evaluate_position(t: float) -> Vector2:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.POSITION)

func evaluate_velocity(t: float) -> Vector2:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.VELOCITY)

func evaluate_acceleration(t: float) -> Vector2:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.ACCELERATION)

func evaluate_jerk(t: float) -> Vector2:
	return _eval_spline(t, PlaynubSplines.SplineEvaluation.JERK)

func evaluate_length(t: float) -> float:
	var params := get_evaluation_parameters(t)
	var relative_tangents := is_tangential_spline() and tangential_splines_relative_tangents
	var rel_tans_f := float(relative_tangents)
	
	return PlaynubSplines.length_spline_2D(spline_type
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * rel_tans_f
			, points[params.x2]
			, points[params.x3] - points[params.x2] * rel_tans_f
			, params.e1, params.e2, params.e3
		)

func get_control_point_count() -> int:
	return points.size()

func _eval_spline(t: float, eval: PlaynubSplines.SplineEvaluation) -> Vector2:
	var params := get_evaluation_parameters(t)
	var relative_tangents := is_tangential_spline() and tangential_splines_relative_tangents
	var rel_tans_f := float(relative_tangents)
	
	return PlaynubSplines.eval_rational_spline_2D(spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * rel_tans_f
			, points[params.x2]
			, points[params.x3] - points[params.x2] * rel_tans_f
			, ratios[params.x0], ratios[params.x1], ratios[params.x2], ratios[params.x3]
			, params.e1, params.e2, params.e3
		) if rationalization_enabled else PlaynubSplines.eval_spline_2D(spline_type
			, eval
			, params.t
			, points[params.x0]
			, points[params.x1] - points[params.x0] * rel_tans_f
			, points[params.x2]
			, points[params.x3] - points[params.x2] * rel_tans_f
			, params.e1, params.e2, params.e3
		)

func get_control_point(index: int) -> Vector2:
	return points[index]

func _set_control_point_direct(index: int, pos: Vector2) -> void:
	points[index] = pos
