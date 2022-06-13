extends Spatial

const obj_explosion = preload("res://Effects/firework/Explosion.tscn")

onready var body = $Body

func explode():
	$Body.visible = false
	var inst_explode = obj_explosion.instance()
	$Position3D.add_child(inst_explode)
	inst_explode.scale = Vector3.ONE * 0.5
