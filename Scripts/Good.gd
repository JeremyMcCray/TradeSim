class_name Good
extends StaticBody3D

@export var good_name: String = "Generic Good"
@export var resource_paths: Array = []
@export var base_cost : int = 0
@export var tick_timer: int = 200

var ready_to_work: bool = true
var tick: int = 0

func _ready() -> void:
	if not resource_paths.is_empty():
		var packed = load(resource_paths[randi_range(0, resource_paths.size() - 1)])
		var tree = packed.instantiate()
		add_child(tree)
		tree.global_position = global_position
		tree.rotation = Vector3(0, randf(), 0)

func _process(delta: float) -> void:
	if tick % tick_timer == 0:
		ready_to_work = true
	tick += 1

func work_node(gatherer) -> void:
	if ready_to_work:
		gatherer.add_to_inv(good_name)
		gatherer.inv_count += 1
		ready_to_work = false
