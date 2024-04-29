class_name Interpolator
extends Action

## Performs an interpolation on a value over time as an [Action].
##
## TODO

var control_curve: ControlCurve = null
var relative := true

func controlled_by(_control_curve: ControlCurve) -> Interpolator:
	control_curve = _control_curve
	return self

func update() -> void:
	(target as Box).data = get_current_value()

func get_current_value() -> Variant:
	return control_curve.at(get_interpolation())
