extends Node

signal village_added(village_data)
signal village_removed(village_id)

var villages = []  

func add_village(village_data):
	print("added vil")
	villages.append(village_data)
	village_added.emit(village_data)

func remove_village(village_id):
	# Your removal logic
	village_removed.emit(village_id)
