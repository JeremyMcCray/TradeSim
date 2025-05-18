extends Label

@export var display_text := "":
	set(value):
		display_text = value
		update_display()

func update_display():
	# Implement how your UI displays the text
	# For example, if you have a Label:
	self.text = display_text
