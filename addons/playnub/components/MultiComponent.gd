class_name MultiComponent
extends Component

func _register() -> void:
	parent.get_all_components(attached_script).append(self)

func _unregister() -> void:
	parent.get_all_components(attached_script).erase(self)
