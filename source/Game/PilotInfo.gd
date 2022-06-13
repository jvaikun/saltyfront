extends MarginContainer

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8

# Label accessor vars
onready var p_face = $Body/Portrait/PilotFace
onready var p_color = $Body/Portrait/TeamColor
onready var p_name = $Body/Name


func set_focus(mech):
	if mech != null:
		var face_id = int(mech.pilot.face) 
		var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
		var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
		var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
		p_color.color = GameData.teamColors[mech.team]
		p_face.texture.set_region(faceArea)
		p_face.modulate = Color(1,1,1)
		p_name.text = mech.pilot.name
	else:
		p_face.modulate = Color(0, 0, 0)
