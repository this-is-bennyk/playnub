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

enum CubicBeziérKinkResolution
{
	NONE,
	PARTIAL_MIRRORING,
	FULL_MIRRORING,
}

## The kind of spline to evaluate.
@export
var spline_type: PlaynubSplines.SplineType = PlaynubSplines.SplineType.CARDINAL:
	set(value):
		spline_type = value
		_dirty = true

## Whether the spline should look back to the beginning.
@export
var closed := false:
	set(value):
		closed = value
		_dirty = true

@export_group("Rationalization")

## Whether control points should have ratios, i.e. "weight" or "gravity", relative to other control points.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var rationalization_enabled := false:
	set(value):
		rationalization_enabled = value
		_dirty = true

## The ratio of each control point relative to its neighbors, if [member rationalization_enabled] is [code]true[/code].
## Ratios are automatically clamped within the range [code](0, ∞)[/code].
@export
var ratios := PackedFloat64Array():
	set(value):
		_match_control_point_count(value, 1.0)
		
		ratios = value
		_dirty = true

@export_group("Cardinal", "cardinal_")

## How tight or loose the corner around each control point should be in a Cardinal spline.
@export
var cardinal_tension := 0.5:
	set(value):
		cardinal_tension = value
		_dirty = true

@export_group("Cubic Beziér", "cubic_bezier_")

@export
var cubic_bezier_kink_resolutions: Array[CubicBeziérKinkResolution] = []:
	set(value):
		_match_control_point_count(value, CubicBeziérKinkResolution.NONE)
		
		if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIÉR:
			cubic_bezier_kink_resolutions = value
			return
		
		var i := 0
		var size := get_control_point_count()
		
		while i < size:
			set_control_point_kink_resolution(i, value[i])
			i += 1

# kink resolution: closest neighbor, farthest neighbor, equidistant (take avg dist and apply to both)

@export_group("B-Spline", "b_spline_")

## Whether the B-Spline should be non-uniform (technically open-uniform, i.e. starts exactly at the beginning
## point and ends exactly at the ending point).
@export
var b_spline_non_uniform := true:
	set(value):
		b_spline_non_uniform = value
		_dirty = true

@export_group("Kochanek-Bartels", "kochanek_bartels_")

## How tight or loose the corner around each control point should be in a Kochanek-Bartels spline.
@export
var kochanek_bartels_tension := 0.0:
	set(value):
		kochanek_bartels_tension = value
		_dirty = true

## How much to the relative left or right the corner around each control point should be in a Kochanek-Bartels spline.
@export
var kochanek_bartels_bias := 0.0:
	set(value):
		kochanek_bartels_bias = value
		_dirty = true

## How boxy or inverted the corner around each control point should be in a Kochanek-Bartels spline.
@export
var kochanek_bartels_continuity := 0.0:
	set(value):
		kochanek_bartels_continuity = value
		_dirty = true

@export_group("Tangential Splines", "tangential_splines_")

## Whether control points at odd indices in the array of points should be calculated relative to the previous point in the list
## (i.e. if [code]true[/code], instead of passing values P0, P1, P2, and P3 directly to the chosen spline function, values P0, (P1 - P0),
## P2, (P3 - P2) are passed).
@export
var tangential_splines_relative_tangents := true:
	set(value):
		tangential_splines_relative_tangents = value
		_dirty = true

# TODO: Generalized Closest T and Point calculations

#@export_group("Advanced", "advanced_")
#
#@export_range(1, 2, 1, "or_greater")
#var advanced_closest_point_sampling_rate := 1

var _length_table := PackedFloat64Array()
var _dirty := false

@abstract
func evaluate_position(t: float) -> Variant

@abstract
func evaluate_velocity(t: float) -> Variant

@abstract
func evaluate_acceleration(t: float) -> Variant

@abstract
func evaluate_jerk(t: float) -> Variant

@abstract
func get_control_point_count() -> int

@abstract
func get_control_point(index: int) -> Variant

@abstract
func _set_control_point_direct(index: int, pos) -> void

@abstract
func _evaluate_segment_length(index_t: float, use_params_t: bool) -> float

func _perform_additional_recache() -> void:
	pass

func set_control_point(index: int, pos, ignore_kink_resolution := false) -> void:
	assert(index >= 0 and index < get_control_point_count(), "Out-of-bounds spline control point access!")
	
	var prev_pos := get_control_point(index)
	_set_control_point_direct(index, pos)
	
	_dirty = true
	
	if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIÉR or ignore_kink_resolution:
		return
	
	var size := get_control_point_count()
	
	# If the center is being moved, move its neighbors in the same direction
	if index % 3 == 0:
		var prev_neighbor := clampi(index - 1, 0, size - 1)
		var next_neighbor := clampi(index + 1, 0, size - 1)
		
		if closed:
			prev_neighbor = wrapi(index - 1, 0, size - 1)
			next_neighbor = wrapi(index + 1, 0, size - 1)
		
		if prev_neighbor == index or next_neighbor == index:
			return
		
		var is_1D := get_control_point(index) is float
		var kink_resolution := cubic_bezier_kink_resolutions[index]
		
		var prev_neighbor_pos = get_control_point(prev_neighbor)
		var next_neighbor_pos = get_control_point(next_neighbor)
		
		var prev_neighbor_displacement = prev_neighbor_pos - prev_pos
		var next_neighbor_displacement = next_neighbor_pos - prev_pos
		
		if kink_resolution == CubicBeziérKinkResolution.NONE:
			# Could take the center's displacement and add it to each position, but this is less prone to FP error
			_set_control_point_direct(prev_neighbor, pos + prev_neighbor_displacement)
			_set_control_point_direct(next_neighbor, pos + next_neighbor_displacement)
		else:
			var neighbor_dir
			var neighbor_distance
			
			if is_1D:
				neighbor_dir 		= signf(next_neighbor_pos - prev_neighbor_pos)
				neighbor_distance 	= absf(next_neighbor_pos - prev_neighbor_pos)
			else:
				neighbor_dir 		= prev_neighbor_pos.direction_to(next_neighbor_pos)
				neighbor_distance 	= prev_neighbor_pos.distance_to(next_neighbor_pos)
			
			neighbor_distance *= 0.5
			
			if kink_resolution == CubicBeziérKinkResolution.PARTIAL_MIRRORING:
				if is_1D:
					neighbor_distance = absf(prev_neighbor_displacement)
				else:
					neighbor_distance = prev_neighbor_displacement.length()
			
			_set_control_point_direct(prev_neighbor, pos - neighbor_dir * neighbor_distance)
			
			if kink_resolution == CubicBeziérKinkResolution.PARTIAL_MIRRORING:
				if is_1D:
					neighbor_distance = absf(next_neighbor_displacement)
				else:
					neighbor_distance = next_neighbor_displacement.length()
			
			_set_control_point_direct(next_neighbor, pos + neighbor_dir * neighbor_distance)
	
	# Otherwise a neighbor is being moved, so constrain the opposite neighbor along the line from the center to this neighbor
	elif cubic_bezier_kink_resolutions[index] != CubicBeziérKinkResolution.NONE:
		var center   := clampi(index + 1 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, size - 1)
		var opposite := clampi(index + 2 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, size - 1)
		
		if center == opposite:
			return
		
		var is_1D := get_control_point(index) is float
		
		var center_pos = get_control_point(center)
		var dir_cur_to_center
		var dist_center_to_neighbor
		
		if is_1D:
			dir_cur_to_center 		= signf(get_control_point(index) - center_pos)
			dist_center_to_neighbor 	= absf(get_control_point(opposite) - center_pos)
		else:
			dir_cur_to_center 		= center_pos.direction_to(get_control_point(index))
			dist_center_to_neighbor 	= center_pos.distance_to(get_control_point(opposite))
		
		if cubic_bezier_kink_resolutions[index] == CubicBeziérKinkResolution.FULL_MIRRORING:
			if is_1D:
				dist_center_to_neighbor = absf(prev_pos - center_pos)
			else:
				dist_center_to_neighbor = center_pos.distance_to(prev_pos)
		
		_set_control_point_direct(opposite, center_pos - dir_cur_to_center * dist_center_to_neighbor)

func set_control_point_kink_resolution(index: int, kink_resolution: CubicBeziérKinkResolution) -> void:
	assert(index >= 0 and index < get_control_point_count(), "Out-of-bounds spline control point access!")
	
	if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIÉR:
		cubic_bezier_kink_resolutions[index] = kink_resolution
		return
	
	_match_control_point_count(cubic_bezier_kink_resolutions, CubicBeziérKinkResolution.NONE)
	
	if cubic_bezier_kink_resolutions[index] != kink_resolution:
		set_control_point(index, get_control_point(index))
		_dirty = true
	
	cubic_bezier_kink_resolutions[index] = kink_resolution

func get_control_point_kink_resolution(index: int) -> CubicBeziérKinkResolution:
	assert(index >= 0 and index < get_control_point_count(), "Out-of-bounds spline control point access!")
	return cubic_bezier_kink_resolutions[index]

func evaluate_length(t: float) -> float:
	if get_control_point_count() <= 0:
		return 0.0
	
	_recache()
	
	if _length_table.is_empty():
		return _evaluate_segment_length(t, true)
	
	var segment_index := int(t * _length_table.size())
	var length_of_prev_segment := 0.0
	
	if segment_index >= get_control_point_count():
		length_of_prev_segment = _length_table[_length_table.size() - 1]
	elif segment_index > 0:
		length_of_prev_segment = _length_table[segment_index - 1]
	
	return length_of_prev_segment + _evaluate_segment_length(t, true)

func get_total_length() -> float:
	if get_control_point_count() <= 0:
		return 0.0
	
	_recache()
	
	if _length_table.is_empty():
		return _evaluate_segment_length(1.0, true)
	
	return _length_table[_length_table.size() - 1]

func is_ubs() -> bool:
	return spline_type == PlaynubSplines.SplineType.B_SPLINE \
		and (not (b_spline_non_uniform or closed)) \
		and get_control_point_count() >= PlaynubSplines.B_SPLINE_NUM_MIN_UNIFORM_POINTS

func is_nubs() -> bool:
	return spline_type == PlaynubSplines.SplineType.B_SPLINE and b_spline_non_uniform and not closed

func is_nurbs() -> bool:
	return is_nubs() and rationalization_enabled

func is_tangential_spline() -> bool:
	return spline_type == PlaynubSplines.SplineType.HERMITE \
		or spline_type == PlaynubSplines.SplineType.BIARC_UNCACHED \
		or spline_type == PlaynubSplines.SplineType.BIARC_CACHED

class EvaluationParameters:
	var t := 0.0
	
	var x0 := 0
	var x1 := 0
	var x2 := 0
	var x3 := 0
	
	var e1: Variant = null
	var e2 := 0.0
	var e3 := 0.0
	
	var relative_tangents_mult := 0.0

func get_evaluation_parameters(t: float) -> EvaluationParameters:
	assert(get_control_point_count() > 0, "No points in this spline!")
	
	var result := EvaluationParameters.new()
	
	result.e1 = cardinal_tension * float(spline_type == PlaynubSplines.SplineType.CARDINAL) \
			  + kochanek_bartels_tension * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	result.e2 = kochanek_bartels_bias * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	result.e3 = kochanek_bartels_continuity * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	
	var relative_tangents := is_tangential_spline() and tangential_splines_relative_tangents
	result.relative_tangents_mult = float(relative_tangents)
	
	var nubs := is_nubs()
	var nubs_size_adjust := PlaynubSplines.B_SPLINE_NUM_NON_UNIFORM_POINTS * int(nubs)
	var size := get_control_point_count() + int(closed) + nubs_size_adjust
	
	if spline_type == PlaynubSplines.SplineType.CUBIC_BEZIÉR:
		var num_segments := ceili(float(size) * PlaynubSplines._ONE_THIRD)
		
		var abs_segment_t := t * float(num_segments)
		var cur_segment := int(abs_segment_t)
		var segment_t := abs_segment_t - float(cur_segment)
		
		result.t = segment_t
		
		result.x0 = clampi(cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE    , 0, size - 1)
		result.x1 = clampi(cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 1, 0, size - 1)
		result.x2 = clampi(cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 2, 0, size - 1)
		result.x3 = clampi(cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 3, 0, size - 1)
		
		if closed:
			result.x0 = cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE
			result.x1 = cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 1
			result.x2 = cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 2
			result.x3 = cur_segment * PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE + 3
			
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
		var absolute_t = t * float(size)
		var cur := int(absolute_t)
		var cur_as_float := float(cur)
		
		result.t = absolute_t - cur_as_float
		
		if is_ubs():
			absolute_t = clampf(absolute_t, 0.0, float(size - (PlaynubSplines.B_SPLINE_NUM_MIN_UNIFORM_POINTS - 1)))
			cur = clampi(cur, 0, size - PlaynubSplines.B_SPLINE_NUM_MIN_UNIFORM_POINTS)
			cur_as_float = float(cur)
			
			result.t = absolute_t - cur_as_float
			
			result.x0 = clampi(cur    , 0, size - 1)
			result.x1 = clampi(cur + 1, 0, size - 1)
			result.x2 = clampi(cur + 2, 0, size - 1)
			result.x3 = clampi(cur + 3, 0, size - 1)
		else:
			var nubs_start_offset := PlaynubSplines.B_SPLINE_NON_UNIFORM_OFFSET_SIZE * int(nubs)
			
			result.x0 = clampi(cur - 1 - nubs_start_offset, 0, size - 1 - nubs_size_adjust)
			result.x1 = clampi(cur     - nubs_start_offset, 0, size - 1 - nubs_size_adjust)
			result.x2 = clampi(cur + 1 - nubs_start_offset, 0, size - 1 - nubs_size_adjust)
			result.x3 = clampi(cur + 2 - nubs_start_offset, 0, size - 1 - nubs_size_adjust)
			
			if closed:
				result.x0 = wrapi(cur - 1, 0, size - int(closed))
				result.x1 = wrapi(cur    , 0, size - int(closed))
				result.x2 = wrapi(cur + 1, 0, size - int(closed))
				result.x3 = wrapi(cur + 2, 0, size - int(closed))
	
	return result

func _recache() -> void:
	if not _dirty:
		return
	
	var is_cubic_bezier := spline_type == PlaynubSplines.SplineType.CUBIC_BEZIÉR
	var is_tangential := is_tangential_spline()
	var nubs := is_nubs()
	var nubs_size_adjust := PlaynubSplines.B_SPLINE_NUM_NON_UNIFORM_POINTS * int(nubs)
	var segment_size := maxi(1, PlaynubSplines.CUBIC_BEZIÉR_SEGMENT_SIZE * int(is_cubic_bezier) + PlaynubSplines.TANGENTIAL_SEGMENT_SIZE * int(is_tangential))
	var num_segments := float(get_control_point_count() + int(closed) + nubs_size_adjust) / float(segment_size)
	
	_length_table.resize(roundi(num_segments))
	
	var i := 0
	var size := float(_length_table.size())
	
	while i < _length_table.size():
		var prev_length := 0.0 if i == 0 else _length_table[i - 1]
		var cur_length := _evaluate_segment_length(float(i) / size, false)
		
		_length_table[i] = prev_length + cur_length
		i += 1
	
	_perform_additional_recache()
	
	_dirty = false

func _match_control_point_count(array: Array, default_value: Variant) -> void:
	if array.size() != get_control_point_count():
		var old_size := array.size()
		var new_size := get_control_point_count()
		
		array.resize(new_size)
		
		if new_size > old_size:
			for i: int in range(old_size, new_size):
				array[i] = default_value
