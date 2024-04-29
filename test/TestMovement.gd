class_name TestMovement
extends UniqueComponent

@export
var control_curve: ControlCurve = null

@export
var point_to_follow: Marker2D = null

func _ready():
	var action_list := parent.get_component(ActionList) as ActionList
	
	var ctrl_curve_copy := control_curve.duplicate() as ControlCurve
	ctrl_curve_copy.between(Box.new((parent.upcasted as Sprite2D).position), Box.new(point_to_follow, "position"))
	
	action_list.push(
		Interpolator.new()
		.controlled_by(ctrl_curve_copy)
		.targets(Box.new(parent, "position")).lasts(2.0)
	)
