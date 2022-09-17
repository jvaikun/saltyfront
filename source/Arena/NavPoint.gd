extends Area

# Editor variables
export var base_move : int = 1
export var base_cover : float = 0.0

# Accessor variables
onready var highlight = $Highlight

# Regular variables
var index : String = "0"
var grid_pos : Vector3 = Vector3.ZERO
var move_cost : int = 1
var cover : float = 0.0
var effects : Dictionary = {
	"burn":{"turns":0, "instance":null},
	"acid":{"turns":0, "instance":null},
	"sludge":{"turns":0, "instance":null},
	"smoke":{"turns":0, "instance":null},
	"chaff":{"turns":0, "instance":null}
	}
var curr_mech = null
var curr_item = null

# Indicator flags
var can_move : bool = false setget set_move
var can_atk : bool = false setget set_atk

# Called when the node enters the scene tree for the first time.
func _ready():
	highlight.visible = false
	pass # Replace with function body.

func set_move(value):
	can_move = value
	check_state()

func set_atk(value):
	can_atk = value
	check_state()

func check_state():
	if can_move:
		highlight.material_override.albedo_color = Color(0, 0, 1, 0.5)
	if can_atk:
		highlight.material_override.albedo_color = Color(1, 0, 0, 0.5)
	highlight.visible = (can_move || can_atk)

func proc_effects():
	for effect in effects:
		if effects[effect].turns > 0:
			match effect:
				"burn":
					if is_instance_valid(curr_mech):
						if !curr_mech.is_dead:
							for part in ["body", "arm_r", "arm_l", "legs"]:
								curr_mech.damage({"type":"fire", 
								"part":part, 
								"dmg":20, 
								"crit":1})
				"acid":
					if is_instance_valid(curr_mech):
						if !curr_mech.is_dead:
							for part in ["body", "arm_r", "arm_l", "legs"]:
								curr_mech.damage({"type":"fire", 
								"part":part, 
								"dmg":20, 
								"crit":1})
			effects[effect].turns -= 1
		if effects[effect].turns <= 0:
			if is_instance_valid(effects[effect].instance):
				effects[effect].instance.queue_free()

func add_effect(effect):
	if effects[effect].turns <= 0:
		var effect_obj
		var effect_inst
		match effect:
			"burn":
				effect_obj = load("res://Effects/map/MapFire.tscn")
				effect_inst = effect_obj.instance()
				add_child(effect_inst)
				effects[effect].instance = effect_inst
				effects[effect].turns = 4
			"acid":
				effect_obj = load("res://Effects/map/MapAcid.tscn")
				effect_inst = effect_obj.instance()
				add_child(effect_inst)
				effects[effect].instance = effect_inst
				effects[effect].turns = 4
			"sludge":
				effects[effect].turns = 4
			"smoke":
				effect_obj = load("res://Effects/map/MapSmoke.tscn")
				effect_inst = effect_obj.instance()
				add_child(effect_inst)
				effects[effect].instance = effect_inst
				effects[effect].turns = 4
			"chaff":
				effect_obj = load("res://Effects/map/MapChaff.tscn")
				effect_inst = effect_obj.instance()
				add_child(effect_inst)
				effects[effect].instance = effect_inst
				effects[effect].turns = 4
	else:
		effects[effect].turns = 4


func clear_effects():
	for effect in effects:
		effects[effect].turns = 0
		if is_instance_valid(effects[effect].instance):
			effects[effect].instance.queue_free()


# Reset all data. self is used here to trigger the setter functions
func reset_data():
	self.can_move = false
	self.can_atk = false
	curr_mech = null
	curr_item = null

# Only reset markers. self is used here to trigger the setter functions
func unmark():
	self.can_move = false
	self.can_atk = false

# Check line of sight between a point 1 unit above our position,
# to a point 1 unit above the target position, where the target is another NavPoint
func get_los(target):
	var from = global_transform.origin + Vector3.UP
	var to = target.global_transform.origin + Vector3.UP
	var space_state = get_world().direct_space_state
	var raycast = space_state.intersect_ray(from, to, [], 1)
	return raycast.empty()
