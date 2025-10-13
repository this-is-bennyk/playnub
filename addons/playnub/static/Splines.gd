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

class_name PlaynubSplines

## Static class for the mathematics behind splines.
## 
## Implements several spline types from practical sources and traditional academia and puts them
## into one cohesive file, to be reused across Playnub files and used directly within projects.
## 
## @tutorial(Biarc interpolation): https://www.ryanjuckett.com/biarc-interpolation/
## @tutorial(Freya Holmér: "The Continuity of Splines"): https://www.youtube.com/watch?v=jvPPXbo87ds
## @tutorial(How to compute the length of a spline): https://medium.com/@all2one/how-to-compute-the-length-of-a-spline-e44f5f04c40
## @tutorial(Kochanek-Bartels spline): https://en.wikipedia.org/wiki/Kochanek%E2%80%93Bartels_spline
## @tutorial(Pomax: A Primer on Bézier Curves): https://pomax.github.io/bezierinfo/

const _ONE_TWELFTH := 1.0 / 12.0
const _ONE_SIXTH := 1.0 / 6.0
const _ONE_THIRD := 1.0 / 3.0
const _TWO_THIRDS := 2.0 / 3.0

## Delta value for evaluating derivatives of complex splines.
const SPLINES_EPSILON := 0.0001

## Magic numbers for approximating the length of all splines (except biarc splines, which have a known solution).
const GAUSS_LEGENDRE_COEFFICIENTS: Array[float] = [
	0.0, 128.0 / 225.0,
	-_ONE_THIRD * sqrt(5.0 - 2.0 * sqrt(10.0 / 7.0)), ((322.0 + 13.0 * sqrt(70.0)) / 900.0),
	 _ONE_THIRD * sqrt(5.0 - 2.0 * sqrt(10.0 / 7.0)), ((322.0 + 13.0 * sqrt(70.0)) / 900.0),
	-_ONE_THIRD * sqrt(5.0 + 2.0 * sqrt(10.0 / 7.0)), ((322.0 - 13.0 * sqrt(70.0)) / 900.0),
	 _ONE_THIRD * sqrt(5.0 + 2.0 * sqrt(10.0 / 7.0)), ((322.0 - 13.0 * sqrt(70.0)) / 900.0),
]

enum SplineType
{
	  CARDINAL
	, CATMULL_ROM
	
	, CUBIC_BEZIER
	, CUBIC_B_SPLINE
	
	, HERMITE
	, KOCHANEK_BARTELS
	
	, BIARC_UNCACHED
	, BIARC_CACHED
}

enum SplineEvaluation
{
	  POSITION
	, VELOCITY
	, ACCELERATION
	, JERK
}

static func eval_spline_1D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: float, p1: float, p2: float, p3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	match type:
		SplineType.CARDINAL:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cardinal_1D_vel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.ACCELERATION:
					return spline_cardinal_1D_accel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.JERK:
					return spline_cardinal_1D_jerk(t, p0, p1, p2, p3, extra1)
				_:
					return spline_cardinal_1D(t, p0, p1, p2, p3, extra1)
		SplineType.CATMULL_ROM:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_catmull_rom_1D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_catmull_rom_1D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_catmull_rom_1D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_catmull_rom_1D(t, p0, p1, p2, p3)
		SplineType.CUBIC_BEZIER:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_bezier_1D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_bezier_1D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_bezier_1D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_bezier_1D(t, p0, p1, p2, p3)
		SplineType.CUBIC_B_SPLINE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_b_spline_1D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_b_spline_1D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_b_spline_1D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_b_spline_1D(t, p0, p1, p2, p3)
		SplineType.HERMITE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_hermite_1D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_hermite_1D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_hermite_1D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_hermite_1D(t, p0, p1, p2, p3)
		SplineType.KOCHANEK_BARTELS:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_kochanek_bartels_1D_vel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.ACCELERATION:
					return spline_kochanek_bartels_1D_accel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.JERK:
					return spline_kochanek_bartels_1D_jerk(t, p0, p1, p2, p3, extra1, extra2, extra3)
				_:
					return spline_kochanek_bartels_1D(t, p0, p1, p2, p3, extra1, extra2, extra3)
	assert(false, "Unknown/unimplemented spline type!")
	return 0.0

static func length_spline_1D(type: SplineType, t: float,
	p0: float, p1: float, p2: float, p3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	var result := 0.0
	var gauss_legendre_index := 0
	var num_gauss_legendre_coeffs := GAUSS_LEGENDRE_COEFFICIENTS.size() / 2
	
	while gauss_legendre_index < num_gauss_legendre_coeffs:
		var abscissa := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2]
		var weight   := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2 + 1]
		
		result += absf(eval_spline_1D(type, SplineEvaluation.VELOCITY, t * 0.5 * (1.0 + abscissa), p0, p1, p2, p3, extra1, extra2, extra3)) * t * weight
		
		gauss_legendre_index += 1
	
	return 0.5 * result

static func eval_rational_spline_1D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: float, p1: float, p2: float, p3: float,
	r0: float, r1: float, r2: float, r3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	var basis := eval_spline_1D(type, eval, t, r0, r1, r2, r3, extra1, extra2, extra3)
	
	if is_zero_approx(basis):
		basis = 1.0
	
	var result := eval_spline_1D(type, eval, t, p0 * r0, p1 * r1, p2 * r2, p3 * r3, extra1, extra2, extra3) / basis
	return result

static func eval_spline_2D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
	extra1: Variant = null, extra2 := 0.0, extra3 := 0.0
) -> Vector2:
	match type:
		SplineType.CARDINAL:
			var e1 := extra1 as float
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cardinal_2D_vel(t, p0, p1, p2, p3, e1)
				SplineEvaluation.ACCELERATION:
					return spline_cardinal_2D_accel(t, p0, p1, p2, p3, e1)
				SplineEvaluation.JERK:
					return spline_cardinal_2D_jerk(t, p0, p1, p2, p3, e1)
				_:
					return spline_cardinal_2D(t, p0, p1, p2, p3, e1)
		SplineType.CATMULL_ROM:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_catmull_rom_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_catmull_rom_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_catmull_rom_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_catmull_rom_2D(t, p0, p1, p2, p3)
		SplineType.CUBIC_BEZIER:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_bezier_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_bezier_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_bezier_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_bezier_2D(t, p0, p1, p2, p3)
		SplineType.CUBIC_B_SPLINE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_b_spline_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_b_spline_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_b_spline_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_b_spline_2D(t, p0, p1, p2, p3)
		SplineType.HERMITE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_hermite_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_hermite_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_hermite_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_hermite_2D(t, p0, p1, p2, p3)
		SplineType.KOCHANEK_BARTELS:
			var e1 := extra1 as float
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_kochanek_bartels_2D_vel(t, p0, p1, p2, p3, e1, extra2, extra3)
				SplineEvaluation.ACCELERATION:
					return spline_kochanek_bartels_2D_accel(t, p0, p1, p2, p3, e1, extra2, extra3)
				SplineEvaluation.JERK:
					return spline_kochanek_bartels_2D_jerk(t, p0, p1, p2, p3, e1, extra2, extra3)
				_:
					return spline_kochanek_bartels_2D(t, p0, p1, p2, p3, e1, extra2, extra3)
		SplineType.BIARC_UNCACHED:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_biarc_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_biarc_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_biarc_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_biarc_2D(t, p0, p1, p2, p3)
		SplineType.BIARC_CACHED:
			var e1 := extra1 as Biarc2D
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_biarc_2D_vel_cached(t, p0, p1, p2, p3, e1)
				SplineEvaluation.ACCELERATION:
					return spline_biarc_2D_accel_cached(t, p0, p1, p2, p3, e1)
				SplineEvaluation.JERK:
					return spline_biarc_2D_jerk_cached(t, p0, p1, p2, p3, e1)
				_:
					return spline_biarc_2D_cached(t, p0, p1, p2, p3, e1)
	assert(false, "Unknown/unimplemented spline type!")
	return Vector2()

static func length_spline_2D(type: SplineType, t: float,
	p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	var result := 0.0
	var gauss_legendre_index := 0
	var num_gauss_legendre_coeffs := GAUSS_LEGENDRE_COEFFICIENTS.size() / 2
	
	while gauss_legendre_index < num_gauss_legendre_coeffs:
		var abscissa := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2]
		var weight   := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2 + 1]
		
		result += eval_spline_2D(type, SplineEvaluation.VELOCITY, t * 0.5 * (1.0 + abscissa), p0, p1, p2, p3, extra1, extra2, extra3).length() * t * weight
		
		gauss_legendre_index += 1
	
	return 0.5 * result

static func eval_rational_spline_2D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
	r0: float,   r1: float,   r2: float,   r3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> Vector2:
	var basis := eval_spline_1D(type, eval, t, r0, r1, r2, r3, extra1, extra2, extra3)
	
	if is_zero_approx(basis):
		basis = 1.0
	
	var result := eval_spline_2D(type, eval, t, p0 * r0, p1 * r1, p2 * r2, p3 * r3, extra1, extra2, extra3) / basis
	return result

static func eval_spline_3D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> Vector3:
	match type:
		SplineType.CARDINAL:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cardinal_3D_vel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.ACCELERATION:
					return spline_cardinal_3D_accel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.JERK:
					return spline_cardinal_3D_jerk(t, p0, p1, p2, p3, extra1)
				_:
					return spline_cardinal_3D(t, p0, p1, p2, p3, extra1)
		SplineType.CATMULL_ROM:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_catmull_rom_3D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_catmull_rom_3D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_catmull_rom_3D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_catmull_rom_3D(t, p0, p1, p2, p3)
		SplineType.CUBIC_BEZIER:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_bezier_3D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_bezier_3D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_bezier_3D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_bezier_3D(t, p0, p1, p2, p3)
		SplineType.CUBIC_B_SPLINE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_b_spline_3D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_b_spline_3D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_b_spline_3D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_b_spline_3D(t, p0, p1, p2, p3)
		SplineType.HERMITE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_hermite_3D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_hermite_3D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_hermite_3D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_hermite_3D(t, p0, p1, p2, p3)
		SplineType.KOCHANEK_BARTELS:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_kochanek_bartels_3D_vel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.ACCELERATION:
					return spline_kochanek_bartels_3D_accel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.JERK:
					return spline_kochanek_bartels_3D_jerk(t, p0, p1, p2, p3, extra1, extra2, extra3)
				_:
					return spline_kochanek_bartels_3D(t, p0, p1, p2, p3, extra1, extra2, extra3)
	assert(false, "Unknown/unimplemented spline type!")
	return Vector3()

static func length_spline_3D(type: SplineType, t: float,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	var result := 0.0
	var gauss_legendre_index := 0
	var num_gauss_legendre_coeffs := GAUSS_LEGENDRE_COEFFICIENTS.size() / 2
	
	while gauss_legendre_index < num_gauss_legendre_coeffs:
		var abscissa := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2]
		var weight   := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2 + 1]
		
		result += eval_spline_3D(type, SplineEvaluation.VELOCITY, t * 0.5 * (1.0 + abscissa), p0, p1, p2, p3, extra1, extra2, extra3).length() * t * weight
		
		gauss_legendre_index += 1
	
	return 0.5 * result

static func eval_rational_spline_3D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	r0: float,   r1: float,   r2: float,   r3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> Vector3:
	var basis := eval_spline_1D(type, eval, t, r0, r1, r2, r3, extra1, extra2, extra3)
	
	if is_zero_approx(basis):
		basis = 1.0
	
	var result := eval_spline_3D(type, eval, t, p0 * r0, p1 * r1, p2 * r2, p3 * r3, extra1, extra2, extra3) / basis
	return result

static func eval_spline_4D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> Vector4:
	match type:
		SplineType.CARDINAL:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cardinal_4D_vel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.ACCELERATION:
					return spline_cardinal_4D_accel(t, p0, p1, p2, p3, extra1)
				SplineEvaluation.JERK:
					return spline_cardinal_4D_jerk(t, p0, p1, p2, p3, extra1)
				_:
					return spline_cardinal_4D(t, p0, p1, p2, p3, extra1)
		SplineType.CATMULL_ROM:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_catmull_rom_4D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_catmull_rom_4D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_catmull_rom_4D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_catmull_rom_4D(t, p0, p1, p2, p3)
		SplineType.CUBIC_BEZIER:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_bezier_4D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_bezier_4D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_bezier_4D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_bezier_4D(t, p0, p1, p2, p3)
		SplineType.CUBIC_B_SPLINE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_cubic_b_spline_4D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_cubic_b_spline_4D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_cubic_b_spline_4D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_cubic_b_spline_4D(t, p0, p1, p2, p3)
		SplineType.HERMITE:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_hermite_4D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_hermite_4D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_hermite_4D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_hermite_4D(t, p0, p1, p2, p3)
		SplineType.KOCHANEK_BARTELS:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_kochanek_bartels_4D_vel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.ACCELERATION:
					return spline_kochanek_bartels_4D_accel(t, p0, p1, p2, p3, extra1, extra2, extra3)
				SplineEvaluation.JERK:
					return spline_kochanek_bartels_4D_jerk(t, p0, p1, p2, p3, extra1, extra2, extra3)
				_:
					return spline_kochanek_bartels_4D(t, p0, p1, p2, p3, extra1, extra2, extra3)
	assert(false, "Unknown/unimplemented spline type!")
	return Vector4()

static func length_spline_4D(type: SplineType, t: float,
	p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4,
	r0 := 1.0,   r1 := 1.0,   r2 := 1.0,   r3 := 1.0,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> float:
	var result := 0.0
	var gauss_legendre_index := 0
	var num_gauss_legendre_coeffs := GAUSS_LEGENDRE_COEFFICIENTS.size() / 2
	
	while gauss_legendre_index < num_gauss_legendre_coeffs:
		var abscissa := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2]
		var weight   := GAUSS_LEGENDRE_COEFFICIENTS[gauss_legendre_index * 2 + 1]
		
		result += eval_spline_4D(type, SplineEvaluation.VELOCITY, t * 0.5 * (1.0 + abscissa), p0, p1, p2, p3, extra1, extra2, extra3).length() * t * weight
		
		gauss_legendre_index += 1
	
	return 0.5 * result

static func eval_rational_spline_4D(type: SplineType, eval: SplineEvaluation, t: float,
	p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4,
	r0: float,   r1: float,   r2: float,   r3: float,
	extra1 := 0.0, extra2 := 0.0, extra3 := 0.0
) -> Vector4:
	var basis := eval_spline_1D(type, eval, t, r0, r1, r2, r3, extra1, extra2, extra3)
	
	if is_zero_approx(basis):
		basis = 1.0
	
	var result := eval_spline_4D(type, eval, t, p0 * r0, p1 * r1, p2 * r2, p3 * r3, extra1, extra2, extra3) / basis
	return result

# --------------------------------------------------------------------------------------------------
#region Cardinal
# --------------------------------------------------------------------------------------------------

static func spline_cardinal_1D(t: float, p0: float, p1: float, p2: float, p3: float, scale: float) -> float:
	var t_pow2 := t * t
	return (
		  p1
		+ (-scale * p0 + scale * p2) * t
		+ (2.0 * scale * p0 + (scale - 3.0) * p1 + (3.0 - 2.0 * scale) * p2 - scale * p3) * t_pow2
		+ (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3) * t_pow2 * t
	)
static func spline_cardinal_1D_vel(t: float, p0: float, p1: float, p2: float, p3: float, scale: float) -> float:
	var t_pow2 := t * t
	return (
		  scale * (4.0 * t - 3.0 * t_pow2 - 1.0) 							* p0
		+ t * (scale * (2.0 - 3.0 * t) + 6.0 * (t - 1.0)) 				* p1
		+ (scale * (t * (3.0 * t - 4.0) + 1.0) + 6.0 * t * (1.0 - t)) 	* p2
		+ scale * t * (3.0 * t - 2.0) 									* p3
	)
static func spline_cardinal_1D_accel(t: float, p0: float, p1: float, p2: float, p3: float, scale: float) -> float:
	return (
		  scale * (4.0 - 6.0 * t) 							* p0
		+ 2.0 * (scale * (1.0 - 3.0 * t) + 6.0 * t - 3.0) 	* p1
		+ 2.0 * (scale * (3.0 * t - 2.0) - 6.0 * t + 3.0) 	* p2
		+ 2.0 * scale * (3.0 * t - 1.0) 						* p3
	)
static func spline_cardinal_1D_jerk(_t: float, p0: float, p1: float, p2: float, p3: float, scale: float) -> float:
	return 6.0 * (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3)

static func spline_cardinal_2D(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, scale: float) -> Vector2:
	var t_pow2 := t * t
	return (
		  p1
		+ (-scale * p0 + scale * p2) * t
		+ (2.0 * scale * p0 + (scale - 3.0) * p1 + (3.0 - 2.0 * scale) * p2 - scale * p3) * t_pow2
		+ (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3) * t_pow2 * t
	)
static func spline_cardinal_2D_vel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, scale: float) -> Vector2:
	var t_pow2 := t * t
	return (
		  scale * (4.0 * t - 3.0 * t_pow2 - 1.0) 							* p0
		+ t * (scale * (2.0 - 3.0 * t) + 6.0 * (t - 1.0)) 				* p1
		+ (scale * (t * (3.0 * t - 4.0) + 1.0) + 6.0 * t * (1.0 - t)) 	* p2
		+ scale * t * (3.0 * t - 2.0) 									* p3
	)
static func spline_cardinal_2D_accel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, scale: float) -> Vector2:
	return (
		  scale * (4.0 - 6.0 * t) 							* p0
		+ 2.0 * (scale * (1.0 - 3.0 * t) + 6.0 * t - 3.0) 	* p1
		+ 2.0 * (scale * (3.0 * t - 2.0) - 6.0 * t + 3.0) 	* p2
		+ 2.0 * scale * (3.0 * t - 1.0) 						* p3
	)
static func spline_cardinal_2D_jerk(_t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, scale: float) -> Vector2:
	return 6.0 * (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3)

static func spline_cardinal_3D(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, scale: float) -> Vector3:
	var t_pow2 := t * t
	return (
		  p1
		+ (-scale * p0 + scale * p2) * t
		+ (2.0 * scale * p0 + (scale - 3.0) * p1 + (3.0 - 2.0 * scale) * p2 - scale * p3) * t_pow2
		+ (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3) * t_pow2 * t
	)
static func spline_cardinal_3D_vel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, scale: float) -> Vector3:
	var t_pow2 := t * t
	return (
		  scale * (4.0 * t - 3.0 * t_pow2 - 1.0) 							* p0
		+ t * (scale * (2.0 - 3.0 * t) + 6.0 * (t - 1.0)) 				* p1
		+ (scale * (t * (3.0 * t - 4.0) + 1.0) + 6.0 * t * (1.0 - t)) 	* p2
		+ scale * t * (3.0 * t - 2.0) 									* p3
	)
static func spline_cardinal_3D_accel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, scale: float) -> Vector3:
	return (
		  scale * (4.0 - 6.0 * t) 							* p0
		+ 2.0 * (scale * (1.0 - 3.0 * t) + 6.0 * t - 3.0) 	* p1
		+ 2.0 * (scale * (3.0 * t - 2.0) - 6.0 * t + 3.0) 	* p2
		+ 2.0 * scale * (3.0 * t - 1.0) 						* p3
	)
static func spline_cardinal_3D_jerk(_t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, scale: float) -> Vector3:
	return 6.0 * (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3)

static func spline_cardinal_4D(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, scale: float) -> Vector4:
	var t_pow2 := t * t
	return (
		  p1
		+ (-scale * p0 + scale * p2) * t
		+ (2.0 * scale * p0 + (scale - 3.0) * p1 + (3.0 - 2.0 * scale) * p2 - scale * p3) * t_pow2
		+ (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3) * t_pow2 * t
	)
static func spline_cardinal_4D_vel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, scale: float) -> Vector4:
	var t_pow2 := t * t
	return (
		  scale * (4.0 * t - 3.0 * t_pow2 - 1.0) 							* p0
		+ t * (scale * (2.0 - 3.0 * t) + 6.0 * (t - 1.0)) 				* p1
		+ (scale * (t * (3.0 * t - 4.0) + 1.0) + 6.0 * t * (1.0 - t)) 	* p2
		+ scale * t * (3.0 * t - 2.0) 									* p3
	)
static func spline_cardinal_4D_accel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, scale: float) -> Vector4:
	return (
		  scale * (4.0 - 6.0 * t) 							* p0
		+ 2.0 * (scale * (1.0 - 3.0 * t) + 6.0 * t - 3.0) 	* p1
		+ 2.0 * (scale * (3.0 * t - 2.0) - 6.0 * t + 3.0) 	* p2
		+ 2.0 * scale * (3.0 * t - 1.0) 						* p3
	)
static func spline_cardinal_4D_jerk(_t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, scale: float) -> Vector4:
	return 6.0 * (-scale * p0 + (2.0 - scale) * p1 + (scale - 2.0) * p2 + scale * p3)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Catmull-Rom
# --------------------------------------------------------------------------------------------------

static func spline_catmull_rom_1D(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	var t_pow2 := t * t
	return 0.5 * (
		  (2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t_pow2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t_pow2 * t
	)
static func spline_catmull_rom_1D_vel(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	var t_pow2 := t * t
	
	return 0.5 * (
		-(3.0 * t_pow2 - 4.0 * t + 1) 	* p0
		+ (9.0 * t_pow2 - 10.0 * t) 		* p1
		- (9.0 * t_pow2 - 8.0 * t - 1.0) * p2
		+ (3.0 * t_pow2 - 2.0 * t) 		* p3
	)
static func spline_catmull_rom_1D_accel(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return (
		  (2.0 - 3.0 * t) * p0
		+ (9.0 * t - 5.0) * p1
		+ (4.0 - 9.0 * t) * p2
		+ (3.0 * t - 1.0) * p3
	)
static func spline_catmull_rom_1D_jerk(_t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return -3.0 * (
		  p0
		+ 3.0 * p1
		+ 3.0 * p2
		- p3
	)

static func spline_catmull_rom_2D(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var t_pow2 := t * t
	return 0.5 * (
		  (2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t_pow2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t_pow2 * t
	)
static func spline_catmull_rom_2D_vel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var t_pow2 := t * t
	
	return 0.5 * (
		-(3.0 * t_pow2 - 4.0 * t + 1) 	* p0
		+ (9.0 * t_pow2 - 10.0 * t) 		* p1
		- (9.0 * t_pow2 - 8.0 * t - 1.0) * p2
		+ (3.0 * t_pow2 - 2.0 * t) 		* p3
	)
static func spline_catmull_rom_2D_accel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return (
		  (2.0 - 3.0 * t) * p0
		+ (9.0 * t - 5.0) * p1
		+ (4.0 - 9.0 * t) * p2
		+ (3.0 * t - 1.0) * p3
	)
static func spline_catmull_rom_2D_jerk(_t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return -3.0 * (
		  p0
		+ 3.0 * p1
		+ 3.0 * p2
		- p3
	)

static func spline_catmull_rom_3D(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	var t_pow2 := t * t
	return 0.5 * (
		  (2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t_pow2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t_pow2 * t
	)
static func spline_catmull_rom_3D_vel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	var t_pow2 := t * t
	
	return 0.5 * (
		-(3.0 * t_pow2 - 4.0 * t + 1) 	* p0
		+ (9.0 * t_pow2 - 10.0 * t) 		* p1
		- (9.0 * t_pow2 - 8.0 * t - 1.0) * p2
		+ (3.0 * t_pow2 - 2.0 * t) 		* p3
	)
static func spline_catmull_rom_3D_accel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return (
		  (2.0 - 3.0 * t) * p0
		+ (9.0 * t - 5.0) * p1
		+ (4.0 - 9.0 * t) * p2
		+ (3.0 * t - 1.0) * p3
	)
static func spline_catmull_rom_3D_jerk(_t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return -3.0 * (
		  p0
		+ 3.0 * p1
		+ 3.0 * p2
		- p3
	)

static func spline_catmull_rom_4D(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	var t_pow2 := t * t
	return 0.5 * (
		  (2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t_pow2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t_pow2 * t
	)
static func spline_catmull_rom_4D_vel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	var t_pow2 := t * t
	
	return 0.5 * (
		-(3.0 * t_pow2 - 4.0 * t + 1) 	* p0
		+ (9.0 * t_pow2 - 10.0 * t) 		* p1
		- (9.0 * t_pow2 - 8.0 * t - 1.0) * p2
		+ (3.0 * t_pow2 - 2.0 * t) 		* p3
	)
static func spline_catmull_rom_4D_accel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return (
		  (2.0 - 3.0 * t) * p0
		+ (9.0 * t - 5.0) * p1
		+ (4.0 - 9.0 * t) * p2
		+ (3.0 * t - 1.0) * p3
	)
static func spline_catmull_rom_4D_jerk(_t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return -3.0 * (
		  p0
		+ 3.0 * p1
		+ 3.0 * p2
		- p3
	)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Cubic Beziér
# --------------------------------------------------------------------------------------------------

static func spline_cubic_bezier_1D(t: float, p0: float, p1: float, p2: float, p3: float, r0 := 1.0, r1 := 1.0, r2 := 1.0, r3 := 1.0) -> float:
	var u := 1.0 - t
	var u_pow2 := u * u
	var t_pow2 := t * t
	
	return (
		  u_pow2 * u 		* p0
		+ 3.0 * u_pow2 * t 	* p1
		+ 3.0 * u * t_pow2 	* p2
		+ t_pow2 * t 		* p3
	)
static func spline_cubic_bezier_1D_vel(t: float, p0: float, p1: float, p2: float, p3: float, r0 := 1.0, r1 := 1.0, r2 := 1.0, r3 := 1.0) -> float:
	var u := 1.0 - t
	return 3.0 * (
		  u * u 			* (p1 - p0)
		+ 2.0 * u * t 	* (p2 - p1)
		+ t * t 			* (p3 - p2)
	)
static func spline_cubic_bezier_1D_accel(t: float, p0: float, p1: float, p2: float, p3: float, r0 := 1.0, r1 := 1.0, r2 := 1.0, r3 := 1.0) -> float:
	var u := 1.0 - t
	return 6.0 * (
		  u * (p2 - 2.0 * p1 + p0)
		+ t * (p3 - 2.0 * p2 + p1)
	)
static func spline_cubic_bezier_1D_jerk(_t: float, p0: float, p1: float, p2: float, p3: float, r0 := 1.0, r1 := 1.0, r2 := 1.0, r3 := 1.0) -> float:
	return 6.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)

static func spline_cubic_bezier_2D(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var u := 1.0 - t
	var u_pow2 := u * u
	var t_pow2 := t * t
	
	return (
		  u_pow2 * u 		* p0
		+ 3.0 * u_pow2 * t 	* p1
		+ 3.0 * u * t_pow2 	* p2
		+ t_pow2 * t 		* p3
	)
static func spline_cubic_bezier_2D_vel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var u := 1.0 - t
	return 3.0 * (
		  u * u 			* (p1 - p0)
		+ 2.0 * u * t 	* (p2 - p1)
		+ t * t 			* (p3 - p2)
	)
static func spline_cubic_bezier_2D_accel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var u := 1.0 - t
	return 6.0 * (
		  u * (p2 - 2.0 * p1 + p0)
		+ t * (p3 - 2.0 * p2 + p1)
	)
static func spline_cubic_bezier_2D_jerk(_t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return 6.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)

static func spline_cubic_bezier_3D(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	var u := 1.0 - t
	var u_pow2 := u * u
	var t_pow2 := t * t
	
	return (
		  u_pow2 * u 		* p0
		+ 3.0 * u_pow2 * t 	* p1
		+ 3.0 * u * t_pow2 	* p2
		+ t_pow2 * t 		* p3
	)
static func spline_cubic_bezier_3D_vel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	var u := 1.0 - t
	return 3.0 * (
		  u * u 			* (p1 - p0)
		+ 2.0 * u * t 	* (p2 - p1)
		+ t * t 			* (p3 - p2)
	)
static func spline_cubic_bezier_3D_accel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	var u := 1.0 - t
	return 6.0 * (
		  u * (p2 - 2.0 * p1 + p0)
		+ t * (p3 - 2.0 * p2 + p1)
	)
static func spline_cubic_bezier_3D_jerk(_t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return 6.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)

static func spline_cubic_bezier_4D(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	var u := 1.0 - t
	var u_pow2 := u * u
	var t_pow2 := t * t
	
	return (
		  u_pow2 * u 		* p0
		+ 3.0 * u_pow2 * t 	* p1
		+ 3.0 * u * t_pow2 	* p2
		+ t_pow2 * t 		* p3
	)
static func spline_cubic_bezier_4D_vel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	var u := 1.0 - t
	return 3.0 * (
		  u * u 			* (p1 - p0)
		+ 2.0 * u * t 	* (p2 - p1)
		+ t * t 			* (p3 - p2)
	)
static func spline_cubic_bezier_4D_accel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	var u := 1.0 - t
	return 6.0 * (
		  u * (p2 - 2.0 * p1 + p0)
		+ t * (p3 - 2.0 * p2 + p1)
	)
static func spline_cubic_bezier_4D_jerk(_t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return 6.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Cubic B-Spline
# --------------------------------------------------------------------------------------------------

static func spline_cubic_b_spline_1D(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return spline_cubic_bezier_1D(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_1D_vel(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return spline_cubic_bezier_1D_vel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_1D_accel(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return spline_cubic_bezier_1D_accel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_1D_jerk(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
	return spline_cubic_bezier_1D_jerk(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)

static func spline_cubic_b_spline_2D(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return spline_cubic_bezier_2D(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_2D_vel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return spline_cubic_bezier_2D_vel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_2D_accel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return spline_cubic_bezier_2D_accel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_2D_jerk(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	return spline_cubic_bezier_2D_jerk(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)

static func spline_cubic_b_spline_3D(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return spline_cubic_bezier_3D(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_3D_vel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return spline_cubic_bezier_3D_vel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_3D_accel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return spline_cubic_bezier_3D_accel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_3D_jerk(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> Vector3:
	return spline_cubic_bezier_3D_jerk(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)

static func spline_cubic_b_spline_4D(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return spline_cubic_bezier_4D(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_4D_vel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return spline_cubic_bezier_4D_vel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_4D_accel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return spline_cubic_bezier_4D_accel(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)
static func spline_cubic_b_spline_4D_jerk(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4) -> Vector4:
	return spline_cubic_bezier_4D_jerk(t,
		_ONE_SIXTH * (p0 + 4.0 * p1 + p2),
		_ONE_THIRD * (2.0 * p1 + p2),
		_ONE_THIRD * (p1 + 2.0 * p2),
		_ONE_SIXTH * (p1 + 4.0 * p2 + p3)
	)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Hermite
# --------------------------------------------------------------------------------------------------

static func spline_hermite_1D(t: float, p0: float, v0: float, p1: float, v1: float) -> float:
	var t_pow2 := t * t
	var t_pow3 := t_pow2 * t
	return (
		  (2.0 * t_pow3 - 3.0 * t_pow2 + 1.0) 	* p0
		+ (t_pow3 - 2.0 * t_pow2 + t) 			* v0
		+ (-2.0 * t_pow3 + 3.0 * t_pow2) 		* p1
		+ (t_pow3 - t_pow2) 						* v1
	)
static func spline_hermite_1D_vel(t: float, p0: float, v0: float, p1: float, v1: float) -> float:
	var u := 1.0 - t
	var t_pow2 := t * t
	
	return (
		  v0
		+ 6.0 * u * t * (p0 - p1)
		+ 3.0 * t_pow2 * (v0 + v1)
		- 2.0 * t * (2.0 * v0 + v1)
	)
static func spline_hermite_1D_accel(t: float, p0: float, v0: float, p1: float, v1: float) -> float:
	var t_times2 := 2.0 * t
	
	return 6.0 * (
		  (t_times2 - 1.0) * p0
		+ (1.0 - t_times2) * p1
		+ t * (v0 + v1)
		- _TWO_THIRDS * v0 - _ONE_THIRD * v1
	)
static func spline_hermite_1D_jerk(_t: float, p0: float, v0: float, p1: float, v1: float) -> float:
	return 6.0 * (2.0 * p0 - 2.0 * p1 + v0 + v1)

static func spline_hermite_2D(t: float, p0: Vector2, v0: Vector2, p1: Vector2, v1: Vector2) -> Vector2:
	var t_pow2 := t * t
	var t_pow3 := t_pow2 * t
	return (
		  (2.0 * t_pow3 - 3.0 * t_pow2 + 1.0) 	* p0
		+ (t_pow3 - 2.0 * t_pow2 + t) 			* v0
		+ (-2.0 * t_pow3 + 3.0 * t_pow2) 		* p1
		+ (t_pow3 - t_pow2) 						* v1
	)
static func spline_hermite_2D_vel(t: float, p0: Vector2, v0: Vector2, p1: Vector2, v1: Vector2) -> Vector2:
	var u := 1.0 - t
	var t_pow2 := t * t
	
	return (
		  v0
		+ 6.0 * u * t * (p0 - p1)
		+ 3.0 * t_pow2 * (v0 + v1)
		- 2.0 * t * (2.0 * v0 + v1)
	)
static func spline_hermite_2D_accel(t: float, p0: Vector2, v0: Vector2, p1: Vector2, v1: Vector2) -> Vector2:
	var t_times2 := 2.0 * t
	
	return 6.0 * (
		  (t_times2 - 1.0) * p0
		+ (1.0 - t_times2) * p1
		+ t * (v0 + v1)
		- _TWO_THIRDS * v0 - _ONE_THIRD * v1
	)
static func spline_hermite_2D_jerk(_t: float, p0: Vector2, v0: Vector2, p1: Vector2, v1: Vector2) -> Vector2:
	return 6.0 * (2.0 * p0 - 2.0 * p1 + v0 + v1)

static func spline_hermite_3D(t: float, p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3) -> Vector3:
	var t_pow2 := t * t
	var t_pow3 := t_pow2 * t
	return (
		  (2.0 * t_pow3 - 3.0 * t_pow2 + 1.0) 	* p0
		+ (t_pow3 - 2.0 * t_pow2 + t) 			* v0
		+ (-2.0 * t_pow3 + 3.0 * t_pow2) 		* p1
		+ (t_pow3 - t_pow2) 						* v1
	)
static func spline_hermite_3D_vel(t: float, p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3) -> Vector3:
	var u := 1.0 - t
	var t_pow2 := t * t
	
	return (
		  v0
		+ 6.0 * u * t * (p0 - p1)
		+ 3.0 * t_pow2 * (v0 + v1)
		- 2.0 * t * (2.0 * v0 + v1)
	)
static func spline_hermite_3D_accel(t: float, p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3) -> Vector3:
	var t_times2 := 2.0 * t
	
	return 6.0 * (
		  (t_times2 - 1.0) * p0
		+ (1.0 - t_times2) * p1
		+ t * (v0 + v1)
		- _TWO_THIRDS * v0 - _ONE_THIRD * v1
	)
static func spline_hermite_3D_jerk(_t: float, p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3) -> Vector3:
	return 6.0 * (2.0 * p0 - 2.0 * p1 + v0 + v1)

static func spline_hermite_4D(t: float, p0: Vector4, v0: Vector4, p1: Vector4, v1: Vector4) -> Vector4:
	var t_pow2 := t * t
	var t_pow3 := t_pow2 * t
	return (
		  (2.0 * t_pow3 - 3.0 * t_pow2 + 1.0) 	* p0
		+ (t_pow3 - 2.0 * t_pow2 + t) 			* v0
		+ (-2.0 * t_pow3 + 3.0 * t_pow2) 		* p1
		+ (t_pow3 - t_pow2) 						* v1
	)
static func spline_hermite_4D_vel(t: float, p0: Vector4, v0: Vector4, p1: Vector4, v1: Vector4) -> Vector4:
	var u := 1.0 - t
	var t_pow2 := t * t
	
	return (
		  v0
		+ 6.0 * u * t * (p0 - p1)
		+ 3.0 * t_pow2 * (v0 + v1)
		- 2.0 * t * (2.0 * v0 + v1)
	)
static func spline_hermite_4D_accel(t: float, p0: Vector4, v0: Vector4, p1: Vector4, v1: Vector4) -> Vector4:
	var t_times2 := 2.0 * t
	
	return 6.0 * (
		  (t_times2 - 1.0) * p0
		+ (1.0 - t_times2) * p1
		+ t * (v0 + v1)
		- _TWO_THIRDS * v0 - _ONE_THIRD * v1
	)
static func spline_hermite_4D_jerk(_t: float, p0: Vector4, v0: Vector4, p1: Vector4, v1: Vector4) -> Vector4:
	return 6.0 * (2.0 * p0 - 2.0 * p1 + v0 + v1)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Kochanek-Bartels
# --------------------------------------------------------------------------------------------------

## Evaluates a segment of a 1-dimensional Kochanek-Bartels spline at position [param t] (usually in the range [code][0, 1][/code]).[br][br]
## [param tension] changes the length of the computed tangent vectors. Usually within the range [code][-1, 1][/code], (round to tight corners).[br]
## [param bias] changes the direction of the computed tangent vectors. Usually within the range [code][-1, 1][/code], (pre- to post-shooting the knots).[br]
## [param continuity] changes the sharpness in change between tangents. Usually within the range [code][-1, 1][/code], (boxed to inverted corners).[br]
static func spline_kochanek_bartels_1D(t: float, p0: float, p1: float, p2: float, p3: float, tension: float, bias: float, continuity: float) -> float:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_1D(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_1D_vel(t: float, p0: float, p1: float, p2: float, p3: float, tension: float, bias: float, continuity: float) -> float:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_1D_vel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_1D_accel(t: float, p0: float, p1: float, p2: float, p3: float, tension: float, bias: float, continuity: float) -> float:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_1D_accel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_1D_jerk(t: float, p0: float, p1: float, p2: float, p3: float, tension: float, bias: float, continuity: float) -> float:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_1D_jerk(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)

static func spline_kochanek_bartels_2D(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, tension: float, bias: float, continuity: float) -> Vector2:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_2D(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_2D_vel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, tension: float, bias: float, continuity: float) -> Vector2:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_2D_vel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_2D_accel(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, tension: float, bias: float, continuity: float) -> Vector2:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_2D_accel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_2D_jerk(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, tension: float, bias: float, continuity: float) -> Vector2:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_2D_jerk(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)

static func spline_kochanek_bartels_3D(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, tension: float, bias: float, continuity: float) -> Vector3:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_3D(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_3D_vel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, tension: float, bias: float, continuity: float) -> Vector3:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_3D_vel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_3D_accel(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, tension: float, bias: float, continuity: float) -> Vector3:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_3D_accel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_3D_jerk(t: float, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, tension: float, bias: float, continuity: float) -> Vector3:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_3D_jerk(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)

static func spline_kochanek_bartels_4D(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, tension: float, bias: float, continuity: float) -> Vector4:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_4D(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_4D_vel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, tension: float, bias: float, continuity: float) -> Vector4:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_4D_vel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_4D_accel(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, tension: float, bias: float, continuity: float) -> Vector4:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_4D_accel(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)
static func spline_kochanek_bartels_4D_jerk(t: float, p0: Vector4, p1: Vector4, p2: Vector4, p3: Vector4, tension: float, bias: float, continuity: float) -> Vector4:
	var actual_tension := 1.0 - tension
	var add_bias := 1.0 + bias
	var sub_bias := 1.0 - bias
	var add_cont := 1.0 + continuity
	var sub_cont := 1.0 - continuity
	
	return spline_hermite_4D_jerk(t,
		p1,
		0.5 * (actual_tension * add_bias * add_cont) * (p1 - p0) + 0.5 * (actual_tension * sub_bias * sub_cont) * (p2 - p1),
		p2,
		0.5 * (actual_tension * add_bias * sub_cont) * (p2 - p1) + 0.5 * (actual_tension * sub_bias * add_cont) * (p3 - p2)
	)

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#region Biarc
# --------------------------------------------------------------------------------------------------

class Arc2D:
	var _point := Vector2()
	var _tangent := Vector2()
	var _center := Vector2()
	var _radius := 0.0
	var _angle := 0.0
	var _arclen := 0.0
	var _flipped := false
	
	func get_point() -> Vector2:
		return _point
	
	func get_tangent() -> Vector2:
		return _tangent
	
	func get_normal() -> Vector2:
		return Vector2(-_tangent.y, _tangent.x)
	
	func get_center() -> Vector2:
		return _center
	
	func get_radius() -> float:
		return _radius
	
	func get_angle() -> float:
		return _angle
	
	func get_arclength() -> float:
		return _arclen
	
	func get_flipped() -> bool:
		return _flipped
	
	func create_arc(start_point: Vector2, tangent: Vector2, endpoint: Vector2, flipped: bool) -> void:
		_point = start_point
		_tangent = tangent.normalized()
		_flipped = flipped
		
		var norm := get_normal()
		
		var pt_to_mid := endpoint - _point
		var scalar := pt_to_mid.dot(pt_to_mid) / (2.0 * norm.dot(pt_to_mid))
		
		_center = _point + scalar * norm
		_radius = _center.distance_to(_point)
		
		if is_zero_approx(_radius):
			_angle = 0.0
			_arclen = _point.distance_to(endpoint)
		else:
			var pt_rel_to_center := (_point   - _center) / _radius
			var md_rel_to_center := (endpoint - _center) / _radius
			
			var cross_z := _cross_product_z_2D(pt_rel_to_center, md_rel_to_center)
			var cross_z_positive := cross_z > 0.0
			
			_angle = acos(pt_rel_to_center.dot(md_rel_to_center)) * (1.0 * float(cross_z_positive) + -1.0 * float(not cross_z_positive))
			
			if _flipped:
				_angle = TAU * (-1.0 * float(cross_z_positive) + 1.0 * float(not cross_z_positive)) + _angle
			
			_arclen = absf(_angle * _radius)
	
	func prepare_for_semicircles(point: Vector2, tangent: Vector2, radius: float) -> void:
		_point = point
		_tangent = tangent
		_radius = radius
	
	func create_semicircles_with(other_arc: Arc2D, cross_z: float) -> void:
		_center				= _point.lerp(other_arc._point, 0.25)
		other_arc._center 	= _point.lerp(other_arc._point, 0.75)
		
		var cross_z_negative := cross_z < 0.0
		_angle = PI * (1.0 * float(cross_z_negative) + -1.0 * float(not cross_z_negative))
		
		var cross_z_positive := cross_z > 0.0
		other_arc._angle = PI * (1.0 * float(cross_z_positive) + -1.0 * float(not cross_z_positive))
	
	static func _cross_product_z_2D(a: Vector2, b: Vector2) -> float:
		return a.x * b.y - a.y * b.x

class Biarc2D:
	var arc0 := Arc2D.new()
	var arc1 := Arc2D.new()
	var midpoint := Vector2()
	var total_arclength: float:
		get:
			return arc0.get_arclength() + arc1.get_arclength()
	
	func _init(p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> void:
		calculate(p0, tan0, p1, tan1)
	
	func calculate(p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> void:
		tan0 = tan0.normalized()
		tan1 = tan1.normalized()
		
		var vel := p1 - p0
		
		if tan0.is_equal_approx(tan1) and is_zero_approx(vel.dot(tan1)):
			midpoint = p0.lerp(p1, 0.5)
			
			var radius := vel.length() * 0.25
			
			arc0.prepare_for_semicircles(p0, tan1, radius)
			arc1.prepare_for_semicircles(p1, tan1, radius)
			arc0.create_semicircles_with(arc1, Arc2D._cross_product_z_2D(vel, tan1))
			return
		
		var dist := 0.0
		
		if tan0.is_equal_approx(tan1):
			dist = vel.dot(vel) / (4.0 * vel.dot(tan1))
		else:
			var tan_sum := tan0 + tan1
			var vel_dot_tan_sum := vel.dot(tan_sum)
			var denominator := 2.0 * (1.0 - tan0.dot(tan1))
			dist = (-vel_dot_tan_sum + sqrt(vel_dot_tan_sum * vel_dot_tan_sum + denominator * vel.dot(vel))) / denominator
		
		var negative_dist := not (dist > 0.0)
		
		midpoint = 0.5 * (p0 + p1 + dist * (tan0 - tan1))
		
		arc0.create_arc(p0, tan0, midpoint, negative_dist)
		arc1.create_arc(p1, tan1, midpoint, negative_dist)
	
	func evaluate_position(t: float) -> Vector2:
		var result := Vector2()
		var cur_arclen := total_arclength * t
		
		if cur_arclen < arc0.get_arclength():
			if is_zero_approx(arc0.get_arclength()):
				result = midpoint
			else:
				var arc0_percent := cur_arclen / arc0.get_arclength()
				
				if is_zero_approx(arc0.get_radius()):
					result = arc0.get_center()
				else:
					var cur_angle := arc0.get_angle() * arc0_percent + (arc0.get_point() - arc0.get_center()).angle()
					result = arc0.get_center() + Vector2(cos(cur_angle), sin(cur_angle)) * arc0.get_radius()
		else:
			if is_zero_approx(arc1.get_arclength()):
				result = midpoint
			else:
				var arc1_percent := (cur_arclen - arc0.get_arclength()) / arc1.get_arclength()
				
				if is_zero_approx(arc1.get_radius()):
					result = arc1.get_center()
				else:
					var cur_angle := arc1.get_angle() * (1.0 - arc1_percent) + (arc1.get_point() - arc1.get_center()).angle()
					result = arc1.get_center() + Vector2(cos(cur_angle), sin(cur_angle)) * arc1.get_radius()
		
		return result
	
	func evaluate_velocity(t: float) -> Vector2:
		return (evaluate_position(t + 0.0001) - evaluate_position(t)) / 0.0001
		# REMARK: There's likely an exact solution to this problem without having to evaluate position. WIP below.
		#region WIP Velocity
		#var result := Vector2()
		#var cur_arclen := total_arclength * t
		#var total_radii := arc0.get_point().distance_to(arc1.get_point())
		#
		#if cur_arclen < arc0.get_arclength():
			#if is_zero_approx(arc0.get_arclength()):
				#result = arc0.get_normal() * total_radii
			#else:
				#var arc0_percent := cur_arclen / arc0.get_arclength()
				#
				#if not is_zero_approx(arc0.get_radius()):
					#var cur_angle := arc0.get_angle() * arc0_percent + (arc0.get_point() - arc0.get_center()).angle()
					#result = arc0.get_normal().rotated(cur_angle) * total_radii
		#else:
			#if is_zero_approx(arc1.get_arclength()):
				#result = arc1.get_normal() * total_radii
			#else:
				#var arc1_percent := (cur_arclen - arc0.get_arclength()) / arc1.get_arclength()
				#
				#if not is_zero_approx(arc1.get_radius()):
					#var cur_angle := arc1.get_angle() * (1.0 - arc1_percent) + (arc1.get_point() - arc1.get_center()).angle()
					#result = arc1.get_normal().rotated(cur_angle) * total_radii
		 #
		#return result
		#endregion
	
	func evaluate_acceleration(t: float) -> Vector2:
		return (evaluate_velocity(t + 0.0001) - evaluate_velocity(t)) / 0.0001
	
	func evaluate_jerk(t: float) -> Vector2:
		return (evaluate_acceleration(t + 0.0001) - evaluate_acceleration(t)) / 0.0001
	
	func evaluate_length(t: float) -> float:
		var cur_dist := t * total_arclength
		
		if cur_dist < arc0.get_arclength():
			if is_zero_approx(arc0.get_arclength()):
				return 0.0
			return lerpf(0.0, arc0.get_arclength(), cur_dist / arc0.get_arclength())
		
		if is_zero_approx(arc1.get_arclength()):
			return arc0.get_arclength()
		return lerpf(arc0.get_arclength(), total_arclength, (cur_dist - arc0.get_arclength()) / arc1.get_arclength())

static func spline_biarc_2D(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.new(p0, tan0, p1, tan1).evaluate_position(t)

static func spline_biarc_2D_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_position(t)

static func spline_biarc_2D_vel(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.new(p0, tan0, p1, tan1).evaluate_velocity(t)

static func spline_biarc_2D_vel_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_velocity(t)

static func spline_biarc_2D_accel(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.new(p0, tan0, p1, tan1).evaluate_acceleration(t)

static func spline_biarc_2D_accel_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_acceleration(t)

static func spline_biarc_2D_jerk(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.new(p0, tan0, p1, tan1).evaluate_jerk(t)

static func spline_biarc_2D_jerk_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_jerk(t)

# TODO: 3D Biarc

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------
