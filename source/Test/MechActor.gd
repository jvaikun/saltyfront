extends Spatial

onready var mech_parts = {
	"body":[
		{"point":$mech_frame/Armature/Skeleton/Body, 
		"model":"Torso", 
		"obj":null}
	],
	"pack":[
		{"point":$mech_frame/Armature/Skeleton/Body, 
		"model":"pack",
		"rotate":Vector3(0,180,0),
		"offset":Vector3(0, 0.3, -0.3),
		"obj":null}
	],
	"arm_l":[
		{"point":$mech_frame/Armature/Skeleton/PodL,
		"model":"ArmUp",
		"rotate":Vector3(-25,0,0),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/ArmLowL,
		"model":"ArmLow",
		"rotate":Vector3(-20,0,180),
		"obj":null},
	],
	"arm_r":[
		{"point":$mech_frame/Armature/Skeleton/PodR,
		"model":"ArmUp",
		"rotate":Vector3(-25,0,0),
		"flip":Vector3(0, 180, 0),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/ArmLowR,
		"model":"ArmLow",
		"rotate":Vector3(-20,0,180),
		"flip":Vector3(0, 180, 0),
		"obj":null},
	],
	"legs":[
		{"point":$mech_frame/Armature/Skeleton/Hip,
		"model":"Hip",
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegUpL,
		"model":"LegUp",
		"rotate":Vector3(-20,0,180),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegLowL,
		"model":"LegLow", 
		"rotate":Vector3(15,0,180),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/FootL, 
		"model":"Foot", 
		"rotate":Vector3(-60,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegUpR, 
		"model":"LegUp",
		"rotate":Vector3(-20,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegLowR, 
		"model":"LegLow",
		"rotate":Vector3(15,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/FootR, 
		"model":"Foot",
		"rotate":Vector3(-60,0,180), 
		"obj":null},
	],
	"wpn_l":[
		{"point":$mech_frame/Armature/Skeleton/WpnL,
		"model":"",
		"obj":null}
	],
	"pod_l":[
		{"point":$mech_frame/Armature/Skeleton/PodL,
		"model":"pod",
		"obj":null}
	],
	"wpn_r":[
		{"point":$mech_frame/Armature/Skeleton/WpnR,
		"model":"",
		"obj":null}
	],
	"pod_r":[
		{"point":$mech_frame/Armature/Skeleton/PodR,
		"model":"pod",
		"obj":null}
	],
}
onready var mech_anim = $mech_frame/AnimationPlayer
#onready var smoke = $Effects/Smoke
onready var sparks = {
	"body":$mech_frame/Armature/Skeleton/Body/Sparks,
	"arm_r":$mech_frame/Armature/Skeleton/PodR/Sparks,
	"arm_l":$mech_frame/Armature/Skeleton/PodL/Sparks,
	"legs":$mech_frame/Armature/Skeleton/Hip/Sparks,
}
#onready var cam_point = $CamPoint

var move_target
var attack_target

signal turn_done

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func setup():
	pass


func move():
	attack()


func attack():
	yield(get_tree().create_timer(0.25), "timeout")
	emit_signal("turn_done")
