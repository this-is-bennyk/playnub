class_name PlaynubModuleDB

static var _database: Dictionary[StringName, Array] = {}

static func register(module: Module, script: Script) -> void:
	if not _database.has(script.get_global_name()):
		var column: Array[Module] = []
		_database[script.get_global_name()] = column
	
	_database[script.get_global_name()].push_back(module)

static func unregister(module: Module, script: Script) -> void:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	_database[script.get_global_name()].erase(module)

static func retrieve(script: Script, index := 0) -> Module:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	var column := _database[script.get_global_name()] as Array[Module]
	return column[index]

static func retrieve_all(script: Script) -> Array[Module]:
	assert(_database.has(script.get_global_name()), str(&"No Modules of type ", script.get_global_name(), &" found!"))
	return _database[script.get_global_name()] as Array[Module]
