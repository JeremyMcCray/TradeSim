extends Node

func load_config(file_path : String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var _config
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			_config = json.get_data()
		file.close()
		return file
