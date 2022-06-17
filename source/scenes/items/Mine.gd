extends Spatial

var obj_explosion = preload("res://Effects/Explosion.tscn")
var curr_tile = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#visible = false
	add_to_group("mine")

func detonate(target):
	var explosion = obj_explosion.instance()
	self.add_child(explosion)
	var sound = "explode_lg" + str(randi() % $Sounds.get_resource_list().size())
	$Explosion.stream = $Sounds.get_resource(sound)
	$Explosion.play()
	for part in ["body", "arm_r", "arm_l", "legs"]:
		target.damage({"type":"mine", "part":part, "dmg":50, "crit":1})
	yield(explosion, "tree_exited")
	self.queue_free()
