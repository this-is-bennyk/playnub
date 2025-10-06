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

class_name PlaynubModuleDB

## Global singleton that allows for efficient querying of all [Module] instantiations.

static var _database: Dictionary[StringName, Array] = {}

static func _register(module: Module, script: Script) -> void:
	if not _database.has(script.get_global_name()):
		var column: Array[Module] = []
		_database[script.get_global_name()] = column
	
	_database[script.get_global_name()].push_back(module)

static func _unregister(module: Module, script: Script) -> void:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	_database[script.get_global_name()].erase(module)

## Returns the [Module] with the given [param script] type at the given [param index].
static func retrieve(script: Script, index := 0) -> Module:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	var column := _database[script.get_global_name()] as Array[Module]
	return column[index]

## Returns all the [Module] with the given [param script] type.
static func retrieve_all(script: Script) -> Array[Module]:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	return _database[script.get_global_name()] as Array[Module]
