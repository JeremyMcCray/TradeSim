extends MeshInstance3D
@onready var audio_player = $AudioStreamPlayer3D

@export var music: AudioStream


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
