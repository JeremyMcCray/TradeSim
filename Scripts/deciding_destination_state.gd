extends State
class_name DecidingDestination

var script_user : CharacterBody2D
func _ready():
	script_user = get_parent().get_script_user()
	pass

func Enter():
	script_user.current_target = Global.villages.pick_random()
	transitioned.emit(self,"Traveling_State")
func Exit():
	pass

func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
