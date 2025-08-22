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

@icon("uid://icbbhjlyokr6")
class_name FunctionCaller
extends InstantAction

## Calls a function one time via a [Callable] when this action is reached.
## 
## Pass a [Callable] to [method Action.targets] to use this action:
## [codeblock]
## # Like this:
## FunctionCaller.new().targets(func() -> void: do_logic())
## # Or this:
## FunctionCaller.new().targets(my_func)
## # Or this:
## FunctionCaller.from(my_func)
## [/codeblock]

## Whether to pass this action as the first argument to the given [Callable].
var self_bind := false

## Sets [member self_bind].
func binds_self(should_bind := false) -> FunctionCaller:
	self_bind = should_bind
	return self

## Binds this action to the Callable if [member self_bind] is set to [code]true[/code].
func enter() -> void:
	super()
	_bind()

## Executes the [Callable] given by the [member Action.target].
func update() -> void:
	(target as Callable).call()

## Binds this action to the Callable if [member self_bind] is set to [code]true[/code].
func exit() -> void:
	super()
	_bind()

func _bind() -> void:
	if self_bind and (target as Callable).get_bound_arguments_count() < 1:
		target = (target as Callable).bind(self)

## Returns a [FunctionCaller] with the given [param callable] and with the created
## action bound to its arguments, if [param binds_action] is set to [code]true[/code].
static func from(callable: Callable, binds_action := false) -> FunctionCaller:
	var result := FunctionCaller.new()
	
	result.binds_self(binds_action).targets(callable)
	
	return result
