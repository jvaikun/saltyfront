extends KinematicBody

var velocity = Vector3.ZERO
var grav = Vector3.DOWN
var object = null
var kill = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if kill:
		queue_free()
	elif velocity != Vector3.ZERO:
		velocity += grav * delta
		var _vel = move_and_slide(velocity, Vector3.UP)
		if is_on_floor():
			kill = true

func launch(end_point):
	var time = 0.5
	var max_height = 2
	var diff = (end_point.global_transform.origin - self.global_transform.origin)
	var diff_h = Vector3(diff.x, 0, diff.z)
	var a = self.global_transform.origin.y
	var b = max_height
	var c = end_point.global_transform.origin.y
	var speed = diff_h.length() / time
	var gravity = -4*(a - 2*b + c) / (time * time)
	grav = Vector3(0, -gravity, 0)
	velocity = diff_h.normalized() * speed
	velocity.y = -(3*a - 4*b + c) / time
