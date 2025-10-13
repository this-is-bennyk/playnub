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

@abstract
@tool
class_name Spliner
extends Resource

## The base class of all dimensions of splines.
## 
## This class abstracts out the common behaviors between splines of all dimensions.

enum CubicBezierKinkResolution
{
	NEAREST_NEIGHBOR,
	FARTHEST_NEIGHBOR,
	EQUIDISTANT,
}

## The kind of spline to evaluate.
@export
var spline_type: PlaynubSplines.SplineType = PlaynubSplines.SplineType.CARDINAL

@export
var closed := false

@export_group("Rationalization")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var rationalization_enabled := false

@export
var ratios := PackedFloat64Array():
	set(value):
		if value.size() != get_control_point_count():
			var old_size := value.size()
			var new_size := get_control_point_count()
			
			value.resize(new_size)
			
			if new_size > old_size:
				for i: int in range(old_size, new_size):
					value[i] = 1.0
			
		ratios = value

@export_group("Cardinal", "cardinal_")

@export var cardinal_tension := 0.5

@export_group("Cubic Beziér", "cubic_bezier_")

@export var cubic_bezier_allow_kinks := true:
	set(value):
		cubic_bezier_allow_kinks = value
		
		if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIER or cubic_bezier_allow_kinks:
			return
		
		var i := 0
		var size := get_control_point_count()
		
		while i < size:
			set_control_point(i, get_control_point(i))
			i += 1

# kink resolution: closest neighbor, farthest neighbor, equidistant (take avg dist and apply to both)

@export_group("Cubic B-Spline", "cubic_b_spline_")

@export var cubic_b_spline_non_uniform := true

@export_group("Kochanek-Bartels", "kochanek_bartels_")

@export
var kochanek_bartels_tension := 0.0
@export
var kochanek_bartels_bias := 0.0
@export
var kochanek_bartels_continuity := 0.0

@export_group("Tangential Splines", "tangential_splines_")

@export
var tangential_splines_relative_tangents := true

@abstract
func evaluate_position(t: float) -> Variant

@abstract
func evaluate_velocity(t: float) -> Variant

@abstract
func evaluate_acceleration(t: float) -> Variant

@abstract
func evaluate_jerk(t: float) -> Variant

@abstract
func evaluate_length(t: float) -> float

@abstract
func get_control_point_count() -> int

@abstract
func get_control_point(index: int) -> Variant

@abstract
func _set_control_point_direct(index: int, pos) -> void

func set_control_point(index: int, pos) -> void:
	var prev_pos := get_control_point(index)
	_set_control_point_direct(index, pos)
	
	if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIER or cubic_bezier_allow_kinks:
		return
	
	var size := get_control_point_count()
	
	# If the center is being moved, move its neighbors in the same direction
	if index % 3 == 0:
		var prev_neighbor := clampi(index - 1, 0, size - 1)
		var next_neighbor := clampi(index + 1, 0, size - 1)
		
		if prev_neighbor == index or next_neighbor == index:
			return
		
		var prev_neighbor_displacement = get_control_point(prev_neighbor) - prev_pos
		var next_neighbor_displacement = get_control_point(next_neighbor) - prev_pos
		
		# Could take the center's displacement and add it to each position, but this is less prone to FP error
		_set_control_point_direct(prev_neighbor, pos + prev_neighbor_displacement)
		_set_control_point_direct(next_neighbor, pos + next_neighbor_displacement)
	
	# Otherwise a neighbor is being moved, so constrain the opposite neighbor along the line from the center to this neighbor
	else:
		var center   := clampi(index + 1 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, size - 1)
		var opposite := clampi(index + 2 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, size - 1)
		
		if center == opposite:
			return
		
		var center_pos = get_control_point(center)
		var dir_cur_to_center
		var dist_center_to_neighbor
		
		if center_pos is float:
			dir_cur_to_center		= signf(get_control_point(index) - center_pos)
			dist_center_to_neighbor 	= absf(get_control_point(opposite) - center_pos)
		else:
			dir_cur_to_center		= center_pos.direction_to(get_control_point(index))
			dist_center_to_neighbor 	= center_pos.distance_to(get_control_point(opposite))
			
		_set_control_point_direct(opposite, center_pos - dir_cur_to_center * dist_center_to_neighbor)

func is_nurbs() -> bool:
	return spline_type == PlaynubSplines.SplineType.CUBIC_B_SPLINE \
		and cubic_b_spline_non_uniform and rationalization_enabled and not closed

func is_tangential_spline() -> bool:
	return spline_type == PlaynubSplines.SplineType.HERMITE \
		or spline_type == PlaynubSplines.SplineType.BIARC_UNCACHED \
		or spline_type == PlaynubSplines.SplineType.BIARC_CACHED

func get_evaluation_parameters(t: float) -> SplineEvaluationParameters:
	var result := SplineEvaluationParameters.new()
	
	result.e1 = cardinal_tension * float(spline_type == PlaynubSplines.SplineType.CARDINAL) \
			  + kochanek_bartels_tension * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	result.e2 = kochanek_bartels_bias * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	result.e3 = kochanek_bartels_continuity * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	
	var nurbs := is_nurbs()
	var size := get_control_point_count() + int(closed) + (6 * int(nurbs))
	
	if spline_type == PlaynubSplines.SplineType.CUBIC_BEZIER:
		var num_segments := ceili(float(size) / 3.0)
		
		var abs_segment_t := t * float(num_segments)
		var cur_segment := int(abs_segment_t)
		var segment_t := abs_segment_t - float(cur_segment)
		
		result.t = segment_t
		
		result.x0 = clampi(cur_segment * 3    , 0, size - 1)
		result.x1 = clampi(cur_segment * 3 + 1, 0, size - 1)
		result.x2 = clampi(cur_segment * 3 + 2, 0, size - 1)
		result.x3 = clampi(cur_segment * 3 + 3, 0, size - 1)
		
		if closed:
			result.x0 = cur_segment * 3
			result.x1 = cur_segment * 3 + 1
			result.x2 = cur_segment * 3 + 2
			result.x3 = cur_segment * 3 + 3
			
			result.x0 = 0 if result.x0 >= size - 1 else result.x0
			result.x1 = 0 if result.x1 >= size - 1 else result.x1
			result.x2 = 0 if result.x2 >= size - 1 else result.x2
			result.x3 = 0 if result.x3 >= size - 1 else result.x3
		
	elif is_tangential_spline():
		var is_even := get_control_point_count() % 2 == 0
		var is_odd  := not is_even
		var size_adjust := int(closed) * (2 * int(is_even) + 1 * int(is_odd))
		
		size = get_control_point_count() + size_adjust
		
		var num_segments := ceili(float(size) * 0.5)
		
		var abs_segment_t := t * float(num_segments)
		var cur_segment := int(abs_segment_t)
		var segment_t := abs_segment_t - float(cur_segment)
		
		result.t = segment_t
		
		if closed:
			result.x0 = wrapi(cur_segment * 2    , 0, size - size_adjust)
			result.x1 = wrapi(cur_segment * 2 + 1, 0, size - size_adjust)
			result.x2 = wrapi(cur_segment * 2 + 2, 0, size - size_adjust)
			result.x3 = wrapi(cur_segment * 2 + 3, 0, size - size_adjust)
		else:
			result.x0 = clampi(cur_segment * 2    , 0, size - 1)
			result.x1 = clampi(cur_segment * 2 + 1, 0, size - 1)
			result.x2 = clampi(cur_segment * 2 + 2, 0, size - 1)
			result.x3 = clampi(cur_segment * 2 + 3, 0, size - 1)
		
	else:
		var cur := int(t * float(size))
		
		result.t = (t * float(size)) - float(cur)
		
		result.x0 = clampi(cur - 1 - (3 * int(nurbs)), 0, size - 1 - (6 * int(nurbs)))
		result.x1 = clampi(cur     - (3 * int(nurbs)), 0, size - 1 - (6 * int(nurbs)))
		result.x2 = clampi(cur + 1 - (3 * int(nurbs)), 0, size - 1 - (6 * int(nurbs)))
		result.x3 = clampi(cur + 2 - (3 * int(nurbs)), 0, size - 1 - (6 * int(nurbs)))
		
		if closed:
			result.x0 = wrapi(cur - 1, 0, size - int(closed))
			result.x1 = wrapi(cur    , 0, size - int(closed))
			result.x2 = wrapi(cur + 1, 0, size - int(closed))
			result.x3 = wrapi(cur + 2, 0, size - int(closed))
	
	return result

class SplineEvaluationParameters:
	var t := 0.0
	
	var x0 := 0
	var x1 := 0
	var x2 := 0
	var x3 := 0
	
	var e1: Variant = null
	var e2 := 0.0
	var e3 := 0.0
