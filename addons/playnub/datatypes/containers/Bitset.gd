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

@icon("uid://1o50di42u0o6")
class_name Bitset
extends RefCounted

## A vector of an arbitrary number of bits.

## The number of bits in a byte.
const NUM_BITS := 8

var _bits := PackedByteArray()

func _init(_idxs_to_set := PackedInt64Array()) -> void:
	if not _idxs_to_set.is_empty():
		var sorted_idxs := _idxs_to_set.duplicate()
		
		# Sort the indices so we know we're writing bits in sequential order
		sorted_idxs.sort()
		# Go in reverse sequential order so we only do one resize in the groups bitset
		sorted_idxs.reverse()
		
		# Set the bits given
		for idx: int in sorted_idxs:
			raise_bit(idx)

## Gets the bit at the index [param idx].
func get_bit(idx: int) -> bool:
	var exceeds_known_groups := idx / NUM_BITS >= _bits.size()
	
	if idx < 0 or exceeds_known_groups:
		return false
	
	return (_bits[idx / NUM_BITS] >> (idx % NUM_BITS)) & 1

## Sets the bit at the index [param idx] to [code]1[/code].
func raise_bit(idx: int) -> void:
	var exceeds_known_groups := idx / NUM_BITS >= _bits.size()
	
	if exceeds_known_groups:
		_resize(idx / NUM_BITS + 1)
	
	_bits[idx / NUM_BITS] |= 1 << (idx % NUM_BITS)

## Sets the bit at the index [param idx] to [code]0[/code].
func lower_bit(idx: int) -> void:
	var exceeds_known_groups := idx / NUM_BITS >= _bits.size()
	
	if exceeds_known_groups:
		_resize(idx / NUM_BITS + 1)
	
	_bits[idx / NUM_BITS] &= ~(1 << (idx % NUM_BITS))

## Flips the bit at the index [param idx] from [code]0[/code] to [code]1[/code]
## or from [code]1[/code] to [code]0[/code].
func flip_bit(idx: int) -> void:
	lower_bit(idx) if get_bit(idx) else raise_bit(idx)

## Raises the bits that this [Bitset] has raised in the [param other] [Bitset].
func merge_onto(other: Bitset) -> void:
	if other._bits.size() < _bits.size():
		other._resize(_bits.size())
	
	for i: int in _bits.size():
		other._bits[i] |= _bits[i]

## Whether this [Bitset] and the [param other] [Bitset] share any raised bits.
func any_bits_from(other: Bitset) -> bool:
	for i: int in mini(_bits.size(), other._bits.size()):
		if _bits[i] & other._bits[i] != 0:
			return true
	return false

## Erases all the raised bits.
func clear() -> void:
	_bits.fill(0)

func _resize(new_size: int) -> void:
	_bits.resize(new_size)
