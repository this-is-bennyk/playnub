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

class_name PlaynubMath

## Static class for certain mathematical functions not native to Godot.
## 
## Borrows statistical functions, lerping techniques, etc. from practical sources
## and traditional academia and puts them into one cohesive file,
## to be reused across Playnub files and used directly within projects.
## 
## @tutorial(Freya Holmér: "Lerp smoothing is broken"): https://www.youtube.com/watch?v=LSNQuFEDOyQ

## The minimum of the "useful range" of decay values for [method exp_decay].
## See the tutorial "Lerp smoothing is broken" for more information.
const EXP_DECAY_MIN := 1.0
## The maximum of the "useful range" of decay values for [method exp_decay].
## See the tutorial "Lerp smoothing is broken" for more information.
const EXP_DECAY_MAX := 25.0

## Returns a smoothed, framerate-independent interpolation between two values
## [param a] and [param b], with [param decay] as the speed in which [param a]
## approaches [param b] and [param delta] as the time between frames (given by
## the delta parameter from [method Node._process] or [method Node._physics_process]
## depending on the situation, or with [method Node.get_process_delta_time] or
## [method Node.get_physics_process_delta_time]).[br]
## The "useful range" of values for [param decay] is between [member EXP_DECAY_MIN]
## and [member EXP_DECAY_MAX], inclusive.[br]
## See the tutorial "Lerp smoothing is broken" for more information.
static func exp_decay(a: Variant, b: Variant, decay: float, delta: float) -> Variant:
	return lerp(b, a, exp(-decay * delta))

## Returns the geometric mean of a given set of floating-point numbers from [param inputs].
static func geometric_mean(inputs: Array[float]) -> float:
	var sum := 0.0
	
	for input: float in inputs:
		sum += log(input)
	
	return exp(sum / float(inputs.size()))

## Returns the geometric mean of a packed set of 32-bit floating-point numbers from [param inputs].
static func geometric_mean_packed_f32(inputs: PackedFloat32Array) -> float:
	var sum := 0.0
	
	for input: float in inputs:
		sum += log(input)
	
	return exp(sum / float(inputs.size()))

## Returns the geometric mean of a packed set of 64-bit floating-point numbers from [param inputs].
static func geometric_mean_packed_f64(inputs: PackedFloat64Array) -> float:
	var sum := 0.0
	
	for input: float in inputs:
		sum += log(input)
	
	return exp(sum / float(inputs.size()))
