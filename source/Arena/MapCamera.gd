extends Spatial

# Constants
enum CamState {NORMAL, DEBUG, PHOTO}
const configs = [
	{ # NORMAL state
		"zoom_min":5.0, 
		"zoom_max":15.0,
		"zoom_mod":1.5,
		"arm_length":20,
		"base_pitch":-30.0,
		"base_yaw":45.0
	},
	{ # DEBUG state
		"zoom_min":20.0, 
		"zoom_max":20.0,
		"zoom_mod":1.5, 
		"arm_length":50,
		"base_pitch":-90.0,
		"base_yaw":0.0
	},
	{ # PHOTO state
		"zoom_min":5.0, 
		"zoom_max":10.0,
		"zoom_mod":1.0,
		"arm_length":20,
		"base_pitch":-30.0,
		"base_yaw":45.0
	},
]
const ROTATION_SPEED = 6.0
const MOVEMENT_SPEED = 6.0
const TWEEN_TIME = 3.0
const TWEEN_TIME_FAST = 2.0

# Accessor vars
onready var pivot = $Pivot
onready var cam = $Pivot/Camera

# Camera variables
var cam_mode = CamState.NORMAL setget set_mode
var cam_above = Vector3(0, 25, 0)
var origin = Vector3.ZERO
var pitch = configs[cam_mode].base_pitch
var yaw = configs[cam_mode].base_yaw
var tween_done = true
var cam_effect = null

func set_mode(value):
	cam.translation = Vector3(0, 0, configs[value].arm_length)
	cam.size = configs[value].zoom_max
	pitch = configs[value].base_pitch
	yaw = configs[value].base_yaw
	cam_mode = value
	set_angles()

func _ready():
	var err = $Tween.connect("tween_all_completed", self, "move_done")
	if err != OK:
		print("Error connecting camera to camera tween!")
	cam.size = configs[cam_mode].zoom_max
	set_angles()

func intro():
	cam.size = configs[cam_mode].zoom_max
	tween_done = false
	var rotate_to = self.rotation_degrees
	rotate_to.y += 360
	var time = TWEEN_TIME
	if GameData.fast_combat:
		time = TWEEN_TIME_FAST
	$Tween.interpolate_property(self, "translation",
	origin + cam_above, origin, time)
	$Tween.start()

func outro():
	cam.size = configs[cam_mode].zoom_max
	tween_done = false
	var rotate_to = self.rotation_degrees
	rotate_to.y += 360
	var time = TWEEN_TIME
	if GameData.fast_combat:
		time = TWEEN_TIME_FAST
	$Tween.interpolate_property(self, "translation",
	origin, origin + cam_above, time)
	$Tween.start()

func move_done():
	tween_done = true
	set_angles()

func follow_mech(mech):
	if tween_done:
		var next_pos = mech.translation
		var next_zoom = configs[cam_mode].zoom_max
		if is_instance_valid(mech.attack_target):
			var distance = mech.attack_target.translation - mech.translation
			next_pos = mech.translation + distance * 0.5
			next_zoom = max(configs[cam_mode].zoom_min, distance.length() * configs[cam_mode].zoom_mod)
		$ZoomTween.stop_all()
		$ZoomTween.interpolate_property(
			self, "translation", 
			translation, next_pos, 0.25)
		$ZoomTween.interpolate_property(
			cam, "size", 
			cam.size, next_zoom, 0.25)
		$ZoomTween.resume_all()


func set_angles():
	rotation_degrees.y = yaw
	pivot.rotation_degrees.x = pitch

func zero_angles():
	yaw = 0
	pitch = 0
	set_angles()

func reset_angles():
	cam.translation = Vector3(0, 0, configs[cam_mode].arm_length)
	pitch = configs[cam_mode].base_pitch
	yaw = configs[cam_mode].base_yaw
	set_angles()

func get_tile():
	var tap = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(tap)
	var to = from + cam.project_ray_normal(tap) * 10000
	var space_state = get_world().direct_space_state
	var coll_pos = space_state.intersect_ray(from, to, [], 1).get("position")
	return coll_pos
