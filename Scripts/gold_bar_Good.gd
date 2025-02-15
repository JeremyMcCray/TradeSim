extends StaticBody3D

var tick_timer = 600
var ready_to_work = true
var tick = 0
var good_name = "Gold_bar"

var goods_list = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var packed = load(goods_list[randi_range(0,goods_list.size()-1)])
	var goods = packed.instantiate()
	self.add_child(goods)
	goods.set_global_position(self.global_position)
	goods.rotation = Vector3(0,randf(),0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tick % tick_timer == 0:
		ready_to_work = true
	tick += 1

func work_node(gatherer):
	if ready_to_work == true:
		gatherer.add_to_inv(good_name)
		ready_to_work = false
