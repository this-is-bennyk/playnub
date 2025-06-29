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

@icon("uid://b7qwtda1hcn6a")
class_name Module
extends ModularityInterface

## A modular unit of logic and/or data.
## 
## A component-like type that can be attached to any [Node] while still utilizing
## the benefits that come from Godot's scene system.[br]
## Deriving from this type gives the following benefits:[br][br]
## · Decoupling node access logic from [code]@export[/code], [code]$NodeName[/code],
## and [code]%NodeName[/code]; i.e. instead of this:
## 
## [codeblock]
## # Requires manually assigning the nodes in the scene tree.
## 
## @export var health_pool: HealthPool = null
## @export var weapon: Weapon = null
## # ...
## 
## # Or, the hardcoded alternative:
## 
## var health_pool := %HealthPool as HealthPool
## var weapon := $Gun as Weapon
## 
## # Or, the dynamic alternative in code:
## 
## var weapon: Weapon = null
## for child: Node in get_children():
##     if child is Weapon:
##         weapon = child
##         break
## # ...
## [/codeblock]
## 
## You can do this:
## 
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
## # You can write module access like this...
## var cur_weapon: Weapon = get_submodule(Weapon, cur_weapon_idx)
## var health_pool: HealthPool = get_submodule(HealthPool)
## 
## # ...or like this, which is the same and guarantees static type compilation
## var cur_weapon := get_submodule(Weapon, cur_weapon_idx) as Weapon
## var health_pool := get_submodule(HealthPool) as HealthPool
## 
## # ...
## [/codeblock]
## 
## · Querying modules of a certain type either locally or globally:
## [codeblock]
## # For getting all the children of a certain type relative to a parent module:
## var weapons := get_all_submodules(Weapon)
## 
## # For getting all the modules of a certain type in the scene tree:
## var all_of_my_type := get_tree().get_nodes_in_group(script_type)
## var all_weapons := get_tree().get_nodes_in_group(Module.name_of(Weapon))
## get_tree().call_group(Module.name_of(Weapon), Weapon.fire.get_method(), 1)
## [/codeblock]
## 
## · Stronger type safety when querying modules of a certain type:
## [codeblock]
## # If this class_name gets changed from...
## class_name Hero extends Module
## 
## # ...to:
## class_name PartyMember extends Module
## 
## # ...then these throw errors, so it's easier to identify and fix them.
## var hero := get_submodule(Hero) as Hero
## hero.revive()
## 
## var all_heros := get_tree().get_nodes_in_group(Module.name_of(Hero))
## get_tree().call_group(Module.name_of(Hero), Hero.heal.get_method(), 10)
## [/codeblock]
## 
## [b]NOTE[/b]: Deriving from this class [b]requires[/b] the derived classes to have
## [code]class_name[/code]s.

@export_group("Uniqueness", "uniqueness_")

## Whether there should only be 1 of this type of module as a child to a parent module.[br]
## [b]NOTE[/b]: This only applies to the [b]most derived class[/b].
@export
var uniqueness_enabled := false

## How existing modules of the same type should be replaced, if there are any.[br]
## [b]NOTE[/b]: This only applies to the [b]most derived class[/b].
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
## [b]NOTE[/b]: It is slightly less convenient to have to do this self-casting workaround
## over just making a script that inherits directly from a given [Node] type, but it allows for attaching
## modules to multiple types of [Node]s (ex. behavior shared between both 2D and 3D scenes).
var base: Node:
	get:
		return self as Node

## The parent of this module. May or may not be a module, so check [method has_parent_module] before
## accessing this.
var parent: Module:
	get:
		return get_parent() as Module

## Returns the [code]class_name[/code] of the given [param script].
static func name_of(script: Script) -> StringName:
	return script.get_global_name()

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

## Returns whether this module has a parent module. Be sure to check this
## before accessing the [member parent].
func has_parent_module() -> bool:
	return (not get_parent()) or get_parent() is Module

## See [method ModularityInterface.is_strongly_unique].
func is_strongly_unique(super_level: int) -> bool:
	if super_level == 0:
		return super(super_level)
	return super(super_level - 1)

## See [method ModularityInterface.get_strong_uniqueness_mode].
func get_strong_uniqueness_mode(super_level: int) -> UniquenessMode:
	if super_level == 0:
		return super(super_level)
	return super(super_level - 1)

func _ready() -> void:
	_add_type_groups()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_register()
		
		NOTIFICATION_UNPARENTED:
			_unregister()

func _add_type_groups() -> void:
	if not script_type.is_empty():
		add_to_group(script_type)
		
		var script_base := attached_script.get_base_script()
		
		while script_base and script_base != ModularityInterface:
			add_to_group(script_base.get_global_name())
			script_base = script_base.get_base_script()
		
	add_to_group(builtin_type)

func _create_module_list(script: Script) -> void:
	var empty: Array[Module] = []
	set_meta(script.get_global_name(), empty)

func _register() -> void:
	if not has_parent_module():
		return
	
	var current_script := attached_script
	var super_level := 0
	
	while current_script and current_script != ModularityInterface:
		var submodules := parent.get_all_submodules(current_script)
		
		if _is_unique(super_level):
			if submodules.is_empty():
				submodules.append(self)
			else:
				match _get_uniqueness_mode(super_level):
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
		
		current_script = current_script.get_base_script()
		super_level += 1

func _unregister() -> void:
	if not has_parent_module():
		return
	
	var current_script := attached_script
	var super_level := 0
	
	while current_script:
		var submodules := parent.get_all_submodules(attached_script)
		
		if _is_unique(super_level):
			submodules.clear()
		else:
			submodules.erase(self)
		
		current_script = current_script.get_base_script()
		super_level += 1

func _is_unique(super_level: int) -> bool:
	# If this is the most derived class, account for the designer variable
	# of uniqueness
	if super_level == 0:
		return uniqueness_enabled or is_strongly_unique(super_level)
	
	# Otherwise use the class's
	return is_strongly_unique(super_level)

func _get_uniqueness_mode(super_level: int) -> UniquenessMode:
	if is_strongly_unique(super_level):
		return get_strong_uniqueness_mode(super_level)
	elif uniqueness_enabled:
		return uniqueness_mode
	return UniquenessMode.REPLACE_ONLY
