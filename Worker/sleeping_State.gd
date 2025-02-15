extends State
class_name Sleeping

func _ready():
	pass

func Enter():
	#Move toward house
	# when at house do nothing
	pass

func Exit():
	pass

func Update(_delta: float):
	#if Day time emit working
	transitioned.emit(self,"Working")
	pass

func Physics_Update(_delta: float):
	pass
