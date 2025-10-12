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
	
	, AUTO_BIARC_UNCACHED
	, AUTO_BIARC_CACHED
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
		SplineType.AUTO_BIARC_UNCACHED:
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_auto_biarc_2D_vel(t, p0, p1, p2, p3)
				SplineEvaluation.ACCELERATION:
					return spline_auto_biarc_2D_accel(t, p0, p1, p2, p3)
				SplineEvaluation.JERK:
					return spline_auto_biarc_2D_jerk(t, p0, p1, p2, p3)
				_:
					return spline_auto_biarc_2D(t, p0, p1, p2, p3)
		SplineType.AUTO_BIARC_CACHED:
			var e1 := extra1 as Biarc2D
			match eval:
				SplineEvaluation.VELOCITY:
					return spline_auto_biarc_2D_vel_cached(t, p0, p1, p2, p3, e1)
				SplineEvaluation.ACCELERATION:
					return spline_auto_biarc_2D_accel_cached(t, p0, p1, p2, p3, e1)
				SplineEvaluation.JERK:
					return spline_auto_biarc_2D_jerk_cached(t, p0, p1, p2, p3, e1)
				_:
					return spline_auto_biarc_2D_cached(t, p0, p1, p2, p3, e1)
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

class Biarc2D:
	var p0   := Vector2()
	var tan0 := Vector2()
	var p1   := Vector2()
	var tan1 := Vector2()
	
	var midpoint := Vector2()
	var center0  := Vector2()
	var center1  := Vector2()
	var radius0  := 0.0
	var radius1  := 0.0
	var angle0   := 0.0
	var angle1   := 0.0
	var arclen0  := 0.0
	var arclen1  := 0.0
	
	static func _biarc_cross_product_z_for_2D(a: Vector2, b: Vector2) -> float:
		return a.x * b.y - a.y * b.x
	
	static func create_auto(point0: Vector2, tangent0: Vector2, point1: Vector2, tangent1: Vector2) -> Biarc2D:
		var result := Biarc2D.new()
		
		result.p0 = point0
		result.p1 = point1
		
		result.tan0 = tangent0.normalized()
		result.tan1 = tangent1.normalized()
		
		var norm0 := Vector2(-result.tan0.y, result.tan0.x)
		var norm1 := Vector2(-result.tan1.y, result.tan0.x)
		
		var vel := result.p1 - result.p0
		var vel_dot_vel := vel.dot(vel)
		
		if is_zero_approx(vel_dot_vel):
			result.center0 = result.p0
			result.center1 = result.p1
			
			return result
		
		if result.tan0.is_equal_approx(result.tan1) and is_zero_approx(vel.dot(result.tan0)):
			result.midpoint = result.p0 + 0.5 * vel
			result.center0 =  result.p0.lerp(result.p1, 0.25)
			result.center1 =  result.p0.lerp(result.p1, 0.75)
			result.radius0 =  0.25 * vel.length()
			result.radius1 =  result.radius1
			
			var cross_z := _biarc_cross_product_z_for_2D(vel, result.tan1)
			var cross_z_negative := cross_z < 0.0
			var cross_z_positive := cross_z > 0.0
			
			result.angle0 = PI * (1.0 * float(cross_z_negative) + -1.0 * float(not cross_z_negative))
			result.angle1 = PI * (1.0 * float(cross_z_positive) + -1.0 * float(not cross_z_positive))
			
			result.arclen0 = PI * result.radius0
			result.arclen1 = PI * result.radius1
			
			return result
		
		var dist := 0.0
		var tan0_dot_tan1 := result.tan0.dot(result.tan1)
		var one_min_t0_dot_t1 := 1.0 - tan0_dot_tan1
		var vel_dot_tan1 := vel.dot(result.tan1)
		
		if is_zero_approx(tan0_dot_tan1):
			dist = vel_dot_vel / (4.0 * vel_dot_tan1)
		else:
			var tan_sum := result.tan0 + result.tan1
			var vel_dot_tan_sum := vel.dot(tan_sum)
			dist = (-vel_dot_tan_sum + sqrt(vel_dot_tan_sum * vel_dot_tan_sum + 2.0 * one_min_t0_dot_t1 * vel_dot_vel)) / (2.0 * one_min_t0_dot_t1)
		
		result.midpoint = 0.5 * (result.p0 + result.p1 + dist * (result.tan0 - result.tan1))
		
		var vec_p0_to_mdp := result.midpoint - result.p0
		var scalar0 := vec_p0_to_mdp.dot(vec_p0_to_mdp) / (2.0 * norm0.dot(vec_p0_to_mdp))
		
		var vec_p1_to_mdp := result.midpoint - result.p1
		var scalar1 := vec_p1_to_mdp.dot(vec_p1_to_mdp) / (2.0 * norm1.dot(vec_p1_to_mdp))
		
		result.center0 = result.p0 + scalar0 * norm0
		result.center1 = result.p1 + scalar1 * norm1
		result.radius0 = absf(scalar0)
		result.radius1 = absf(scalar1)
		
		var p0_rel_to_circle0  := (result.p0 - result.center0) / result.radius0
		var mdp_rel_to_circle0 := (result.midpoint - result.center0) / result.radius0
		var p1_rel_to_circle1  := (result.p1 - result.center1) / result.radius1
		var mdp_rel_to_circle1 := (result.midpoint - result.center1) / result.radius1
		
		var cross_z0_positive := _biarc_cross_product_z_for_2D(p0_rel_to_circle0, mdp_rel_to_circle0) > 0.0
		var cross_z1_positive := _biarc_cross_product_z_for_2D(p1_rel_to_circle1, mdp_rel_to_circle1) > 0.0
		
		var arc0 := acos(p0_rel_to_circle0.dot(mdp_rel_to_circle0))
		var arc1 := acos(p1_rel_to_circle1.dot(mdp_rel_to_circle1))
		
		result.angle0 = arc0 * (1.0 * float(cross_z0_positive) + -1.0 * float(not cross_z0_positive))
		result.angle1 = arc1 * (1.0 * float(cross_z1_positive) + -1.0 * float(not cross_z1_positive))
		
		if dist < 0.0:
			var tau0 := TAU * (-1.0 * float(cross_z0_positive) + 1.0 * float(cross_z0_positive))
			var tau1 := TAU * (-1.0 * float(cross_z1_positive) + 1.0 * float(cross_z1_positive))
			
			result.angle0 = tau0 + result.angle0
			result.angle1 = tau1 + result.angle1
		
		result.arclen0 = (result.midpoint - result.p0).length() if result.radius0 == 0.0 else absf(result.radius0 * result.angle0)
		result.arclen1 = (result.midpoint - result.p1).length() if result.radius1 == 0.0 else absf(result.radius1 * result.angle1)
		
		return result
	
	func evaluate_position(t: float) -> Vector2:
		var total_dist := arclen0 + arclen1
		var cur_dist := t * total_dist
		
		if cur_dist < arclen0:
			if is_zero_approx(arclen0):
				return p0
			
			var arc0_percent := cur_dist / arclen0
			
			if radius0 == 0.0:
				return p0.lerp(midpoint, arc0_percent)
			
			var cur_angle := angle0 * arc0_percent
			
			return center0 + Vector2(cos(cur_angle), sin(cur_angle)) * radius0
		
		if is_zero_approx(arclen1):
			return midpoint
		
		var arc1_percent := (cur_dist - arclen0) / arclen1
		
		if radius1 == 0.0:
			return midpoint.lerp(p1, arc1_percent)
		
		var cur_angle := angle1 * (1.0 - arc1_percent)
		
		return center1 + Vector2(cos(cur_angle), sin(cur_angle)) * radius1
	
	func evaluate_velocity(t: float) -> Vector2:
		return (evaluate_position(t + SPLINES_EPSILON) - evaluate_position(t)) / SPLINES_EPSILON
	
	func evaluate_acceleration(t: float) -> Vector2:
		return (evaluate_velocity(t + SPLINES_EPSILON) - evaluate_velocity(t)) / SPLINES_EPSILON
	
	func evaluate_jerk(t: float) -> Vector2:
		return (evaluate_acceleration(t + SPLINES_EPSILON) - evaluate_acceleration(t)) / SPLINES_EPSILON
	
	func evaluate_length(t: float) -> float:
		var total_dist := arclen0 + arclen1
		var cur_dist := t * total_dist
		
		if cur_dist < arclen0:
			if is_zero_approx(arclen0):
				return 0.0
			return lerpf(0.0, arclen0, cur_dist / arclen0)
		
		if is_zero_approx(arclen1):
			return arclen0
		return lerpf(arclen0, total_dist, (cur_dist - arclen0) / arclen1)

static func spline_auto_biarc_2D(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.create_auto(p0, tan0, p1, tan1).evaluate_position(t)

static func spline_auto_biarc_2D_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_position(t)

static func spline_auto_biarc_2D_vel(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.create_auto(p0, tan0, p1, tan1).evaluate_velocity(t)

static func spline_auto_biarc_2D_vel_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_velocity(t)

static func spline_auto_biarc_2D_accel(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.create_auto(p0, tan0, p1, tan1).evaluate_acceleration(t)

static func spline_auto_biarc_2D_accel_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_acceleration(t)

static func spline_auto_biarc_2D_jerk(t: float, p0: Vector2, tan0: Vector2, p1: Vector2, tan1: Vector2) -> Vector2:
	return Biarc2D.create_auto(p0, tan0, p1, tan1).evaluate_jerk(t)

static func spline_auto_biarc_2D_jerk_cached(t: float, _p0: Vector2, _tan0: Vector2, _p1: Vector2, _tan1: Vector2, biarc: Biarc2D) -> Vector2:
	return biarc.evaluate_jerk(t)

# TODO: 3D Biarc

# --------------------------------------------------------------------------------------------------
#endregion
# --------------------------------------------------------------------------------------------------
