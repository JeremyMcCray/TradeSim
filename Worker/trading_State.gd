extends State
class_name Trading

var scriptUser : CharacterBody2D
var villageInventory
var inventory

func _ready():
	scriptUser = get_parent().get_script_user()
	pass

func Enter():
	inventory = scriptUser.inventory
	pass

func Exit():
	pass

func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass

#Get Inventory from current village
#Decide Wants to buy/ wants to sell
#Haggle
#Add/Remove traded items
#Emit DecidingDestinationState

func trade():
	villageInventory = scriptUser.currentVillage.inventory
	var itemsToTrade = decideExchangeableGoods()
	
	scriptUser.currentVillage.offer(itemsToTrade)
#Get Inventory from current village
#Decide Wants to buy/ wants to sell
#Haggle
#Add/Remove traded items
#Emit DecidingDestinationState
	transitioned.emit(self,"DecidingDestination_State")

func decideExchangeableGoods():
	pass
	
