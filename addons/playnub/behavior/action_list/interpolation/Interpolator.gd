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

@icon("uid://bouj1k3h6vh3k")
class_name Interpolator
extends Action

## Performs an interpolation on a value over time as an [Action].
##
## One of the most important and used functionality in a game is to change a value over time.
## This can include character movement, value changes, animations, transitions, and more.
## Despite this, the solution to such a foundational concept in game engines is either
## found in baked animations or manually coded logic, and is hard to reuse. Godot's
## [Animation] and [Tween] systems are fantastic, yet still not as flexible, general-purpose,
## and dynamic as one might need to make a video game or other kind of sufficiently complex
## program. The [Interpolator] can interpolate [b]any[/b] value in the engine and in your game
## via the [Box] with any kind of motion via the [ControlCurve] or the [Envelope].

var control_curve: ControlCurve = null
var relative := true

func controlled_by(_control_curve: ControlCurve) -> Interpolator:
	control_curve = _control_curve
	return self

func starts_absolute() -> Interpolator:
	relative = false
	return self

func enter() -> void:
	if relative:
		control_curve.start = Box.new((target as Box).data)

func update() -> void:
	(target as Box).data = get_current_value()

func get_current_value() -> Variant:
	return control_curve.at(get_interpolation())
