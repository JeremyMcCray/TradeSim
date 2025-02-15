extends StaticBody3D

var worker_count = 13

var inventory = {}

var wood_count
var stone_count

var tick = 0
var tick_timer = 300

var statue =  false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#spawns 3 vills
	spawn_workers()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tick > tick_timer:
		bulid_new_mill()
		tick = 0
	tick += 1 
	pass

func spawn_workers():
	for i in worker_count:
		var worker = load("res://Worker/worker.tscn")
		worker.set_local_to_scene(true)
		var unpacked = worker.instantiate()
		unpacked.village = self
		self.add_child(unpacked)
		unpacked.set_global_position((self.global_position) + Vector3(randi_range(1,10),0,randi_range(1,10)))

func deliver_goods(deliverer):
	inventory = merge_dictionaries(deliverer.inventory, inventory)
	
	deliverer.inventory = {}
	deliverer.inv_count = 0
	print(inventory)
	pass

func add_to_inv(good_string):
	var resource = inventory.get_or_add(good_string, 0)
	inventory[good_string] = resource + 1

func merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var merged = dict1.duplicate()  # Create a copy of the first dictionary
	for key in dict2.keys():
		if merged.has(key):
			merged[key] += dict2[key]  # Add the values for existing keys
		else:
			merged[key] = dict2[key]  # Add new keys
	return merged

func bulid_new_mill():
	print("Bulin the mill la")
	wood_count = inventory.get_or_add("Wood", 0)
	stone_count = inventory.get("Stone", 0)
	if wood_count != null and wood_count > 4 and stone_count != null and stone_count > 4 and statue == false:
		statue = true 
		inventory["Wood"] = inventory["Wood"] - 4
		inventory["Stone"] = inventory["Stone"] - 4 
		var pack = load("res://assets/KayKitModels/lumbermill.obj")
		var mill = pack.instantiate()
		self.add_child(mill)
		mill.set_global_position(Vector3(self.global_position.x + randi_range(1,10),self.global_position.y,self.global_position.z + randi_range(1,10)))
