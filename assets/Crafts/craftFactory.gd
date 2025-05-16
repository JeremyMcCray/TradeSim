class_name CraftFactory
extends Node

var _config: Dictionary = {}

func _init() -> void:
	load_config()

func load_config() -> void:
	var file = FileAccess.open("res://assets/Crafts/crafts_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			_config = json.get_data()
		file.close()

func create_craft(craft_type: String) -> Craft:
	if not _config.has(craft_type):
		push_warning("Craft type '%s' not found in config" % craft_type)
		return null
	
	var craft_data = _config[craft_type]
	var craft = Craft.new()
	
	# Apply configuration
	for property in craft_data:
		craft.set(property, craft_data[property])
	return craft

func get_craft_types() -> Array:
	return _config.keys()
