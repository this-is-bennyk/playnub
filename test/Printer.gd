class_name Printer
extends UniqueComponent

func _ready():
	super()
	print(builtin_type, ", ", get_groups())
