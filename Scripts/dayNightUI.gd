extends Control

@onready var day_label := $DayLabel
@onready var time_progress := $TimeProgress

func _ready() -> void:
	TimeManager.new_day_started.connect(update_day)
	update_day(TimeManager.current_day)

func _process(_delta: float) -> void:
	time_progress.value = (TimeManager.time_elapsed / TimeManager.day_duration) * 100

func update_day(day: int) -> void:
	day_label.text = "Day: %d" % day
