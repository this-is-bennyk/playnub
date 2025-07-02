class_name ActionFactory
extends Resource # make abstract w 4.5
# make ControlCurve and PIDCFactory inherit

## Interface for creating actions with certain parameters.

func create_action() -> Action: # I believe you can return inherited types (forgot what that paradigm was called)
	return null
