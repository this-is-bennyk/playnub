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

class_name Condition
extends IndefiniteAction

## Waits for a condition to be [code]true[/code], then finishes.
## 
## Useful for blocking a multitude of actions from executing before an
## event occurs, like an input press or an in-game event.[br][br]
## [b]NOTE[/b]: The [member Action.target] [b]must[/b] be a [Callable] that
## returns a truthy or falsey value.[br]
## Examples below:
## [codeblock]
## func() -> bool: #...
## func() -> int: #...
## func() -> Object: #... (null is falsy)
## [/codeblock]

var _self_bind := false

## Sets whether the action should be passed as the first variable of the target
## [Callable] as determined by [param should_bind].
func binds_self(should_bind: bool) -> Condition:
	_self_bind = should_bind
	return self

func indefinite_enter() -> void:
	if _self_bind:
		target = (target as Callable).bind(self)

func indefinite_update() -> void:
	if (target as Callable).call():
		finish()
