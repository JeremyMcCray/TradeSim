extends State
class_name Trading

func _ready():
	pass

func Enter():
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
#Get Inventory from current village
#Decide Wants to buy/ wants to sell
#Haggle
#Add/Remove traded items
#Emit DecidingDestinationState
	transitioned.emit(self,"Working")
