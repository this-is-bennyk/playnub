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

@icon("uid://xxpo088ohenh")
class_name InstantAction
extends Action

## An action that happens instantaneously, i.e. that has no duration.
## 
## Code is generally meant to be executed in a linear order as described by the programmer.
## Unfortunately, game actions are often not linear. They often take time that can be modified
## or interrupted at any time, and events that are not time-dependent, that is, they execute immediately
## when called, are cumbersome to mix into these time-bound events. The [InstantAction] allows for
## this much more easily, by letting programmers and designers insert immediate events and/or logic
## to be organized with and manipulated by time-bound [Action]s and [IndefiniteAction]s.

## Initializes the instant action to have a duration of zero.
func _init() -> void:
	duration.reset()

## Overrides [method Action.lasts] to not affect [member Action.duration].
func lasts(_duration_sec: Playhead = null) -> Action:
	duration.reset()
	return self

## Forces the action to be over as soon as it's entered.
## Use [method Action.update] to process your logic.
func enter() -> void:
	finish()

## Overrides [method Action.done] to only be done once the logic is executed.
func done() -> bool:
	return _done
