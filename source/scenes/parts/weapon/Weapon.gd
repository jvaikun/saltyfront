extends Spatial

const bullet_obj = preload("res://scenes/projectile/Bullet.tscn")
const missile_obj = preload("res://scenes/projectile/MissileLarge.tscn")
const projectiles = {
	"melee": {"bullet": bullet_obj, "speed": 20, "spread": 0},
	"sgun": {"bullet": bullet_obj, "speed": 20, "spread": 0.4},
	"flame": {"bullet": bullet_obj, "speed": 30, "spread": 0.4},
	"missile": {"bullet": missile_obj, "speed": 20, "spread": 0},
	"mgun": {"bullet": bullet_obj, "speed": 30, "spread": 0.6},
	"rifle": {"bullet": bullet_obj, "speed": 30, "spread": 0.2}
}

onready var mesh = $Mesh

var sfx_shoot = []
var sfx_aim = []
var id : String = "0"
var wpn_name : String = "Default"
var model : String = "0"
var texture : String = "0"

var type : String = "mgun"
var accuracy : float = 0.8
var acc_loss_h : float = 0.05
var acc_loss_v : float = 0.05
var damage : int = 10
var fire_rate : int = 1
var range_min : int = 1
var range_max : int = 3
var skill : String = "short"
var special : String = "none"
var spc_name : String = "none"

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

