class_name UniqueComponent
extends Component

func _register() -> void:
	var components := parent.get_all_components(attached_script)
	
	if components.is_empty():
		components.append(self)
	else:
		components[0] = self

func _unregister() -> void:
	parent.get_all_components(attached_script).clear()
