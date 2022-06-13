extends Reference
class_name MechPod

var id : String = "0"
var name : String = "Default"
var model : String = "0"
var texture : String = "0"

var type : String = "missile"
var accuracy : float = 0.8
var acc_loss_h : float = 0.05
var acc_loss_v : float = 0.05
var damage : int = 10
var fire_rate : int = 1
var range_min : int = 1
var range_max : int = 3
var skill : String = "long"
var ammo : int = 2
var special : String = "none"
var spc_name : String = "none"

func get_data() -> Dictionary:
	var my_data : Dictionary = {}
	for prop in get_property_list():
		my_data[prop.name] = get(prop.name)
	return my_data
