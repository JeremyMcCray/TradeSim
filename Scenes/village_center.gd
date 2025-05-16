extends StaticBody3D

var worker_count = 6
var trader_count = 2
var inventory = {}
var tick = 0
var tick_timer = 300
var gold = 10000
var building_count = 0
var building_max = 5

var prices = {}
var goods_config

# Dictionary of available buildings with their costs
var available_buildings = {
	"watchtower": {
		"scene": preload("res://assets/highFantasyBuildings/WatchTower/watch_tower.tscn"),
		"cost": {"Wood": 4, "Stone": 4}
	},
	"barraks": {
		"scene": preload("res://assets/highFantasyBuildings/Barracks/barracks.tscn"),
		"cost": {"Wood": 1, "Stone": 5}
	},
		"house": {
		"scene": preload("res://assets/highFantasyBuildings/Hut/hut.tscn"),
		"cost": {"Wood": 4, "Stone": 2}
	},
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_workers()
	spawn_trader()
	goods_config = load("res://configs/goods_config.json").get_data()
	initialize_prices()

func initialize_prices():
	# Villages might have slightly different initial prices
	for good_key in goods_config:
		# Randomize village prices slightly (±20% of base price)
		var base_price = goods_config[good_key].base_price
		prices[good_key] = base_price * (0.8 + randf() * 0.4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tick > tick_timer:
		try_build_random_building()
		tick = 0
	tick += 1 

func spawn_workers():
	for i in worker_count:
		var worker = load("res://Worker/worker.tscn")
		worker.set_local_to_scene(true)
		var unpacked = worker.instantiate()
		unpacked.village = self
		self.add_child(unpacked)
		unpacked.set_global_position((self.global_position) + Vector3(randi_range(1,10),4,randi_range(1,10)))

func spawn_trader():
	for i in trader_count:
		var trader = load("res://Scenes/trader.tscn")
		trader.set_local_to_scene(true)
		var unpacked = trader.instantiate()
		unpacked.village = self
		self.add_child(unpacked)
		unpacked.set_global_position((self.global_position) + Vector3(randi_range(1,10),4,randi_range(1,10)))

func deliver_goods(deliverer):
	# Track price adjustments for logging
	var price_adjustments = {}
	
	# First adjust prices based on what's being delivered
	for item_name in deliverer.inventory:
		var item_key = item_name.to_lower()
		if goods_config.has(item_key):
			var quantity = deliverer.inventory[item_name]
			if quantity > 0:
				var item_data = goods_config[item_key]
				
				# Calculate price adjustment based on quantity delivered
				# More quantity = greater price decrease (supply increases)
				var supply_factor = quantity * 0.02  # 2% price impact per unit
				var new_price = max(
					item_data.min_price,
					prices.get(item_key, item_data.base_price) * (1 - supply_factor))
				
				# Store old and new price for logging
				price_adjustments[item_name] = {
					"old": prices.get(item_key, item_data.base_price),
					"new": new_price,
					"qty": quantity
				}
				
				# Apply the new price
				prices[item_key] = new_price
	
	# Now actually transfer the inventory
	inventory = merge_dictionaries(deliverer.inventory, inventory)
	deliverer.inventory = {}
	deliverer.inv_count = 0
	
	# Log price adjustments if any occurred
	if price_adjustments.size() > 0:
		print("\n--- Price Adjustments After Delivery ---")
		for item_name in price_adjustments:
			var adj = price_adjustments[item_name]
			print("%s: %d units delivered | Price %d -> %d (%.1f%% decrease)" % [
				item_name,
				adj["qty"],
				adj["old"],
				adj["new"],
				(1 - adj["new"]/adj["old"]) * 100
			])
		print("------------------------------------\n")

func add_to_inv(good_string):
	var resource = inventory.get(good_string, 0)
	inventory[good_string] = resource + 1

func merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var merged = dict1.duplicate()
	for key in dict2.keys():
		if merged.has(key):
			merged[key] += dict2[key]
		else:
			merged[key] = dict2[key]
	return merged

func try_build_random_building():
	if building_count >= building_max:
		return
	# Get a random building from available buildings
	var building_keys = available_buildings.keys()
	if building_keys.size() == 0:
		return
		
	var random_building_key = building_keys[randi() % building_keys.size()]
	var building_data = available_buildings[random_building_key]
	
	# Check if we can afford this building
	if can_afford_building(building_data["cost"]):
		build_building(random_building_key, building_data)

func can_afford_building(costs: Dictionary) -> bool:
	for resource in costs.keys():
		if inventory.get(resource, 0) < costs[resource]:
			return false
	return true

func build_building(building_name: String, building_data: Dictionary):
	# Deduct costs from inventory
	for resource in building_data["cost"].keys():
		inventory[resource] = inventory[resource] - building_data["cost"][resource]
	
	# Instantiate and place the building
	var building_scene = building_data["scene"].instantiate()
	self.add_child(building_scene)
	building_scene.scale *= Vector3(5,5,5)
	
	building_scene.set_global_position(
		Vector3(
			self.global_position.x + randi_range(1,40),
			self.global_position.y,
			self.global_position.z + randi_range(1,40)
		)
	)
	
	building_count += 1
	print("Built a new ", building_name)
