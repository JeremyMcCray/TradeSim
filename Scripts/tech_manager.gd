extends Node

var technologies: Dictionary = {}

func _init() -> void:
	load_config()

func load_config() -> void:
	var file = FileAccess.open("res://configs/goods_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			technologies = json.get_data()
		file.close()

func add_tech_progress(tech_name: String, amount : float):
	if not tech_name in technologies:
		return
		
	technologies[tech_name]["progress"] += amount
	
	# Check for tech completion
	if technologies[tech_name]["progress"] >= technologies[tech_name]["required"]:
		complete_technology(tech_name)
		

func complete_technology(tech_name : String):
	pass
