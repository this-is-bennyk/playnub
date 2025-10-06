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
class_name VisualCortex
extends Resource

## Defines a vision model for vision-based behavior.

enum State
{
	UNSEEN_AND_UNKNOWN,
	SEEN_BUT_UNKNOWN,
	SEEN_AND_KNOWN
}

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var understanding_threshold := 0.7

@export_group("Front", "front_")

@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:units")
var front_near_radius := 0.0:
	set(value):
		front_near_radius = value
		
		if front_far_radius < front_near_radius:
			front_far_radius = front_near_radius

@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:units")
var front_far_radius := 0.0:
	set(value):
		front_far_radius = value
		
		if front_far_radius < front_near_radius:
			front_far_radius = front_near_radius

@export_subgroup("Peripheral", "front_peripheral")

@export_range(0.0, 360.0, 0.0001, "radians_as_degrees")
var front_peripheral_sight_arc := PI:
	set(value):
		front_peripheral_sight_arc = value
		
		if front_peripheral_sight_arc < front_central_sight_arc:
			front_peripheral_sight_arc = front_central_sight_arc

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var front_peripheral_near_sensory_understanding := 0.5:
	set(value):
		front_peripheral_near_sensory_understanding = value
		
		if front_peripheral_near_sensory_understanding < front_peripheral_far_sensory_understanding:
			front_peripheral_near_sensory_understanding = front_peripheral_far_sensory_understanding

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var front_peripheral_far_sensory_understanding := 0.2:
	set(value):
		front_peripheral_far_sensory_understanding = value
		
		if front_peripheral_near_sensory_understanding < front_peripheral_far_sensory_understanding:
			front_peripheral_near_sensory_understanding = front_peripheral_far_sensory_understanding

@export_subgroup("Central", "front_central_")

@export_range(0.0, 360.0, 0.0001, "radians_as_degrees")
var front_central_sight_arc := PI / 4.0:
	set(value):
		front_central_sight_arc = value
		
		if front_peripheral_sight_arc < front_central_sight_arc:
			front_peripheral_sight_arc = front_central_sight_arc

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var front_central_near_sensory_understanding := 0.7:
	set(value):
		front_central_near_sensory_understanding = value
		
		if front_central_near_sensory_understanding < front_central_far_sensory_understanding:
			front_central_near_sensory_understanding = front_central_far_sensory_understanding

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var front_central_far_sensory_understanding := 0.5:
	set(value):
		front_central_far_sensory_understanding = value
		
		if front_central_near_sensory_understanding < front_central_far_sensory_understanding:
			front_central_near_sensory_understanding = front_central_far_sensory_understanding

@export_group("Back", "back_")

@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:units")
var back_radius := 0.0

@export_range(0.0, 1.0, 0.0001, "suffix:x 100 %")
var back_sensory_understanding := 0.3

# TODO: Coffin vision
