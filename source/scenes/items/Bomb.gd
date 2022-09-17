extends Spatial

const TYPE_LIST = {
	"acid":{"wave_color":Color(0, 1, 0), "model_color":Color(0, 1, 0)},
	"burn":{"wave_color":Color(1, 0.5, 0), "model_color":Color(1, 0, 0)},
	"chaff":{"wave_color":Color(1, 1, 1), "model_color":Color(0.8, 0.8, 0.8)},
	"smoke":{"wave_color":Color(0.5, 0.5, 0.5), "model_color":Color(0.5, 0.5, 0.5)}
}

var curr_tile = null
var type = "burn" setget set_type
var explode_radius = Vector3(4, 0.25, 4)

signal exploded(pos, size, type)


func set_type(value):
	if value in TYPE_LIST.keys():
		type = value
		$Wave.material_override.albedo_color = TYPE_LIST[type].wave_color
		$Model/Box.material_override.albedo_color = TYPE_LIST[type].model_color


# Called when the node enters the scene tree for the first time.
func _ready():
	self.type = "burn"
	add_to_group("explosive")


func explode():
	$Tween.interpolate_property($Wave, "scale", Vector3(1, 0.25, 1), explode_radius, 0.2)
	$Model.hide()
	$Wave.show()
	$Tween.start()
	emit_signal("exploded", curr_tile.index, explode_radius.x / 2, type)


func _on_Tween_tween_all_completed():
	queue_free()
