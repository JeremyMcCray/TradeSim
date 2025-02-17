extends StaticBody3D

var tick_timer = 200
var ready_to_work = true
var tick = 0

var goods_list = ["res://assets/Trees/detail_tree_a.tscn", "res://assets/Trees/detail_tree_b.tscn", "res://assets/Trees/detail_tree_c.tscn"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var packed = load(goods_list[randi_range(0,goods_list.size()-1)])
	var goods = packed.instantiate()
	self.add_child(goods)
	goods.set_global_position(Vector3(self.global_position.x,self.global_position.y - 1,self.global_position.z))
	goods.rotation = Vector3(0,randf(),0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tick % tick_timer == 0:
		ready_to_work = true
	tick += 1

func work_node(gatherer):
	if ready_to_work == true:
		gatherer.add_to_inv("Wood")
		ready_to_work = false
