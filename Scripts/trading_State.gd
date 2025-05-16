extends State
class_name Trading

var script_user : CharacterBody3D
var villageInventory
var inventory
var trade_attempts = 5
var current_attempts = 0
var goods_config

func _ready():
	goods_config = load("res://configs/goods_config.json").get_data()
	script_user = get_parent().get_script_user()

func Enter():
	current_attempts = 0
	if script_user.inventory:
		inventory = script_user.inventory

func Exit():
	pass

func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	if current_attempts < trade_attempts:
		trade()
		current_attempts += 1
	else:
		transitioned.emit(self, "TravelingState")

func trade():
	villageInventory = script_user.current_target.inventory
	var village_gold = script_user.current_target.inventory["gold"]
	
	var size = villageInventory.size()
	if size == 0:
		return
	
	var trade_item = villageInventory.keys()[randi() % size]
	var item_key = trade_item.to_lower()
	
	if not goods_config.has(item_key):
		return
	
	var item_data = goods_config[item_key]
	var agent_price = script_user.prices.get(item_key, item_data.base_price)
	var village_price = script_user.current_target.prices.get(item_key, item_data.base_price)
	
	## Skip unprofitable trades
	#if abs(agent_price - village_price) < (item_data.base_price * 0.1):
		#return
	
	# Smart trade direction decision
	var price_ratio = agent_price / village_price
	var agent_buying = false
	
	if price_ratio > 1.2:
		agent_buying = true
	elif price_ratio < 0.8:
		agent_buying = false
	else:
		agent_buying = randf() > 0.5
	
	if agent_buying:
		if villageInventory.get(trade_item, 0) > 0 and script_user.inventory["gold"] >= village_price:
			villageInventory[trade_item] -= 1
			inventory[trade_item] = inventory.get(trade_item, 0) + 1
			script_user.inventory["gold"] -= village_price
			script_user.current_target.inventory["gold"] += village_price
			
			# Moderate price adjustments
			script_user.current_target.prices[item_key] = min(
				item_data.max_price,
				village_price * (1 + item_data.price_sensitivity * 0.3)
			)
			script_user.prices[item_key] = max(
				item_data.min_price,
				agent_price * (1 - item_data.price_sensitivity * 0.15)
			)
			print("Bought 1 ", trade_item, " for ", village_price, " gold (new prices - agent: ", 
				script_user.prices[item_key], ", village: ", script_user.current_target.prices[item_key], ")")
	else:
		if inventory.get(trade_item, 0) > 0 and village_gold >= agent_price:
			inventory[trade_item] -= 1
			villageInventory[trade_item] = villageInventory.get(trade_item, 0) + 1
			script_user.inventory["gold"] += agent_price
			script_user.current_target.inventory["gold"] -= agent_price
			
			script_user.prices[item_key] = min(
				item_data.max_price,
				agent_price * (1 + item_data.price_sensitivity * 0.15)
			)
			script_user.current_target.prices[item_key] = max(
				item_data.min_price,
				village_price * (1 - item_data.price_sensitivity * 0.3)
			)
			print("Sold 1 ", trade_item, " for ", agent_price, " gold (new prices - agent: ", 
			script_user.prices[item_key], ", village: ", script_user.current_target.prices[item_key], ")")
			print_inventory_value()

func print_inventory_value():
	if not script_user or not script_user.prices or not inventory:
		print("Cannot calculate inventory value - missing data")
		return
	
	var total_value = 0
	var item_values = {}
	
	# Calculate value for each item in inventory
	for item_name in inventory:
		var item_key = item_name.to_lower()
		var quantity = inventory[item_name]
		
		# Skip if item not in config or quantity is zero
		if not goods_config.has(item_key) or quantity <= 0:
			continue
			
		# Get current price (default to base price if not set)
		var price = script_user.prices.get(item_key, goods_config[item_key].base_price)
		var item_value = price * quantity
		
		item_values[item_name] = {
			"quantity": quantity,
			"unit_price": price,
			"total_value": item_value
		}
		total_value += item_value
	
	# Print detailed breakdown
	print("\n--- Inventory Valuation ---")
	for item_name in item_values:
		var data = item_values[item_name]
		print("%s: %d x %d = %d" % [
			item_name,
			data.quantity,
			data.unit_price,
			data.total_value
		])
	
	print("-----------------------")
	print("TOTAL INVENTORY VALUE: %d gold" % total_value)
	print("CURRENT GOLD: %d gold" % script_user.inventory["gold"])
	print("TOTAL NET WORTH: %d gold" % (total_value + script_user.inventory["gold"]))
	print("-----------------------\n")
	
	script_user.inv_label.text = """
-----------------------
TOTAL INVENTORY VALUE: %d gold
CURRENT GOLD: %d gold
TOTAL NET WORTH: %d gold
-----------------------
""" % [
		total_value,
		script_user.inventory["gold"],
		(total_value + script_user.inventory["gold"])
	]
