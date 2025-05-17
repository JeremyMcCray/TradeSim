extends Node

# Add these new variables to track hunger state
@export var MAX_HUNGER := 3  # Days without food before dying
var current_hunger := 0
var is_starving := false
var is_alive := true
var parent

func _ready() -> void:
	parent = get_parent()

func eat():
	# Try to eat from personal inventory first
	if parent.inventory.has("Food") and parent.inventory["Food"] > 0:
		parent.inventory["Food"] -= 1
		is_starving = false
		print("Ate food from personal inventory")
		current_hunger = 0
		return
		
	# Try to eat from village inventory
	if parent.village and parent.village.has_method("consume_food"):
		if parent.village.consume_food(1):  # Assume this returns bool for success
			is_starving = false
			print("Ate food from village storage")
			current_hunger = 0
			return
	
	if is_starving and current_hunger > MAX_HUNGER:
		die()
	# No food available
	is_starving = true
	current_hunger += 1
	print("No food available, Current Hunger Level: " + str(current_hunger))

func die():
	is_alive = false
	print("Worker has died from starvation!")
	
	# Disable movement and other functionality
	set_physics_process(false)
	
	### Play death animation if available
	##if animation_player.has_animation("die"):
		##animation_player.play("die")
	#else:
	parent.queue_free()  # Remove from game if no death animation
