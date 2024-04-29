class_name Entity
extends ExtendedNode

func get_all_components(script: Script) -> Array[Component]:
	if not has_meta(script.get_global_name()):
		_create_component_list(script)
	
	return get_meta(script.get_global_name()) as Array[Component]

func get_component(script: Script, idx := 0) -> Component:
	if not has_meta(script.get_global_name()):
		_create_component_list(script)
		return null
	
	var components := get_all_components(script)
	
	return null if components.is_empty() else components[idx]

func has_component_type(script: Script) -> bool:
	return has_meta(script.get_global_name()) and not (get_meta(script.get_global_name()) as Array[Component]).is_empty()

func _create_component_list(script: Script) -> void:
	var empty: Array[Component] = []
	set_meta(script.get_global_name(), empty)
