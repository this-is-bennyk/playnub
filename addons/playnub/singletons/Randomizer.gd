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
extends Node

## Enhances existing random logic with game-specific randomization functions.
##
## In terms of UX, using uniform random logic often feels off, or that it is
## "too random." The functions in this class provide methods for making random
## interactions and/or events more believably random, even if that isn't technically
## or mathematically true.

const RANDOMIZATION_DATA_TABLE := &"RandomizationData"

var _rng := RandomNumberGenerator.new()
var _deck_indices: Dictionary[Array, Array] = {}

func _ready() -> void:
	PlaynubTelemeter.watch_all(
		[
			  &"Seed"
			, &"State"
		]
		,
		[
			  Box.new(_rng, "seed")
			, Box.new(_rng, "state")
		]
		,
		RANDOMIZATION_DATA_TABLE)
	
	self.randomize()

## Sets up a time-based seed for the randomizer.
func randomize() -> void:
	_rng.randomize()
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)

## Sets a specific seed for the randomizer. Useful for games where saving the seed is
## important for replicating runs or saved games.
func set_seed(seed: Variant) -> void:
	_rng.seed = hash(seed)
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)

## Returns a pseudo-random 32-bit unsigned integer between [code]0[/code] and
## [code]4294967295[/code] (inclusive).
func randi() -> int:
	var result := _rng.randi()
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return result

## Returns a pseudo-random 32-bit signed integer between [param from] and [param to] (inclusive).
func randi_range(from: int, to: int) -> int:
	var result := _rng.randi_range(from, to)
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return result

## Returns a pseudo-random float between [code]0.0[/code] and [code]1.0[/code] (inclusive).
func randf() -> float:
	var result := _rng.randf()
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return result

## Returns a pseudo-random float between [param from] and [param true] (inclusive).
func randf_range(from: float, to: float) -> float:
	var result := _rng.randf_range(from, to)
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return result

## Returns a random boolean statement with equal probability to return
## [code]true[/code] or [code]false[/code].
func randb() -> bool:
	return bool(self.randi() % 2)

## Returns a normally-distributed, pseudo-random floating-point number from the specified mean and
## a standard deviation. This is also known as a Gaussian distribution.[br]
## [b]NOTE[/b]: This method uses the Box-Muller transform algorithm, trading speed for mathematical
## accuracy. See [method RandomNumberGenerator.randfn] for more information.
func randfn_accurate(mean := 0.0, deviation := 1.0) -> float:
	var result := _rng.randfn(mean, deviation)
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return result

## Returns a normally-distributed, pseudo-random floating-point number from the specified mean
## and a standard deviation. This is also known as a Gaussian distribution.
## [b]NOTE[/b]: This method uses the Central Limit Theorem, trading mathematical accuracy for speed.
func randfn_fast(mean := 0.0, deviation := 1.0) -> float:
	# Three psuedo-random numbers is enough for the CLT
	return (mean - deviation * 3.0) + (deviation * 6.0) * (self.randf() + self.randf() + self.randf()) / 3.0

## Returns a random value from the target [param array] via a uniform distribution.
func pick_random(array: Array) -> Variant:
	return array[self.randi_range(0, array.size() - 1)]

## Returns a random value from the target [param array] based on weighted probabilities provided by [param weights].
func pick_weighted(array: Array, weights: PackedFloat32Array) -> Variant:
	assert(array.size() == weights.size(), "Mismatched array and weight sizes!")
	var selection := _rng.rand_weighted(weights)
	PlaynubTelemeter.update(RANDOMIZATION_DATA_TABLE)
	return array[selection]

## Returns a random value from the target [param array]. However, unlike [method pick_random] or
## [method pick_weighted], this function guarantees that no element is picked multiple times in a row.
## Useful for more believable random events (ex. drawing cards from a deck).
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

# The RNG object doesn't come with a shuffle function
func _perform_fisher_yates(indices: Array[int]) -> void:
	var size := indices.size()
	
	if size < 2:
		return
	
	var from_index := size - 1
	
	while from_index >= 1:
		var to_index := self.randi() % (from_index + 1)
		var temp := indices[to_index]
		
		indices[to_index] = indices[from_index]
		indices[from_index] = temp
		
		from_index -= 1
