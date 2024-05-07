# MIT License
# 
# Copyright (c) 2024 Ben Kurtin
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

class_name Randomizer
extends UniqueComponent

## Enhances existing random logic with game-specific randomization functions.
##
## In terms of UX, using uniform random logic often feels off, or that it is
## "too random." The functions in this class provide methods for making random
## interactions and/or events more believably random, even if that's not truly the
## case.

var _rng := RandomNumberGenerator.new()
var _deck_indices: Dictionary = {}

func _ready() -> void:
	self.randomize()

func randomize() -> void:
	_rng.randomize()
	(Playnub.get_component(Telemeter) as Telemeter).watch_single_datum(&"Seed", Box.new(_rng, "seed"), &"RandomizationData")

func randi() -> int:
	return _rng.randi()

func randf() -> float:
	return _rng.randf()

## Returns a normally-distributed, pseudo-random floating-point number from the specified mean
## and a standard deviation. This is also known as a Gaussian distribution. Unlike [method RandomNumberGenerator.randfn],
## this method does not rely on the Box-Muller transform to create a normal distribution, but
## instead relies on the Central Limit Theorem, trading mathematical accuracy for speed.
func fast_gaussian(mean := 0.0, deviation := 1.0) -> float:
	# Three psuedo-random numbers is enough for the CLT
	return (mean - deviation * 3.0) + (deviation * 6.0) * (_rng.randf() + _rng.randf() + _rng.randf()) / 3.0

## Returns a random value from the target [param array] via a uniform distribution.
func pick_random(array: Array) -> Variant:
	return array[_rng.randi_range(0, array.size() - 1)]

## Returns a random value from the target [param array], like [method Array.pick_random].
## However, unlike [method Array.pick_random], this function guarantees that no element
## is picked multiple times in a row. Useful for more believable random events (ex.
## drawing cards from a deck).
func deck_random(array: Array) -> Variant:
	if not array in _deck_indices:
		var empty: Array[int] = []
		_deck_indices[array] = empty
	
	var indices := _deck_indices[array] as Array[int]
	
	if indices.is_empty():
		var new_indices: Array[int] = []
		
		new_indices.assign(range(array.size()))
		_perform_fisher_yates(new_indices) # Normally Array.shuffle
		
		_deck_indices[array] = new_indices
		indices = new_indices
	
	return array[indices.pop_back()]

func _perform_fisher_yates(indices: Array[int]) -> void:
	var size := indices.size()
	
	if size < 2:
		return
	
	var from_index := size - 1
	
	while from_index >= 1:
		var to_index := _rng.randi() % (from_index + 1)
		var temp := indices[to_index]
		
		indices[to_index] = indices[from_index]
		indices[from_index] = temp
		
		from_index -= 1
