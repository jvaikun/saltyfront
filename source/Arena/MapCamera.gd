extends Spatial

# Constants
enum CamState {NORMAL, DEBUG, PHOTO}

const ROTATION_SPEED = 6.0
const MOVEMENT_SPEED = 6.0
const TWEEN_TIME = 3.0
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
		"zoom_max":40.0,
		"zoom_mod":1.5, 
		"arm_length":50,
		"base_pitch":-90.0,
		"base_yaw":0.0
	},
	{ # PHOTO state
		"zoom_min":1.0, 
		"zoom_max":50.0,
		"zoom_mod":1.0,
		"arm_length":20,
		"base_pitch":-30.0,
		"base_yaw":45.0
	},
]

# Accessor vars
onready var yaw_node = $Yaw
onready var pitch_node = $Yaw/Pitch
onready var cam = $Yaw/Pitch/Camera

# Camera variables
var cam_mode = CamState.NORMAL setget set_mode
var yaw = configs[cam_mode].base_yaw setget set_yaw
var pitch = configs[cam_mode].base_pitch setget set_pitch
var zoom = configs[cam_mode].zoom_max setget set_zoom
var cam_above = Vector3(0, 25, 0)
var origin = Vector3.ZERO
var tween_done = true


func set_mode(value):
	cam_mode = value
	match cam_mode:
		CamState.DEBUG:
			cam.projection = Camera.PROJECTION_ORTHOGONAL
		CamState.NORMAL:
			cam.projection = Camera.PROJECTION_ORTHOGONAL
		CamState.PHOTO:
			cam.projection = Camera.PROJECTION_PERSPECTIVE
	cam.translation = Vector3(0, 0, configs[cam_mode].arm_length)
	cam.size = configs[cam_mode].zoom_max
	self.yaw = configs[cam_mode].base_yaw
	self.pitch = configs[cam_mode].base_pitch


func set_yaw(value):
	yaw = value
	yaw_node.rotation_degrees.y = yaw


func set_pitch(value):
	pitch = value
	pitch_node.rotation_degrees.x = pitch
	#pitch_node.rotation_degrees.x = clamp(cam_pivot.rotation_degrees.x, PITCH_MIN, PITCH_MAX)


func set_zoom(value):
	var clamped = clamp(value, configs[cam_mode].zoom_min, configs[cam_mode].zoom_max)
	if cam_mode == CamState.PHOTO:
		cam.translation = Vector3(0, 0, clamped)
	else:
		cam.size = clamped


func _ready():
	var err = $Tween.connect("tween_all_completed", self, "move_done")
	if err != OK:
		print("Error connecting camera to camera tween!")
	self.cam_mode = CamState.NORMAL


func intro():
	cam.size = configs[cam_mode].zoom_max
	tween_done = false
	$Tween.interpolate_property(self, "translation",
	origin + cam_above, origin, TWEEN_TIME)
	$Tween.start()


func outro():
	cam.size = configs[cam_mode].zoom_max
	tween_done = false
	$Tween.interpolate_property(self, "translation",
	origin, origin + cam_above, TWEEN_TIME)
	$Tween.start()


func move_done():
	tween_done = true


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


func get_tile():
	var tap = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(tap)
	var to = from + cam.project_ray_normal(tap) * 10000
	var space_state = get_world().direct_space_state
	var coll_pos = space_state.intersect_ray(from, to, [], 1).get("position")
	return coll_pos
