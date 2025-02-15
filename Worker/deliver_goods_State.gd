extends State
class_name Deliver_Goods

var script_user
var village 
var deliver_range = 2
var direction

func _ready():
	script_user = get_parent().get_script_user()
	village = script_user.get_village()
	pass

func Enter():
	#Go to house
	script_user.destination = village.global_position
	pass

func Exit():
	pass

func Update(_delta: float):
	if script_user.global_position.distance_to(village.global_position) < deliver_range:
			village.deliver_goods(script_user)
	else:
		script_user.animation_player.stop()
		script_user.move_worker(village)
	if script_user.inventory.is_empty():
		script_user.animation_player.stop()
		await get_tree().create_timer(1.0).timeout
		transitioned.emit(self,"working_state")
