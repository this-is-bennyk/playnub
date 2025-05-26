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

@icon("uid://dx7jrq8bkskvj")
class_name Envelope
extends ControlCurve

## A control curve with a finite duration and delay.
## 
## Based on the music/design terms "envelope" and "ADSR" (Attack, Decay, Sustain,
## Release), this gives the control curve a boundary of time to be within, and is
## best for hands-on design in most instances.

@export_group("Time")

## How long the envelope should last.
@export_range(0.0001, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:sec")
var duration := 0.0001

## How long the envelope should wait before beginning.
@export_range(0.0, 1.0, 0.0001, "hide_slider", "or_greater", "suffix:sec")
var delay := 0.0

## Creates an [Interpolator] action controlled by the underlying [ControlCurve]
## lasting [member duration] seconds after [member delay] seconds of delay. It assumes that
## at least the [member ControlCurve.end] is defined.
func create_interpolator() -> Interpolator:
	var interpolator := Interpolator.new().controlled_by(self)
	
	interpolator.lasts(duration).after(delay)
	
	return interpolator
