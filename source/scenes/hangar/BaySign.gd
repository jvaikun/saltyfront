extends Spatial

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8

onready var p_color = $Viewport/Body/PilotInfo/Portrait/TeamColor
onready var p_face = $Viewport/Body/PilotInfo/Portrait/PilotFace
onready var p_name = $Viewport/Body/PilotInfo/PilotName

func update_sign(mech):
	if mech != null:
		var face_id = int(mech.pilot.face) 
		var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
		var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
		var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
		p_color.color = GameData.teamColors[mech.team]
		p_face.texture.set_region(faceArea)
		p_name.text = mech.pilot.name
