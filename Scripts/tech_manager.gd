extends Node

var technologies: Dictionary
var current_era: String = "early"
var researched_techs: Array = []

@export var script_user : Node

func _ready():
	load_tech_data()
	
func load_tech_data():
	var file = FileAccess.open("res://data/tech_tree.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		technologies = data.get("technologies", {})
	else:
		push_error("Failed to load tech tree data")

func is_tech_researched(tech_id: String) -> bool:
	return tech_id in researched_techs

func can_research(tech_id: String) -> bool:
	if not tech_id in technologies:
		return false
		
	var tech = technologies[tech_id]
	
	# Check era requirement
	if tech.get("era", "") != current_era:
		return false
		
	# Check tech prerequisites
	for required_tech in tech.get("prerequisites", {}).get("techs_required", []):
		if not is_tech_researched(required_tech):
			return false
			
	return true

func research_tech(tech_id: String) -> bool:
	if not can_research(tech_id):
		return false
		
	researched_techs.append(tech_id)
	return true

func get_available_techs() -> Array:
	var available = []
	
	for tech_id in technologies:
		if can_research(tech_id) and not is_tech_researched(tech_id):
			available.append(tech_id)
			
	return available

func advance_era(new_era: String):
	current_era = new_era

func add_researched_bulidings(buildings: Array):
	for building in buildings:
		script_user.building["building"] = building
	pass
