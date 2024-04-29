class_name Action
extends RefCounted

## Performs logic grouped as a singular unit.
##
## TODO

## Time in seconds this action lasts.
var duration := 0.0:
	set(value):
		duration = maxf(0.0, value)

## Time in seconds before this action starts.
var delay := 0.0:
	set(value):
		delay = maxf(0.0, value)

## The object to enact logic on.
var target: Object = null

## The set of groups this action belongs to.
var participating_groups := Bitset.new([0])
## The set of groups this action is blocking from executing before it is finished.
var blocking_groups := Bitset.new()

# The current delta time elasped.
var _dt := 0.0
# The amount of time that has elapsed. Starts at 0, ends at duration + delay.
var _time_passed := 0.0

# Whether this action has already been entered.
var _entered := false
# Whether this action has already been finished.
var _done := false
# Whether this action counts down to 0.0 or up to duration + delay.
var _reversed := false

func targets(_target: Object) -> Action:
	target = _target
	return self

func lasts(_duration_sec: float = 0.0) -> Action:
	duration = _duration_sec
	return self

func after(_delay_sec: float = 0.0) -> Action:
	delay = _delay_sec
	return self

func in_groups(_groups: PackedInt64Array = PackedInt64Array()) -> Action:
	if not _groups.has(0):
		var groups_copy := _groups.duplicate()
		
		groups_copy.append(0)
		
		participating_groups = Bitset.new(groups_copy)
		return self
	
	participating_groups = Bitset.new(_groups)
	return self

## Blocks the groups that this action belongs to from executing.
## Pass [code]true[/code] to [param override] to override the groups being blocked
## instead of adding to them.
func blocks_own_groups(override: bool = false) -> Action:
	# If we're overriding the groups to block, erase the previously blocking groups
	if override:
		blocking_groups.clear()
	
	participating_groups.merge_onto(blocking_groups)
	
	return self

## Blocks an arbitrary collection of groups from executing.
## Each index in [param indices] refers to the bit at the index.
## Pass [code]true[/code] to [param override] to override the groups being blocked
## instead of adding to them.
func blocks(indices: PackedInt64Array, override: bool = false) -> Action:
	# If we're overriding the groups to block, erase the previously blocking groups
	if override:
		blocking_groups.clear()
	
	var blocking_bits := Bitset.new(indices)
	
	blocking_bits.merge_onto(blocking_groups)
	
	return self

## Performs logic and increases the amount of
## time taken by this action by [param dt] seconds. Override [method update]
## to customize the behavior of this action.
func process(dt: float) -> void:
	if done() or not target or not is_instance_valid(target):
		return
	
	_dt = dt
	_time_passed += get_delta_time()
	
	if not delayed():
		if not entered():
			enter()
			_entered = true
		
		update()
		
		if done():
			exit()

## Performs logic upon this action being encountered for the first time.
## Override this method to customize the behavior of the action.
func enter() -> void:
	pass

## Performs continuous logic.
## Override this method to customize the behavior of the action.
func update() -> void:
	pass

## Performs logic upon this action being encountered for the last time.
## Override this method to customize the behavior of the action.
func exit() -> void:
	pass

## Whether this function has already been encountered.
func entered() -> bool:
	return _entered

## Whether the action has finished execution.
func done() -> bool:
	return (_done or
		(_reversed and _time_passed <= 0.0) or
		(not _reversed and _time_passed >= duration + delay))

## Whether this action is being delayed.
func delayed() -> bool:
	return _time_passed < delay

## Prematurely finishes the action.
func finish() -> void:
	_done = true

## @experimental
## Enables a flag that processes the recorded time of this action in reverse.
## That is, the time passed counts down to [code]0.0[/code] instead of up to
## [code]duration + delay[/code].
func reverse() -> void:
	_reversed = true

## How many seconds have passed since the action was entered.
func get_time_passed() -> float:
	return clampf(_time_passed - delay, 0.0, duration)

## How far into the action we are as a percent of the duration that's been completed.
func get_interpolation() -> float:
	if duration == 0.0:
		return 0.0
	return clampf(inverse_lerp(0.0, duration, _time_passed - delay), 0.0, 1.0)

## The delta time for the current frame.
func get_delta_time() -> float:
	return _dt * (-1.0 if _reversed else 1.0)
