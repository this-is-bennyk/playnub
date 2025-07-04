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

class_name SignalAwaiter
extends IndefiniteAction

## Waits for a [Signal] to emit, then finishes.
## 
## [b][u]CAUTION[/u]: This class's implementation requires Godot 4.5 with its
## variadic argument implementation in GDScript. It will be finished when Godot 4.5
## goes into a beta with a stable feature set.[/b][br][br]
## Useful for creating sequences of events that occur based on events that
## happen in-engine or in-game that emit signals.
## 
## @experimental

#var _connect_flags := 0
#var _end_condition := Callable()
#var _binds_self_to_end_cond := false

#func emission_deferred()
#func emission_one_shot()
#func emission_refcounted()
#func depends_on(condition: Callable, binds_action := false)

#func indefinite_enter() -> void:
	#if _binds_self_to_end_cond:
		#assert(_end_condition.is_valid(), "No condition Callable to bind this action to!")
		#_end_condition = _end_condition.bind(self)
	#(target as Signal).connect(_event_occurred)

#func _event_occurred(...: Array) -> void:
	#if (not _end_condition.is_valid()) or _end_condition.call():
		#finish()
