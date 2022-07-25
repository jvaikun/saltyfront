extends Spatial

const cam_home = {"pos":Vector3(0, 3, 9), "rot":Vector3(-15, 0, 0)}
const cam_points = [
	{"pos":Vector3(-1, 2, 5), "rot":Vector3(-15, 90, 0)},
	{"pos":Vector3(-1, 2, 1), "rot":Vector3(-15, 90, 0)},
	{"pos":Vector3(-1, 2, -3), "rot":Vector3(-15, 90, 0)},
	{"pos":Vector3(-1, 2, -7), "rot":Vector3(-15, 90, 0)},
	{"pos":Vector3(1, 2, -5), "rot":Vector3(-15, -90, 0)},
	{"pos":Vector3(1, 2, -1), "rot":Vector3(-15, -90, 0)},
	{"pos":Vector3(1, 2, 3), "rot":Vector3(-15, -90, 0)},
	{"pos":Vector3(1, 2, 7), "rot":Vector3(-15, -90, 0)},
]

onready var arms_top = $TopArms.get_children()
onready var arms_side = $SideArms.get_children()
onready var team1 = $Team1.get_children()
onready var team2 = $Team2.get_children()
onready var signs = $Signs.get_children()
onready var hangar_cam = $HangarView/HangarCam

export var debug = false

signal mechs_out


func _ready():
	for arm in arms_top:
		arm.top = true
	for light in $Lights.get_children():
		light.get_node("AnimationPlayer").play("normal")
	$AnimationPlayer.play("RESET")
	for mech in (team1 + team2):
		mech.get_node("mech_frame/AnimationPlayer").stop()
	if debug:
		reroll_all()


func _process(_delta):
	if debug:
		if Input.is_action_just_pressed("ui_screenshot"):
			GameData.screenshot()
		if Input.is_action_just_pressed("ui_end"):
			reroll_all()
		if Input.is_action_just_pressed("ui_accept"):
			move_out()


func load_mechs(team_list):
	var all_mechs = (team1 + team2)
	var all_data = (team_list[0].mechs + team_list[1].mechs)
	for i in all_mechs.size():
		all_mechs[i].team = all_data[i].team
		all_mechs[i].mechData = all_data[i]
		all_mechs[i].state = all_mechs[i].MechState.DONE
		all_mechs[i].setup(null)
		signs[i].update_sign(all_data[i])
	for arm in (arms_side + arms_top):
		arm._ready()


func update_hp(hp_list):
	var all_mechs = (team1 + team2)
	for i in all_mechs.size():
		if hp_list[i].body <= 0:
			all_mechs[i].bodyHP = 1
		else:
			all_mechs[i].bodyHP = hp_list[i].body
		all_mechs[i].armRHP = hp_list[i].arm_r
		all_mechs[i].armLHP = hp_list[i].arm_l
		all_mechs[i].legsHP = hp_list[i].legs
	for arm in (arms_side + arms_top):
		arm._ready()


func move_out():
	$CamTween.interpolate_property(hangar_cam, "translation", 
	hangar_cam.translation, cam_home.pos, 0.5)
	$CamTween.interpolate_property(hangar_cam, "rotation_degrees", 
	hangar_cam.rotation_degrees, cam_home.rot, 0.5)
	$CamTween.start()
	for light in $Lights.get_children():
		light.get_node("AnimationPlayer").play("warning")
	for arm in (arms_top + arms_side):
		arm.reset_arm()
	$AnimationPlayer.play("door_open")
	yield($AnimationPlayer, "animation_finished")
	for mech in (team1 + team2):
		mech.get_node("mech_frame/AnimationPlayer").play("walk")
	$AnimationPlayer.play("mechs_out")
	yield($AnimationPlayer, "animation_finished")
	emit_signal("mechs_out")


func move_cam(point):
	$CamTween.interpolate_property(hangar_cam, "translation", 
	hangar_cam.translation, cam_points[point].pos, 0.5)
	$CamTween.interpolate_property(hangar_cam, "rotation_degrees", 
	hangar_cam.rotation_degrees, cam_points[point].rot, 0.5)
	$CamTween.start()


func reroll_all():
	var all_mechs = team1 + team2
	for i in all_mechs.size():
		roll_stats(all_mechs[i])
		signs[i].update_sign(all_mechs[i].mechData)


func roll_stats(mech):
	var stats = MechStats.new()
	stats.id = 0
	stats.pilot = PartDB.drone[PartDB.drone.keys()[randi() % PartDB.drone.keys().size()]]
	var partSet = str(randi() % PartDB.body.size())
	stats.body = PartDB.body[partSet]
	stats.arm_r = PartDB.arm[partSet]
	stats.arm_l = PartDB.arm[partSet]
	stats.legs = PartDB.legs[partSet]
	var wpnSet = str(randi() % PartDB.weapon.size())
	stats.wpn_r = PartDB.weapon[wpnSet]
	stats.wpn_l = PartDB.weapon[wpnSet]
	var podSet = str(randi() % PartDB.pod.size())
	stats.pod_r = PartDB.pod[podSet]
	stats.pod_l = PartDB.pod[podSet]
	stats.pack = PartDB.pack[str(randi() % PartDB.pack.size())]
	# Attach stat block to mech
	mech.mechData = stats
	mech.setup(null)
