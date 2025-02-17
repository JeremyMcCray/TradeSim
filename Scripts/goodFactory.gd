class_name GoodFactory
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

func create_good(good_type: String) -> Good:
	if not _config.has(good_type):
		push_warning("Good type '%s' not found in config" % good_type)
		return null
	
	var good_data = _config[good_type]
	var good = Good.new()
	
	# Apply configuration
	for property in good_data:
		good.set(property, good_data[property])
	return good

func get_good_types() -> Array:
	return _config.keys()
