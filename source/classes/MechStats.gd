extends Reference
class_name MechStats

# Mech primary stats
var id : int = 0
var user_id : String = ""
var pilot : MechPilot
var body : MechBody
var arm_r : MechArm
var wpn_r : MechWeapon
var pod_r : MechPod
var arm_l : MechArm
var wpn_l : MechWeapon
var pod_l : MechPod
var legs : MechLegs
var pack : MechPack

# Mech derived/calculated stats
var weapon_list : Array = []
var hp_body : int = 0
var hp_armr : int = 0
var hp_arml : int = 0
var hp_legs : int = 0
var mech_dodge : float = 0.0
var move_range : int = 0
var jump_height : int = 0

# Stat tracking vars
var team : int = 0
var kill : int = 0
var dead : int = 0
var dmg_in : int = 0
var dmg_out : int = 0
var hit : int = 0
var crit : int = 0
var miss : int = 0
var part_lost : int = 0
var part_dest : int = 0
var bonuses : Array = []
var total_stats : Dictionary = {
	"hit":0,
	"crit":0,
	"miss":0,
	"dmg_in":0,
	"dmg_out":0,
	"part_lost":0,
	"part_dest":0,
	"bonuses":0
	}

# Member functions
func reset_data():
	hp_body = body.hp
	hp_armr = arm_r.hp
	hp_arml = arm_l.hp
	hp_legs = legs.hp
	kill = 0
	dead = 0
	total_stats.dmg_in += dmg_in
	dmg_in = 0
	total_stats.dmg_out += dmg_out
	dmg_out = 0
	total_stats.hit += hit
	hit = 0
	total_stats.crit += crit
	crit = 0
	total_stats.miss += miss
	miss = 0
	total_stats.part_lost += part_lost
	part_lost = 0
	total_stats.part_dest += part_dest
	part_dest = 0
	total_stats.bonuses += bonuses.size()
	bonuses.clear()


func get_dodge() -> float:
	return (body.dodge + arm_r.dodge + arm_l.dodge + legs.dodge + pilot.dodge / 100.0)


func get_move() -> int:
	if hp_legs >= legs.hp / 2.0:
		return (legs.move)
	else:
		return int(max(1, legs.move/2.0))


func get_jump() -> int:
	if hp_legs >= legs.hp / 2.0:
		return (legs.jump)
	else:
		return int(max(1, legs.jump/2.0))


func get_statblock():
	pass


func import_data():
	pass


func export_data():
	pass

