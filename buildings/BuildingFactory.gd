class_name BuildingFactory
extends Node

var _config: Dictionary = {}

func _init() -> void:
	load_config()

func load_config() -> void:
	var file = FileAccess.open("res://configs/goods_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			_config = json.get_data()
		file.close()

func create_building(building_type: String) -> Building:
	if not _config.has(building_type):
		push_warning("Building type '%s' not found in config" % building_type)
		return null
	
	var good_data = _config[building_type]
	var good = Building.new()
	
	# Apply configuration
	for property in good_data:
		good.set(property, good_data[property])
	return good

func get_building_types() -> Array:
	return _config.keys()
