extends Control

func _ready():
	# Make sure this is set in your scene
	top_level = true
	
	# Connect to Global signal
	Global.village_added.connect(_on_village_added)

func _on_village_added(village_data):
	# Process the village_data and update your display
	$HBoxContainer/Label.display_text = str(village_data)  # Or format it as needed
