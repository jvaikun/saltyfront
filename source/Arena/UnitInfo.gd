extends PanelContainer

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8

# Accessor variables for UI elements
onready var pilot_face = $Body/Portrait
onready var pilot_name = $Body/StatBlock/NameTag/PilotName
onready var t_color = $Body/StatBlock/NameTag/TeamColor
onready var bar_body = $Body/StatBlock/MechHP/HPBarBody
onready var num_body = $Body/StatBlock/MechHP/HPNumBody
onready var bar_armr = $Body/StatBlock/MechHP/HPBarArmR
onready var num_armr = $Body/StatBlock/MechHP/HPNumArmR
onready var bar_arml = $Body/StatBlock/MechHP/HPBarArmL
onready var num_arml = $Body/StatBlock/MechHP/HPNumArmL
onready var bar_legs = $Body/StatBlock/MechHP/HPBarLegs
onready var num_legs = $Body/StatBlock/MechHP/HPNumLegs

var focus_mech = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_info(mech):
	focus_mech = mech
	if is_instance_valid(focus_mech):
		$Body.visible = true
		$NoUnit.visible = false
		var face_id = int(focus_mech.mechData.pilot.face) 
		var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
		var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
		var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
		pilot_face.texture.set_region(faceArea)
		pilot_name.text = focus_mech.mechData.pilot.name
		t_color.modulate = GameData.teamColors[focus_mech.team]
		bar_body.max_value = focus_mech.mechData.body.hp
		bar_body.value = focus_mech.bodyHP
		num_body.text = str(bar_body.value)
		bar_armr.max_value = focus_mech.mechData.arm_r.hp
		bar_armr.value = focus_mech.armRHP
		num_armr.text = str(bar_armr.value)
		bar_arml.max_value = focus_mech.mechData.arm_l.hp
		bar_arml.value = focus_mech.armLHP
		num_arml.text = str(bar_arml.value)
		bar_legs.max_value = focus_mech.mechData.legs.hp
		bar_legs.value = focus_mech.legsHP
		num_legs.text = str(bar_legs.value)
	else:
		$Body.visible = false
		$NoUnit.visible = true
