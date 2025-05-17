extends Node3D

@export var tick_timer: int = 200
@export var max_works : int = 20

var ready_to_work: bool = true
var tick: int = 0
var current_work_count = 0

func _ready() -> void:
	add_to_group("WorkableNode")

func work_node(gatherer) -> void:

	if ready_to_work:
		gatherer.add_to_inv("Food")
		gatherer.inv_count += 1
		ready_to_work = false
		current_work_count += 1
	
	if current_work_count >= max_works:
		print("farm is dea")

func _process(delta: float) -> void:
	if tick % tick_timer == 0:
		ready_to_work = true
	tick += 1
