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

class_name InterpolationEquation
extends Resource

## A math equation defining an interpolation behavior for a [ControlCurve].
## 
## TODO

const T_VARIABLE: Array[String] = ["t"]

## The area to define the equation. [b]Must[/b] return a [float]. To use the input
## interpolant / percent / etc., use the variable [code]t[/code]. For example:
## [codeblock]
## sin(t)
## [/codeblock]
## This expression is valid since [method @GlobalScope.sin] returns a [float]. It also uses
## the interpolant [code]t[/code].
@export_multiline
var expression_string := "":
	set(value):
		expression_string = value
		_expression.parse(expression_string, T_VARIABLE)
		emit_changed()

## Editor-only pseudo-console to let the designer know if there's any issues with compiling
## the equation.
## [b]NOTE[/b]: This doesn't guarantee that the equation will work if it's expecting
## a function from the [member base_instance].
@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var compilation := "":
	get:
		if not Engine.is_editor_hint():
			return ""
		
		var expr = Expression.new()
		var err := expr.parse(expression_string, T_VARIABLE)
		
		if err != OK:
			return str("Parsing error (", err, ", ", error_string(err), "): ", expr.get_error_text())
		
		var result := expr.execute([0.0], base_instance)
		
		if expr.has_execute_failed():
			return "Expression failed to execute.\n(The editor will produce errors in the output log until you fix this!)"
		
		if result is not float:
			return "Expression did not return a float."
		
		return "Expression compiled."

## An object whose functions / members can be used in the equation. For advanced
## usage that can't be described in the single line an [Expression] allows for.
## See [Expression] or [url=https://docs.godotengine.org/en/stable/tutorials/scripting/evaluating_expressions.html]this tutorial[/url]
## (especially the comment by Agecaf).
var base_instance: Object = null:
	set(value):
		base_instance = value
		emit_changed()

var _expression := Expression.new()

## Transforms the interpolant [param t] and returns it.
func evaluate(t: float) -> float:
	var result := _expression.execute([t], base_instance)
	
	assert(not _expression.has_execute_failed(), "Expression failed to execute.")
	assert(result is float, "Expression did not return a float.")
	
	return result as float

func clone(deep := false) -> InterpolationEquation:
	return duplicate(deep) as InterpolationEquation
