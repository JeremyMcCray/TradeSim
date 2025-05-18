extends Control

var chatLog : RichTextLabel

var groups = [
	{'name': 'Neutral', 'color': '#00abc7'},#TODO These colors need to be changed to match the name but o well
	{'name': 'Warn', 'color': '#ffdd8b'},
	{'name': 'Good', 'color': '#ffffff'}
]

func _ready() -> void:
	chatLog = RichTextLabel.new()
	chatLog.bbcode_enabled = true
	chatLog.scroll_active = true
	chatLog.scroll_following = true
	chatLog.custom_minimum_size = Vector2(400,160)
	chatLog.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(chatLog)

func add_message(username, message_text, group = 0, color = ''):
	print(message_text)
	chatLog.text += '\n' 
	if color == '':
		chatLog.text += '[color=' + groups[group]['color'] + ']'
	else:
		chatLog.text += '[color=' + color + ']'
	if username != '':
		chatLog.text += '[' + username + ']: '
	chatLog.text += message_text
	chatLog.text += '[/color]'
