extends Node

signal new_day_started(day_number)
signal day_ended(day_number)

var current_day := 0
var day_duration := 30.0  # 2.5 minutes in seconds
var time_elapsed := 0.0
var is_paused := false

func _process(delta: float) -> void:
	if is_paused:
		return
		
	time_elapsed += delta
	if time_elapsed >= day_duration:
		end_day()
		
func end_day() -> void:
	emit_signal("day_ended", current_day)
	time_elapsed = 0.0
	current_day += 1
	emit_signal("new_day_started", current_day)
	
func pause_time() -> void:
	is_paused = true
	
func resume_time() -> void:
	is_paused = false
