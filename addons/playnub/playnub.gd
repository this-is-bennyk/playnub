@tool
extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton(&"Playnub", &"res://addons/playnub/autoload/PlaynubSingleton.tscn")

func _disable_plugin() -> void:
	remove_autoload_singleton(&"Playnub")
