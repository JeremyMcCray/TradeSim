extends Node

signal log_added(text: String, group: int, color: String)

# Predefined groups (optional)
enum LogGroup { NEUTRAL, WARN, GOOD }
const GROUP_COLORS = {
	LogGroup.NEUTRAL: "#00abc7",
	LogGroup.WARN: "#ffdd8b",
	LogGroup.GOOD: "#ffffff"
}

# Call this from anywhere to add a log
func add_log(text: String, group: LogGroup = LogGroup.NEUTRAL, color: String = "") -> void:
	var final_color = color if color != "" else GROUP_COLORS[group]
	emit_signal("log_added", text, group, final_color)
