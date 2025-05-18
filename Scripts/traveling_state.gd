extends State
class_name Traveling

var script_user : CharacterBody3D

func _ready():
	script_user = get_parent().get_script_user()

func Enter():
	if Global and Global.villages:
		script_user.current_target = Global.villages.pick_random()
	else:
		script_user.current_target = script_user.village

func Exit():
	pass

func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	if script_user.current_target:
		if script_user.global_position.distance_to(script_user.current_target.global_position) < 5:
				transitioned.emit(self,"tradingstate")
		else:
			script_user.move_worker(script_user.current_target)
	else:
		script_user.current_target = Global.villages.pick_random()
