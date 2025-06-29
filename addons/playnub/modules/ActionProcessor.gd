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

class_name ActionProcessor
extends Module

## Manages the collection and processing of [ActionList]s in update loops.
## 
## Manually creating, executing, organizing, and intertwining discrete and
## continuous logic in a game object's update loops (ex. Godot's [Node] and
## [method Node._process] / [method Node._physics_process]) is always cumbersome.
## The [ActionProcessor] simplifies this by abstracting out the update loops
## using [ActionList]s and allows for complex logic to be manipulated in the
## aforementioned ways by adding [Action]s of any kind to them.[br][br]
## One can think of this as an "actor" class, similar to other game engines, but
## unlike the actors in other engines, an "action processor" is more generic and
## can be applied to objects not necessarily part of the visible or audible game
## world (e.g. game systems, game UI, etc.).

var _action_lists: Array[ActionList] = []
var _action_list_index_to_update_loops: Array[Callable] = []
var _update_loop_flags: Dictionary[Callable, Bitset] = {}
var _list_memory_recycler := MemoryRecycler.new()

## Allocates an [ActionList] to process on the given [param update_loop].
## Returns the UID of the list generated for retrieval and deletion.
func create_action_list(update_loop: Callable) -> int:
	var index := MemoryRecycler.INVALID_INDEX
	
	if _list_memory_recycler.can_recycle():
		index = _list_memory_recycler.recycle()
		
		_action_lists[index].clear_all()
		_action_list_index_to_update_loops[index] = update_loop
		
	else:
		index = _list_memory_recycler.allocate()
		
		_action_lists.push_back(ActionList.new())
		_action_list_index_to_update_loops.push_back(update_loop)
	
	if not _update_loop_flags.has(update_loop):
		_update_loop_flags[update_loop] = Bitset.new()
	
	var flags := _update_loop_flags[update_loop]
	
	flags.set_bit(index, true)
	
	if update_loop == _process:
		set_process(flags.num_raised() > 0)
	elif update_loop == _physics_process:
		set_physics_process(flags.num_raised() > 0)
	
	return index

## Returns the [ActionList] at the given [param index].
func get_action_list(index: int) -> ActionList:
	return _action_lists[index]

## Deletes the [ActionList] at the given [param index].
func delete_action_list(index: int) -> void:
	var update_loop := _action_list_index_to_update_loops[index]
	var flags := _update_loop_flags[update_loop]
	
	_list_memory_recycler.delete(index)
	flags.lower_bit(index)
	
	if update_loop == _process:
		set_process(flags.num_raised() > 0)
	elif update_loop == _physics_process:
		set_physics_process(flags.num_raised() > 0)

## See [method ModularityInterface.get_strong_uniqueness_mode].
func get_strong_uniqueness_mode(super_level: int) -> UniquenessMode:
	if super_level == 0:
		return UniquenessMode.REPLACE_ONLY
	return super(super_level - 1)

## See [method ModularityInterface.is_strongly_unique].
func is_strongly_unique(super_level: int) -> bool:
	if super_level == 0:
		return false
	return super(super_level - 1)

func _ready() -> void:
	super()
	
	set_process(false)
	set_physics_process(false)

func _process(delta: float) -> void:
	_process_lists(delta, _update_loop_flags[_process])

func _physics_process(delta: float) -> void:
	_process_lists(delta, _update_loop_flags[_physics_process])

func _process_lists(delta: float, processable_bitset: Bitset) -> void:
	var num_allocated := _list_memory_recycler.get_allocation_total()
	
	if num_allocated <= 0:
		return
	
	for index: int in range(num_allocated):
		if _list_memory_recycler.is_deleted(index) or (not processable_bitset.get_bit(index)):
			continue
		
		_action_lists[index].update(delta)
