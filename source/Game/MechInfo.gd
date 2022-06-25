extends PanelContainer

# Texture atlas constants
const FACE_WIDTH = 64
const FACE_HEIGHT = 80
const ATLAS_WIDTH = 8
const PORT_SIZE = 72
const ICONS = {
	"melee":preload("res://ui/icons/icon_melee.png"),
	"mgun":preload("res://ui/icons/icon_mgun.png"),
	"sgun":preload("res://ui/icons/icon_sgun.png"),
	"rifle":preload("res://ui/icons/icon_rifle.png"),
	"flame":preload("res://ui/icons/icon_flame.png"),
	"missile":preload("res://ui/icons/icon_missile.png"),
	"pack":preload("res://ui/icons/icon_pack.png"),
}

# Label accessor vars
onready var info_wpnl = $Stats/MechStats/PartList/InfoWpnL
onready var info_wpnr = $Stats/MechStats/PartList/InfoWpnR
onready var info_podl = $Stats/MechStats/PartList/InfoPodL
onready var info_podr = $Stats/MechStats/PartList/InfoPodR
onready var info_pack = $Stats/MechStats/PartList/InfoPack

# Label accessor vars
onready var p_face = $Stats/PilotDetail/Portrait/PilotFace
onready var p_color = $Stats/PilotDetail/Portrait/TeamColor
onready var p_name = $Stats/PilotName/Name
onready var t_name = $Stats/PilotName/Team
onready var t_color = $Stats/PilotName/TeamColor
onready var melee_bar = $Stats/PilotDetail/PilotData/Bar
onready var melee = $Stats/PilotDetail/PilotData/Melee
onready var short_bar = $Stats/PilotDetail/PilotData/Bar2
onready var short = $Stats/PilotDetail/PilotData/Short
onready var long_bar = $Stats/PilotDetail/PilotData/Bar3
onready var long = $Stats/PilotDetail/PilotData/Long
onready var dodge_bar = $Stats/PilotDetail/PilotData/Bar4
onready var dodge = $Stats/PilotDetail/PilotData/Dodge
onready var hp = $Stats/PilotDetail/MechData/HP
onready var defense = $Stats/PilotDetail/MechData/Defense
onready var m_dodge = $Stats/PilotDetail/MechData/Dodge

# Object vars
var focus_mech = null


func update_info():
	if focus_mech != null:
		var face_id = int(focus_mech.pilot.face) 
		var faceX = (face_id % ATLAS_WIDTH) * FACE_WIDTH
		var faceY = (face_id / ATLAS_WIDTH) * FACE_HEIGHT
		var faceArea = Rect2(faceX, faceY, FACE_WIDTH, FACE_HEIGHT)
		p_color.color = GameData.teamColors[focus_mech.team]
		p_face.texture.set_region(faceArea)
		p_name.text = focus_mech.pilot.name
		t_color.modulate = GameData.teamColors[focus_mech.team]
		t_name.text = GameData.teamNames[focus_mech.team].capitalize()
		melee_bar.value = focus_mech.pilot.melee
		melee.text = str(focus_mech.pilot.melee)
		short_bar.value = focus_mech.pilot.short
		short.text = str(focus_mech.pilot.short)
		long_bar.value = focus_mech.pilot.long
		long.text = str(focus_mech.pilot.long)
		dodge_bar.value = focus_mech.pilot.dodge
		dodge.text = str(focus_mech.pilot.dodge)
		hp.text = str(focus_mech.body.hp + focus_mech.arm_r.hp + focus_mech.arm_l.hp + focus_mech.legs.hp)
		defense.text = str(round((focus_mech.body.defense + focus_mech.arm_r.defense + focus_mech.arm_l.defense + focus_mech.legs.defense)/4))
		m_dodge.text = str((focus_mech.body.dodge + focus_mech.arm_r.dodge + focus_mech.arm_l.dodge + focus_mech.legs.dodge) * 100) + "%"
		# Set part data
		var partData = [
			{"part":"pod_l", "info":info_podl, "title":"LEFT SHOULDER", "arm":"arm_l"},
			{"part":"wpn_l", "info":info_wpnl, "title":"LEFT WEAPON", "arm":"arm_l"},
			{"part":"pack", "info":info_pack, "title":"BACKPACK", "arm":"arm_l"},
			{"part":"wpn_r", "info":info_wpnr, "title":"RIGHT WEAPON", "arm":"arm_r"},
			{"part":"pod_r", "info":info_podr, "title":"RIGHT SHOULDER", "arm":"arm_r"}
			]
		# Set up part sprites using parameters
		for item in partData:
			item.info.head.text = item.title
			item.info.body.text = focus_mech[item.part].name + "\n" 
			if item.part in ["pod_l", "pod_r", "wpn_l", "wpn_r"]:
				item.info.icon.texture = ICONS[focus_mech[item.part].type]
				item.info.body.text += (str(focus_mech[item.part].damage) + " DMG x " + 
				str(focus_mech[item.part].fire_rate) + "\n")
				if focus_mech[item.part].spc_name != "none":
					item.info.body.text += (focus_mech[item.part].spc_name + 
					", " + str(focus_mech.pilot[focus_mech[item.part].skill]) + "%\n")
			else:
				item.info.icon.texture = ICONS.pack


func set_view(view_tex):
	$Stats/MechStats/HangarView.texture = view_tex
