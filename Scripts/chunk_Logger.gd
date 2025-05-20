extends RichTextLabel

# ChatUI.gd (or wherever your RichTextLabel is)
func _ready():
	LogBox.log_added.connect(_on_log_added)

func _on_log_added(msg: String, group: int, color: String):
	var formatted_text = "\n[color={0}]{1}[/color]".format([color, msg])
	self.text += formatted_text
