extends PanelContainer

# Editor variables
export(Texture) var char_face
export(String) var char_name

# Accessor variables
onready var message = $Body/Message/Text
onready var pilot_face = $Body/Message/PilotInfo/Portrait/PilotFace
onready var pilot_name = $Body/Message/PilotInfo/PilotName


# Called when the node enters the scene tree for the first time.
func _ready():
	pilot_face.texture = char_face
	pilot_name.text = char_name


func set_text(text: String):
	message.text = text


func play_msg(text: String, speed: float):
	visible = true
	message.text = text
	rect_size = rect_min_size
	$Tween.interpolate_property(message, "percent_visible", 0, 1, speed)
	$Tween.start()

