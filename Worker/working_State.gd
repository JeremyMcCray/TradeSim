extends State
class_name Working

var workable_nodes = []
var current_node

var current_attemps = 0
var max_attmepts = 5
var work_range = 3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var script_user
var direction

func _ready():
	script_user = get_parent().get_script_user()

func Enter():
	current_attemps = 0
	var temp = get_parent().get_parent().get_parent().get_children()

	for node in temp:
		if node.is_in_group("WorkableNode"):
			workable_nodes.append(node)
	
	if workable_nodes.size() > 0:
		current_node = workable_nodes[randi_range(0,workable_nodes.size() - 1)]


func Update(_delta: float):
	if script_user.inv_count >= script_user.max_inv:
		transitioned.emit(self,"deliver_goods_state")
	
	if current_node:
		script_user.destination = current_node.global_position
		if script_user.global_position.distance_to(current_node.global_position) < work_range:
			script_user.animation_player.play("work")
			current_node.work_node(script_user)
		else:
			script_user.move_worker(current_node)
	else:
		target_nodes()
		if workable_nodes.size() == 0 and current_attemps == max_attmepts:
			#emit signal go to sleep
			transitioned.emit(self,"Sleeping")

func target_nodes():
	var temp = get_parent().get_parent().get_parent().get_children()
	for node in temp:
		if node.is_in_group("WorkableNode"):
			workable_nodes.append(node)
	
	if workable_nodes.size() > 0:
		current_node = workable_nodes[randi_range(0,workable_nodes.size() - 1)]
