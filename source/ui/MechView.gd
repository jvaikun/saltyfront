extends PanelContainer

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8
const icon_w = 64
const icon_h = 16
const ICONS = {
	"melee":preload("res://ui/icons/icon_melee.png"),
	"mgun":preload("res://ui/icons/icon_mgun.png"),
	"sgun":preload("res://ui/icons/icon_sgun.png"),
	"rifle":preload("res://ui/icons/icon_rifle.png"),
	"flame":preload("res://ui/icons/icon_flame.png"),
	"missile":preload("res://ui/icons/icon_missile.png"),
}
const types = ["mgun", "rifle", "sgun", "flame", "grenade", "missile"]
const txt_header = "%s %d\n%s"
const txt_weapon = "%s\n%s : %d x %d\nAmmo: %s"

# Accessor variables for UI elements
onready var wpn_info = $MechWeapon/WeaponInfo/WeaponText
onready var wpn_icon = $MechWeapon/WeaponInfo/WeaponIcon

onready var pilot_color = $MechPilot/PilotInfo/Portrait/TeamColor
onready var pilot_face = $MechPilot/PilotInfo/Portrait/PilotFace
onready var pilot_name = $MechPilot/PilotInfo/PilotName

onready var bar_body = $MechHP/HPGrid/HPBarBody
onready var bar_armr = $MechHP/HPGrid/HPBarArmR
onready var bar_arml = $MechHP/HPGrid/HPBarArmL
onready var bar_legs = $MechHP/HPGrid/HPBarLegs
onready var cam_pov = $ViewBox/Viewport/ChaseCam

var focus_mech = null
var curr_wpn = null


func update_info(mech):
	focus_mech = mech
	curr_wpn = focus_mech.attack_wpn
	if is_instance_valid(focus_mech):
		cam_pov.global_transform = focus_mech.cam_point.global_transform
		cam_pov.rotation_degrees.y += 180
		var face_id = int(focus_mech.mechData.pilot.face) 
		var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
		var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
		var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
		pilot_color.color = GameData.teamColors[focus_mech.team]
		pilot_face.texture.set_region(faceArea)
		pilot_name.text = (txt_header % [
			GameData.teamNames[focus_mech.team],
			focus_mech.num,
			focus_mech.mechData.pilot.name]).to_upper()
		bar_body.max_value = focus_mech.mechData.body.hp
		bar_body.value = focus_mech.bodyHP
		bar_armr.max_value = focus_mech.mechData.arm_r.hp
		bar_armr.value = focus_mech.armRHP
		bar_arml.max_value = focus_mech.mechData.arm_l.hp
		bar_arml.value = focus_mech.armLHP
		bar_legs.max_value = focus_mech.mechData.legs.hp
		bar_legs.value = focus_mech.legsHP
	if curr_wpn != null:
		wpn_icon.texture = ICONS[curr_wpn.type]
		if "ammo" in curr_wpn:
			wpn_info.text = txt_weapon % [
				curr_wpn.name,
				curr_wpn.type,
				curr_wpn.fire_rate,
				curr_wpn.damage,
				str(curr_wpn.ammo)]
		else:
			wpn_info.text = txt_weapon % [
				curr_wpn.name,
				curr_wpn.type,
				curr_wpn.fire_rate,
				curr_wpn.damage,
				"N/A"]


func night_mode_on():
	cam_pov.environment = load("res://scenes/maps/env_nightvision.tres")
