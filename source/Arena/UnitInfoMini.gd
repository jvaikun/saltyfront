extends PanelContainer

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8

# Accessor vars
onready var p_status = $Items/VisualCont/VisualList
onready var p_color = $Items/VisualCont/VisualList/Portrait/TeamColor
onready var p_face = $Items/VisualCont/VisualList/Portrait/PilotFace
onready var p_dead = $Items/VisualCont/Dead
onready var p_name = $Items/PilotName
onready var highlight = $Highlight
onready var dmg_body = $Items/VisualCont/VisualList/MechDmg/BodyDmg
onready var dmg_armr = $Items/VisualCont/VisualList/MechDmg/ArmRDmg
onready var dmg_arml = $Items/VisualCont/VisualList/MechDmg/ArmLDmg
onready var dmg_legs = $Items/VisualCont/VisualList/MechDmg/LegsDmg
onready var mech_tag = $MechTag/Tag
onready var mech_num = $MechTag/Label

# Local vars
var focus_mech = null
var focus = false

func update_data():
	if !focus_mech.is_dead and focus_mech != null:
		p_status.visible = !focus_mech.is_dead
		p_dead.visible = focus_mech.is_dead
		if !focus_mech.is_dead:
			highlight.visible = focus
			mech_tag.modulate = GameData.teamColors[focus_mech.team]
			mech_num.text = str(focus_mech.num)
			var face_id = int(focus_mech.mechData.pilot.face) 
			var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
			var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
			var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
			p_color.color = GameData.teamColors[focus_mech.team]
			self_modulate = GameData.teamColors[focus_mech.team]
			p_face.texture.set_region(faceArea)
			p_name.text = focus_mech.mechData.pilot.name
			dmg_body.modulate = get_condition(focus_mech.bodyHP, focus_mech.mechData.body.hp)
			dmg_armr.modulate = get_condition(focus_mech.armRHP, focus_mech.mechData.arm_r.hp)
			dmg_arml.modulate = get_condition(focus_mech.armLHP, focus_mech.mechData.arm_l.hp)
			dmg_legs.modulate = get_condition(focus_mech.legsHP, focus_mech.mechData.legs.hp)
		else:
			highlight.visible = false
	else:
		p_status.visible = false
		p_dead.visible = true
		highlight.visible = false

func get_condition(hp, max_hp):
	if hp > 0:
		var percent = float(hp) / max_hp
		if percent >= 0.5:
			return Color(0, 1, 0)
		elif percent >= 0.25:
			return Color(1, 1, 0)
		else:
			return Color(1, 0, 0)
	else:
		return Color(0.5, 0.5, 0.5)
