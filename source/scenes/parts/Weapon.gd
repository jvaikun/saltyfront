extends Spatial

var sfx_shoot = []
var sfx_aim = []


# Called when the node enters the scene tree for the first time.
func _ready():
	sfx_shoot = $SFXShoot.get_resource_list()
	sfx_aim = $SFXAim.get_resource_list()


func start_loop():
	$SoundPlayer.stream = $SFXAim.get_resource(sfx_aim[randi() % sfx_aim.size()])
	$SoundPlayer.play()
	$Eject.emitting = true


func shoot():
	var flash_scale = 0.8 + (randi() % 4 * 0.2)
	$Muzzle.scale = Vector3(flash_scale, flash_scale, 1)
	$Muzzle.show()
	$SoundPlayer.stream = $SFXShoot.get_resource(sfx_shoot[randi() % sfx_shoot.size()])
	$SoundPlayer.play()
	yield(get_tree().create_timer(0.1), "timeout")
	$Muzzle.hide()


func end_loop():
	$Eject.emitting = false
	$Muzzle.hide()

