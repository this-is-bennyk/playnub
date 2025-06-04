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

@tool
class_name Playhead
extends Resource

## A special numerical type to keep track of long durations of time.
## 
## With long-lasting timelines or actions, you may want to reduce the
## amount of small floating-point manipulations you make so you can reduce
## floating-point drift (ex. adding delta time over and over). The [Playhead]
## ensures a more accurate amount of time tracked, in [b]positive[/b] seconds
## (i.e. greater than or equal to 0 seconds; in the range [code][0, ∞)[/code]),
## with operations to help ensure that the number of such operations made is limited.[br][br]
## [b]NOTE[/b]: Like other numerical types, this type cannot hold an infinite amount of numbers.
## It will wrap around in about [b]292 billion years[/b] (assuming a default Godot build with
## 64-bit [int]s and [float]s, and assuming no modifications like delta scaling, pausing,
## reversing, etc.).

# REMARK: The reason for this is because the below number represents seconds with a whole part
# (64-bit integer by default) and a decimal part (0-1, 64-bit floating point). With the integer
# increasing once per second (unmodified), it'll wrap around in LLONG_MAX seconds, which is greater
# than what can be calculated by looking up "9223372036854775807 seconds to years."
# [Default search engine] rounds up the number to 9223372036854776000 due to floating-point error,
# giving us ~292.5B years. Your mileage may vary in single-precision modes, but not by any meaningful amount.
# TL;DR: Don't sweat it. :D

## Describes the ways time can be represented.
enum TimeSegments
{
	SECONDS = 0b00001,
	MINUTES = 0b00010,
	HOURS   = 0b00100,
	DAYS    = 0b01000,
	WEEKS   = 0b10000,
}

## Describes the ways to represent time as a [String].
enum TimerFormat
{
	## Represented as [code]AAw BBd CCh DDm EE.FFs[/code].
	LETTERS,
	## Represented as [code]AA:BB:CC:DD:EE.FF[/code].
	COLONS,
	## Represented as [code]AAw BBd CCh DD'EE.FF''[/code].
	PRIMES,
}

@export_group("Time", "_seconds_")

## The number of whole seconds that the playhead has passed.
@export_range(0, 1, 1, "or_greater", "suffix:sec")
var _seconds_whole := 0

## The current fraction of a second that the playhead has passed.
@export_range(0.0, 0.999, 0.001, "suffix:sec")
var _seconds_fraction := 0.0

## Editor-only variable that manipulates the above numbers more easily.
@export_custom(PROPERTY_HINT_RANGE, "0.0,1.0,0.001,hide_slider,or_greater,suffix:sec", PROPERTY_USAGE_EDITOR)
var _seconds_slider: float:
	get:
		return to_float()
	set(value):
		set_to(value)

@export_group("Stringification", "stringification_")

## Determines which segments of time to represent when converting this playhead to a [String].
## If no value is selected, defaults to seconds.
@export_flags("Seconds", "Minutes", "Hours", "Days", "Weeks")
var stringification_time_segments := int(TimeSegments.SECONDS)

## Determines which format to display time when converting this playhead to a [String].
@export
var stringification_timer_format := TimerFormat.LETTERS

## Determines how many decimal places to show the fractions of a second in
## when converting this playhead to a [String].
@export_range(0, 10)
var stringification_decimal_cutoff := 2

## Moves the playhead forward and back in time, in [param seconds].
func move(seconds: float) -> void:
	_seconds_fraction += seconds
	
	_seconds_whole += int(seconds - fmod(_seconds_fraction, 1.0))
	
	if _seconds_whole < 0:
		reset()
	else:
		_seconds_fraction = absf(fmod(_seconds_fraction, 1.0))

## Resets to the position in time of 0 seconds.
func reset() -> void:
	_seconds_whole = 0
	_seconds_fraction = 0.0

## Sets the playhead to a position in time as given by [param time_seconds].
func set_to(seconds: float) -> void:
	reset()
	move(seconds)

## Returns the current value of the playhead as a usable [float].[br]
## [b]NOTE[/b]: The [float] returned will never be 100% accurate to the playhead's
## position due to floating-point error, but it can help to reduce the number
## of small floating-point additions made, i.e. reduce drifts in time.
func to_float() -> float:
	return float(_seconds_whole) + _seconds_fraction

## Returns the sum of this playhead and the [param other] playhead.
## If an existing playhead is provided to the parameter [param in_place],
## the calculation will be assigned to that playhead and returned via that playhead
## instead of allocating a new one.
func add(other: Playhead, in_place: Playhead = null) -> Playhead:
	var result := in_place if in_place else Playhead.new()
	
	result._seconds_whole = _seconds_whole + other._seconds_whole
	result._seconds_fraction = _seconds_fraction
	result.move(other._seconds_fraction)
	
	return result

## Returns the [b]absolute[/b] difference (i.e. never less than 0) between this playhead and the [param other] playhead.
## If an existing playhead is provided to the parameter [param in_place],
## the calculation will be assigned to that playhead and returned via that playhead
## instead of allocating a new one.
func sub(other: Playhead, in_place: Playhead = null) -> Playhead:
	var this_greater := greater_than(other)
	var a := self if this_greater else other
	var b := other if this_greater else self
	var result := in_place if in_place else Playhead.new()
	
	result._seconds_whole = a._seconds_whole - b._seconds_whole
	result._seconds_fraction = a._seconds_fraction
	result.move(-b._seconds_fraction)
	
	return result

## Assigns the position in time of the [param other] playhead to this one.
func assign(other: Playhead) -> void:
	_seconds_whole = other._seconds_whole
	_seconds_fraction = other._seconds_fraction

## Returns whether this playhead shares the same position in time with the [param other] playhead.
func equals(other: Playhead) -> bool:
	return _seconds_whole == other._seconds_whole and _seconds_fraction == other._seconds_fraction

## Returns whether this playhead is further ahead in time than the [param other] playhead.
func greater_than(other: Playhead) -> bool:
	return _seconds_whole > other._seconds_whole or \
		  (_seconds_whole == other._seconds_whole and _seconds_fraction > other._seconds_fraction)

## Returns whether this playhead shares the same position in time with or
## is further ahead in time than the [param other] playhead.
func greater_than_or_equals(other: Playhead) -> bool:
	return equals(other) or greater_than(other)

## Returns whether this playhead is further behind in time than the [param other] playhead.
func less_than(other: Playhead) -> bool:
	return not greater_than_or_equals(other)

## Returns whether this playhead shares the same position in time with or
## is further behind in time than the [param other] playhead.
func less_than_or_equals(other: Playhead) -> bool:
	return not greater_than(other)

func _init(_seconds := 0.0) -> void:
	_seconds = absf(_seconds)
	
	if _seconds > 0.0:
		move(_seconds)

func _to_string() -> String:
	const EMPTY_STR := &""
	const SPACE_STR := &" "
	const ZERO_STR := &"0"
	
	const DECIMAL_POINT := &"."
	
	const LETTER_SECONDS := &"s"
	const LETTER_MINUTES := &"m"
	const LETTER_HOURS   := &"h"
	const LETTER_DAYS    := &"d"
	const LETTER_WEEKS   := &"w"
	
	const COLON_TIME_SEPARATOR := &":"
	
	const PRIMES_SECONDS := &"''"
	const PRIMES_MINUTES := &"'"
	
	var seconds := _seconds_whole % 60
	var minutes := _seconds_whole / 60
	var hours := minutes / 60
	var days := hours / 24
	var weeks := days / 7
	
	var suffix_seconds := LETTER_SECONDS
	var suffix_minutes := LETTER_MINUTES
	var suffix_hours   := LETTER_HOURS
	var suffix_days    := LETTER_DAYS
	var suffix_weeks   := LETTER_WEEKS
	
	var segments: TimeSegments = stringification_time_segments
	
	match stringification_timer_format:
		TimerFormat.COLONS:
			suffix_seconds = EMPTY_STR
			suffix_minutes = COLON_TIME_SEPARATOR if segments & (TimeSegments.SECONDS) else EMPTY_STR
			suffix_hours   = COLON_TIME_SEPARATOR if segments & (TimeSegments.SECONDS | TimeSegments.MINUTES) else EMPTY_STR
			suffix_days    = COLON_TIME_SEPARATOR if segments & (TimeSegments.SECONDS | TimeSegments.MINUTES | TimeSegments.HOURS) else EMPTY_STR
			suffix_weeks   = COLON_TIME_SEPARATOR if segments & (TimeSegments.SECONDS | TimeSegments.MINUTES | TimeSegments.HOURS | TimeSegments.DAYS) else EMPTY_STR
		
		TimerFormat.PRIMES:
			suffix_seconds = PRIMES_SECONDS
			suffix_minutes = PRIMES_MINUTES if segments & TimeSegments.MINUTES else EMPTY_STR
	
	var fraction_str := ""
	
	if stringification_decimal_cutoff > 0:
		fraction_str = str(snappedf(_seconds_fraction, 1.0 / pow(10.0, float(stringification_decimal_cutoff))))
		
		var decimal_idx := fraction_str.find(DECIMAL_POINT)
		
		if decimal_idx > -1:
			fraction_str = fraction_str.substr(decimal_idx)
		else:
			fraction_str = EMPTY_STR
	
	var parts := PackedStringArray()
	
	if stringification_time_segments == 0 or segments == TimeSegments.SECONDS:
		parts.push_back(str(_seconds_whole, fraction_str, suffix_seconds))
	elif segments & TimeSegments.SECONDS:
		parts.push_back(str(ZERO_STR if seconds < 10 else EMPTY_STR, seconds, fraction_str, suffix_seconds))
	
	if segments & TimeSegments.MINUTES:
		parts.push_back(str(minutes, suffix_minutes))
	
	if segments & TimeSegments.HOURS:
		parts.push_back(str(hours, suffix_hours))
	
	if segments & TimeSegments.DAYS:
		parts.push_back(str(days, suffix_days))
	
	if segments & TimeSegments.WEEKS:
		parts.push_back(str(weeks, suffix_weeks))
	
	parts.reverse()
	
	match stringification_timer_format:
		TimerFormat.COLONS:
			return EMPTY_STR.join(parts)
	
	return SPACE_STR.join(parts)
