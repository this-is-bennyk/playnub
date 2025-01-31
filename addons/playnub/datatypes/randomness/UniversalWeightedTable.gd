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

class_name UniversalWeightedTable
extends RefCounted

## Container that selects elements, affected by given probabilities.
## 
## An easy way to assign rarity to certain data types, objects, functions. Also
## useful for manipulating simple behaviors.

var _weights: Array[float] = []
var _elements := []

var _total_weight := 0.0

## Adds an [param element] with [param weight] affecting its probability of occurring.
## A larger [param weight] means a higher chance. Returns the index the element was
## placed at.
func add(element: Variant, weight: float) -> int:
	var index := _elements.size()
	
	_weights.append(weight)
	_elements.append(element)
	
	_total_weight += weight
	
	return index

## Randomly chooses an element from the list and returns it.
func choose() -> Variant:
	var choice := randf_range(0.0, _total_weight)
	var sum := 0.0
	
	for index: int in _weights.size():
		sum += _weights[index]
		
		if sum > choice:
			return _elements[index]
	
	return _elements.back()
