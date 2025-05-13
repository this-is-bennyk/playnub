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

class_name Module
extends Node

## A modular unit of logic and/or data.
## 
## A component-like type that can be attached to any [Node] while still utilizing
## the benefits that come from Godot's scene system.

## What a unique module does when replacing another / others of the same type.
enum UniquenessMode
{
	## Only replaces the reference. Does not affect the other module(s).
	  REPLACE_ONLY
	## Deletes the other module(s) from memory, then replaces it / them.
	, DELETE_AND_REPLACE
	## Stashes the other module(s) in the parent module, then replaces it / them.
	## (Not functional yet.)
	## @experimental: To be implemented when stashing or disabling (whichever is used) is introduced.
	, STASH_AND_REPLACE
}

@export_group("Uniqueness", "uniqueness_")

## Whether there should only be 1 of this type of module in a parent module.
@export
var uniqueness_enabled := false

## How existing modules of the same type should be replaced, if there are any.
@export
var uniqueness_mode: UniquenessMode = UniquenessMode.REPLACE_ONLY

## The script attached to this module, with the correct casting from [Variant].
var attached_script: Script:
	get:
		return get_script() as Script

## The [code]class_name[/code] of the script of this module.
var script_type: StringName = &"":
	get:
		if script_type.is_empty():
			script_type = attached_script.get_global_name()
		return script_type

## The name of the node type this module is attached to.
var builtin_type: StringName = &"":
	get:
		if builtin_type.is_empty():
			builtin_type = get_class()
		return builtin_type

## The [code]self[/code] as a base [Node]. For convenient downcasting; for example:
## [codeblock]
## # Since sidecasting isn't supported in GDScript, this is slightly harder to type...
## (self as Node as Node2D).position
## # ...than this.
## (base as Node2D).position
## [/codeblock]
## [b]Remark[/b]: It is slightly less convenient to have to do this self-casting workaround
## over just making a script that inherits directly from a given [Node] type, but it allows for attaching
## modules to multiple types of [Node]s (ex. behavior shared between both 2D and 3D scenes).
var base: Node:
	get:
		return self as Node

## The parent module. All modules should have parent modules.
var parent: Module:
	get:
		return get_parent() as Module

func _ready() -> void:
	_add_type_groups()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_register()
		
		NOTIFICATION_UNPARENTED:
			_unregister()

## Returns an array of submodules of type [param script]. For example:
## [codeblock]
## # Weapon.gd
## class_name Weapon extends Module
## # ...
## 
## # Player.gd
## class_name Player extends Module
## # ...
## var weapons := get_all_submodules(Weapon)
## # ...
## [/codeblock]
## [b]NOTE[/b]: Submodules are not guaranteed to be ordered in a particular way.
## The order of them may change as new ones are added / deleted.
func get_all_submodules(script: Script) -> Array[Module]:
	if not has_meta(script.get_global_name()):
		_create_module_list(script)
	
	return get_meta(script.get_global_name()) as Array[Module]

## Returns a specific submodule of type [param script] at [param index]. For example:
## [codeblock]
## # Weapon.gd
## class_name Weapon extends Module
## # ...
## 
## # HealthPool.gd
## class_name HealthPool extends Module
## # ...
## 
## # Player.gd
## class_name Player extends Module
## var cur_weapon_idx := 0
## # ...
## 
## # You can write the calls to this function like this...
## var cur_weapon: Weapon = get_submodule(Weapon, cur_weapon_idx)
## var health_pool: HealthPool = get_submodule(HealthPool)
## 
## # ...or like this, which is the same and guarantees static type compilation
## var cur_weapon := get_submodule(Weapon, cur_weapon_idx) as Weapon
## var health_pool := get_submodule(HealthPool) as HealthPool
## 
## # ...
## [/codeblock]
## [b]NOTE[/b]: Submodules are not guaranteed to be ordered in a particular way.
## The order of them may change as new ones are added / deleted.
func get_submodule(script: Script, index := 0) -> Module:
	if not has_meta(script.get_global_name()):
		_create_module_list(script)
		return null
	
	var submodules := get_all_submodules(script)
	
	return null if submodules.is_empty() else submodules[index]

## Returns whether there exists at least 1 submodule of type [param script].
func has_submodule_type(script: Script) -> bool:
	return has_meta(script.get_global_name()) and not (get_meta(script.get_global_name()) as Array[Module]).is_empty()

## Returns whether this module has a parent module. May be useful to check this
## before accessing the [member parent].
func has_parent_module() -> bool:
	return get_parent() is Module

## Virtual function that determines if the module should enforce uniqueness
## programmatically as opposed to using the designer variable [member uniqueness_enabled].
## Override to return [code]true[/code] if you wish to enable this.
func is_strongly_unique() -> bool:
	return false

## Returns how existing modules of the same type should be replaced, if there are any,
## assuming [method has_strong_uniqueness] returns [code]true[/code].
func get_strong_uniqueness_mode() -> UniquenessMode:
	return UniquenessMode.REPLACE_ONLY

func _add_type_groups() -> void:
	if not script_type.is_empty():
		add_to_group(script_type)
		
		var script_base := attached_script.get_base_script()
		
		while script_base != null:
			add_to_group(script_base.get_global_name())
			script_base = script_base.get_base_script()
		
	add_to_group(builtin_type)

func _create_module_list(script: Script) -> void:
	var empty: Array[Module] = []
	set_meta(script.get_global_name(), empty)

func _register() -> void:
	if not parent:
		return
	
	var submodules := parent.get_all_submodules(attached_script)
	
	if _is_unique():
		if submodules.is_empty():
			submodules.append(self)
		else:
			match _get_uniqueness_mode():
				UniquenessMode.DELETE_AND_REPLACE:
					for submodule: Module in submodules:
						submodule.queue_free()
				
				# TODO: If/when stashing is implemented
				#UniquenessMode.STASH_AND_REPLACE:
					#for submodule: Module in submodules:
						#submodule.stash()
			
			submodules.clear()
			submodules.append(self)
	else:
		submodules.append(self)

func _unregister() -> void:
	if not parent:
		return
	
	var submodules := parent.get_all_submodules(attached_script)
	
	if _is_unique():
		submodules.clear()
	else:
		submodules.erase(self)

func _is_unique() -> bool:
	return uniqueness_enabled or is_strongly_unique()

func _get_uniqueness_mode() -> UniquenessMode:
	if is_strongly_unique():
		return get_strong_uniqueness_mode()
	elif uniqueness_enabled:
		return uniqueness_mode
	return UniquenessMode.REPLACE_ONLY
