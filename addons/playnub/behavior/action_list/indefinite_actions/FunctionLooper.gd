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

class_name FunctionLooper
extends IndefiniteAction

## Calls a function via a [Callable] every time the update loop of this [Action] is reached.
## 
## Pass a [Callable] to [method Action.targets] to use this action:
## [codeblock]
## # Like this:
## FunctionLooper.new().targets(func() -> void: do_logic())
## # Or this:
## FunctionLooper.new().targets(my_func)
## # Or this:
## FunctionLooper.from(my_func)
## [/codeblock]

## Whether to pass this action as the first argument to the given [Callable].
var self_bind := false

## Sets [member self_bind].
func binds_self(should_bind := false) -> FunctionLooper:
	self_bind = should_bind
	return self

## Binds this action to the Callable if [member self_bind] is set to [code]true[/code].
func indefinite_enter() -> void:
	if self_bind:
		target = (target as Callable).bind(self)

## Executes the [Callable] given by the [member Action.target].
func indefinite_update() -> void:
	(target as Callable).call()

## Returns a [FunctionLooper] with the given [param callable] and with the created
## action bound to its arguments, if [param binds_action] is set to [code]true[/code].
static func from(callable: Callable, binds_action := false) -> FunctionLooper:
	var result := FunctionLooper.new()
	
	result.binds_self(binds_action).targets(callable)
	
	return result
