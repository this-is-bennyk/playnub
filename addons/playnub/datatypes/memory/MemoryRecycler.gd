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

@icon("uid://bcccl0gj5kf4x")
class_name MemoryRecycler
extends RefCounted

## Allows arrays to have elements that can be recycled rather than re-allocated,
## and allows each element to have a UID.
## 
## Suppose that you have an array of elements that need to have unique IDs that can't
## be invalidated and that need to be allocated and deleted whenever you want. Also suppose
## that the array needs to be conservative with the number of new memory allocations made.
## That would be a memory pool, and this object allows one to make any array a memory
## pool by giving explicit instructions on when to allocate a new element or recycle and
## reuse an old one with new data.[br][br]
## The following snippet is an example of this in action:
## [codeblock]
## # Allocate the recycler alongside your array.
## # (You must create the array so you have control over the type safety.)
## var my_array := []
## var recycler := MemoryRecycler.new()
## 
## # ...
## 
## # Prepare for the new ID of the element.
## var index := MemoryRecycler.INVALID_INDEX
## 
## # If we can reuse a deleted element, grab its index by recycling
## # and assign new data to the old element.
## if recycler.can_recycle():
##     index = recycler.recycle()
##     my_array[index] = element
## # Otherwise, grab the index by allocation
## # and add the new element to the end of the array.
## else:
##     index = recycler.allocate()
##     my_array.push_back(element)
## 
## # ...
## 
## # When an element is no longer needed, mark its index as deleted
## # so it can be recycled like in the above.
## recycler.delete(index)
## 
## # ...
## 
## # Be sure to check if an element has been deleted before
## # manipulating it.
## 
## # With an if statement:
## if recycler.is_deleted(index):
##     pass # Your logic here.
## 
## # With an assert:
## assert(not recycler.is_deleted(index), "Your error message here")
## [/codeblock]

## The index that indicates an invalid identifier or that there's nothing to recycle.
const INVALID_INDEX := -1

# A jump table of the indices of deleted elements, so we can recycle
# previously removed elements for cache coherency and prevention of invalidated IDs.
# Each index represents either no next deleted element or the next deleted
# element to recycle.
var _deleted_jump_table := PackedInt64Array()
# The index of the last deleted element. A value of INVALID_INDEX
# means there is no element to recycle.
var _last_deleted := INVALID_INDEX
# The index of the first deleted element. The first index deleted will have the invalid
# index as the next jump index, so this needs to be checked as part of the
# recycling logic.
var _first_deleted := INVALID_INDEX
# The number of elements allocated.
var _num_allocated := 0

## Returns an index (unique identifier) representing a newly allocated element.
## [method can_recycle] [b]must[/b] called before this.
func allocate() -> int:
	assert(not can_recycle(), "Check can_recycle() before calling this!")
	
	_deleted_jump_table.push_back(INVALID_INDEX)
	_num_allocated += 1
	
	return _deleted_jump_table.size() - 1

## Returns an index (unique identifier) representing a previously deleted element
## being reused as a new one.
## [method can_recycle] [b]must[/b] called before this.
func recycle() -> int:
	assert(can_recycle(), "Check can_recycle() before calling this!")
	
	var result := _last_deleted
	var next_to_recycle := _deleted_jump_table[_last_deleted]
	
	# Indicate that this element is in use again
	_deleted_jump_table[_last_deleted] = INVALID_INDEX
	# Make the element recycled before this one the next up to be reused
	_last_deleted = next_to_recycle
	
	# If we've reached the first index deleted, mark it as no longer being deleted
	if _first_deleted == result:
		_first_deleted = INVALID_INDEX
	
	_num_allocated += 1
	
	return result

## Marks the element at the given [param index] as being no longer in use and
## able to be recycled.
func delete(index: int) -> void:
	assert(not is_deleted(index), "Double deletion!")
	
	_deleted_jump_table[index] = _last_deleted
	_last_deleted = index
	
	if _first_deleted == INVALID_INDEX:
		_first_deleted = index
	
	_num_allocated -= 1

## Returns whether this element was previously deleted.
func is_deleted(index: int) -> bool:
	assert(index > INVALID_INDEX and index < _deleted_jump_table.size(), "Out of bounds!")
	# The first deleted element will have the invalid index as its next jump index
	# so we need to check for that by seeing if this index is that one
	return _deleted_jump_table[index] != INVALID_INDEX or index == _first_deleted

## Returns whether there are any elements that can be reused.
## [b]Must[/b] be called before [method allocate] or [method recycle].
func can_recycle() -> bool:
	return _last_deleted != INVALID_INDEX

## Returns the number of elements currently allocated.
func get_allocation_total() -> int:
	return _num_allocated
