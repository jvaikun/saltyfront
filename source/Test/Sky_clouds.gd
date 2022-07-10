extends Spatial

var rotate_y = Vector3(0,1,0)
var rotSpeed = 0.01 # How fast the clouds rotate.

func _physics_process(delta):
	rotate_y(delta*rotSpeed)
