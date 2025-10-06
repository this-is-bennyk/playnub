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

class_name Spliner2D
extends Resource

enum CubicBezierKinkResolution
{
	NEAREST_NEIGHBOR,
	FARTHEST_NEIGHBOR,
	EQUIDISTANT,
}

@export var spline_type: PlaynubSplines.SplineType = PlaynubSplines.SplineType.CARDINAL

@export var closed := false

@export_group("Rationalization", "rationalization_")

@export var rationalization_enabled := false
# Bound is (-0.1, inf) i.e. [-0.099, inf)

@export_group("Cardinal", "cardinal_")

@export var cardinal_scale := 0.5

@export_group("Cubic Beziér", "cubic_bezier_")

@export var cubic_bezier_allow_kinks := true:
	set(value):
		cubic_bezier_allow_kinks = value
		
		#for i: int in range(icons.size()):
			#move_point(i, icons[i].position)

# kink resolution: closest neighbor, farthest neighbor, equidistant (take avg dist and apply to both)

@export_group("Cubic B-Spline", "cubic_b_spline_")

@export var cubic_b_spline_non_uniform := true

@export_group("Kochanek-Bartels", "kochanek_bartels_")

@export_range(-1.0, 1.0, 0.01)
var kochanek_bartels_tension := 0.0
@export_range(-1.0, 1.0, 0.01)
var kochanek_bartels_bias := 0.0
@export_range(-1.0, 1.0, 0.01)
var kochanek_bartels_continuity := 0.0

#func move_point(index: int, pos: Vector2) -> void:
	#var prev_pos := icons[index].position
	#icons[index].position = pos
	#
	#if spline_type != PlaynubSplines.SplineType.CUBIC_BEZIER or cubic_bezier_allow_kinks:
		#return
	#
	## If the center is being moved, move its neighbors in the same direction
	#if index % 3 == 0:
		#var prev_neighbor := clampi(index - 1, 0, icons.size() - 1)
		#var next_neighbor := clampi(index + 1, 0, icons.size() - 1)
		#
		#if prev_neighbor == index or next_neighbor == index:
			#return
		#
		#var prev_neighbor_displacement := icons[prev_neighbor].position - prev_pos
		#var next_neighbor_displacement := icons[next_neighbor].position - prev_pos
		#
		## Could take the center's displacement and add it to each position, but this is less prone to FP error
		#icons[prev_neighbor].position = pos + prev_neighbor_displacement
		#icons[next_neighbor].position = pos + next_neighbor_displacement
	#
	## Otherwise a neighbor is being moved, so constrain the opposite neighbor along the line from the center to this neighbor
	#else:
		#var center   := clampi(index + 1 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, icons.size() - 1)
		#var opposite := clampi(index + 2 * (-1 * int(index % 3 == 1) + int(index % 3 == 2)), 0, icons.size() - 1)
		#
		#if center == opposite:
			#return
		#
		#var dir_cur_to_center       := icons[center].position.direction_to(icons[index].position)
		#var dist_center_to_neighbor := icons[center].position.distance_to(icons[opposite].position)
		#
		#icons[opposite].position = icons[center].position - dir_cur_to_center * dist_center_to_neighbor
#
#func _process(_delta: float) -> void:
	#line_2d.clear_points()
	#
	#var points: Array[Vector2] = []
	#var sizes: Array[float] = []
	#
	#var e1 := cardinal_scale * float(spline_type == PlaynubSplines.SplineType.CARDINAL) \
			#+ kochanek_bartels_tension * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	#var e2 := kochanek_bartels_bias * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	#var e3 := kochanek_bartels_continuity * float(spline_type == PlaynubSplines.SplineType.KOCHANEK_BARTELS)
	#
	#for icon: Sprite2D in icons:
		#points.push_back(icon.position)
		#sizes.push_back(icon.scale.x / 0.2)
	#
	#if spline_type == PlaynubSplines.SplineType.CUBIC_B_SPLINE and cubic_b_spline_non_uniform and not closed:
		#points.push_back(points.back())
		#points.push_back(points.back())
		#points.push_back(points.back())
		#points.push_front(points.front())
		#points.push_front(points.front())
		#points.push_front(points.front())
		#
		#sizes.push_back(sizes.back())
		#sizes.push_back(sizes.back())
		#sizes.push_back(sizes.back())
		#sizes.push_front(sizes.front())
		#sizes.push_front(sizes.front())
		#sizes.push_front(sizes.front())
	#
	#var i := 0
	#
	#if spline_type == PlaynubSplines.SplineType.CUBIC_BEZIER:
		#var num_segments := ceili(float(icons.size()) / 3.0)
		#
		#while i < steps:
			#var t := float(i) / float(steps)
			#var abs_segment_t := t * float(num_segments)
			#var cur_segment := int(abs_segment_t)
			#var segment_t := abs_segment_t - float(cur_segment)
			#
			#var x0  := clampi(cur_segment * 3    , 0, points.size() - 1)
			#var x1  := clampi(cur_segment * 3 + 1, 0, points.size() - 1)
			#var x2  := clampi(cur_segment * 3 + 2, 0, points.size() - 1)
			#var x3  := clampi(cur_segment * 3 + 3, 0, points.size() - 1)
			#
			#var point := PlaynubSplines.eval_rational_spline_2D(spline_type
					#, PlaynubSplines.SplineEvaluation.POSITION
					#, segment_t
					#, points[x0], points[x1], points[x2], points[x3]
					#, sizes[x0], sizes[x1], sizes[x2], sizes[x3]
					#, e1, e2, e3
				#) if rationalization_enabled else PlaynubSplines.eval_spline_2D(spline_type
					#, PlaynubSplines.SplineEvaluation.POSITION
					#, segment_t
					#, points[x0], points[x1], points[x2], points[x3]
					#, e1, e2, e3
				#)
			#
			#line_2d.add_point(point)
			#
			#i += 1
	#else:
		#var count := points.size() + int(closed)
		#while i < steps:
			#var t := float(i) / float(steps)
			#var cur := int(t * float(count))
			#
			#var x0 := clampi(cur - 1, 0, points.size() - 1)
			#var x1 := clampi(cur    , 0, points.size() - 1)
			#var x2 := clampi(cur + 1, 0, points.size() - 1)
			#var x3 := clampi(cur + 2, 0, points.size() - 1)
			#
			#if closed:
				#x0 = wrapi(cur - 1, 0, points.size())
				#x1 = wrapi(cur    , 0, points.size())
				#x2 = wrapi(cur + 1, 0, points.size())
				#x3 = wrapi(cur + 2, 0, points.size())
			#
			#var point := PlaynubSplines.eval_rational_spline_2D(spline_type
					#, PlaynubSplines.SplineEvaluation.POSITION
					#, (t * float(count)) - float(cur)
					#, points[x0], points[x1], points[x2], points[x3]
					#, sizes[x0], sizes[x1], sizes[x2], sizes[x3]
					#, e1, e2, e3
				#) if rationalization_enabled else PlaynubSplines.eval_spline_2D(spline_type
					#, PlaynubSplines.SplineEvaluation.POSITION
					#, (t * float(count)) - float(cur)
					#, points[x0], points[x1], points[x2], points[x3]
					#, e1, e2, e3
				#)
			#
			#line_2d.add_point(point)
			#
			#i += 1
