extends KinematicBody

enum MechState {READY, MOVE, ACTION, DONE, WAIT}
enum AIState {AGGRESSIVE, NORMAL, DEFENSIVE, RETREAT}

const skills = ["melee", "short", "long"]
const part_path = "res://Parts/3D/"
const sound_fx = {
	"mgun_ready":3,
	"mgun_shoot":9,
	"rifle_ready":3,
	"rifle_shoot":10,
	"sgun_ready":3,
	"sgun_shoot":4,
	"flame_shoot":4,
	"missile_shoot":3,
	"bullet_hit":16,
	"bullet_miss":10,
	"explode_sm":7,
	"explode_lg":7,
}
const ai_weights = [
	{"enemy":1.0, "aggro":1.0, "allies":0.0, "cover":0.0, "repair":0.0, "splash":0.0}, # Aggressive
	{"enemy":1.0, "aggro":0.0, "allies":0.5, "cover":0.5, "repair":0.5, "splash":-0.5}, # Normal
	{"enemy":0.5, "aggro":0.0, "allies":0.5, "cover":0.5, "repair":0.5, "splash":-0.5}, # Defensive
	{"enemy":-1.0, "aggro":-1.0, "allies":1.0, "cover":1.0, "repair":1.0, "splash":-1.0} # Retreat
]

onready var mech_parts = {
	"body":[
		{"point":$mech_frame/Armature/Skeleton/Body, 
		"model":"Torso", 
		"obj":null}
	],
	"pack":[
		{"point":$mech_frame/Armature/Skeleton/Body, 
		"model":"pack",
		"rotate":Vector3(0,180,0),
		"offset":Vector3(0, 0.3, -0.3),
		"obj":null}
	],
	"arm_l":[
		{"point":$mech_frame/Armature/Skeleton/PodL,
		"model":"ArmUp",
		"rotate":Vector3(-25,0,0),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/ArmLowL,
		"model":"ArmLow",
		"rotate":Vector3(-20,0,180),
		"obj":null},
	],
	"arm_r":[
		{"point":$mech_frame/Armature/Skeleton/PodR,
		"model":"ArmUp",
		"rotate":Vector3(-25,0,0),
		"flip":Vector3(0, 180, 0),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/ArmLowR,
		"model":"ArmLow",
		"rotate":Vector3(-20,0,180),
		"flip":Vector3(0, 180, 0),
		"obj":null},
	],
	"legs":[
		{"point":$mech_frame/Armature/Skeleton/Hip,
		"model":"Hip",
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegUpL,
		"model":"LegUp",
		"rotate":Vector3(-20,0,180),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegLowL,
		"model":"LegLow", 
		"rotate":Vector3(15,0,180),
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/FootL, 
		"model":"Foot", 
		"rotate":Vector3(-60,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegUpR, 
		"model":"LegUp",
		"rotate":Vector3(-20,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/LegLowR, 
		"model":"LegLow",
		"rotate":Vector3(15,0,180), 
		"obj":null},
		{"point":$mech_frame/Armature/Skeleton/FootR, 
		"model":"Foot",
		"rotate":Vector3(-60,0,180), 
		"obj":null},
	],
	"wpn_l":[
		{"point":$mech_frame/Armature/Skeleton/WpnL,
		"model":"",
		"obj":null}
	],
	"pod_l":[
		{"point":$mech_frame/Armature/Skeleton/PodL,
		"model":"pod",
		"obj":null}
	],
	"wpn_r":[
		{"point":$mech_frame/Armature/Skeleton/WpnR,
		"model":"",
		"obj":null}
	],
	"pod_r":[
		{"point":$mech_frame/Armature/Skeleton/PodR,
		"model":"pod",
		"obj":null}
	],
}
onready var mech_anim = $mech_frame/AnimationPlayer
onready var smoke = $Effects/Smoke
onready var sparks = {
	"body":$mech_frame/Armature/Skeleton/Body/Sparks,
	"arm_r":$mech_frame/Armature/Skeleton/PodR/Sparks,
	"arm_l":$mech_frame/Armature/Skeleton/PodL/Sparks,
	"legs":$mech_frame/Armature/Skeleton/Hip/Sparks,
}
onready var cam_point = $CamPoint

signal move_done
signal attack_done
signal dead
signal talk
signal run_combat
signal skill_proc(world_pos, skill_name)
signal glow_done

export (bool) var prop_mode = false

var part_mat = preload("res://Parts/mech_base.material")
var wpn_mat = preload("res://Parts/weapon.material")
var wpn_tex = preload("res://Parts/wpn_tex0.png")
var bullet_obj = preload("res://scenes/bullet/Bullet.tscn")
var missile_obj = preload("res://scenes/bullet/Missile.tscn")
var obj_dmgtext = preload("res://Effects/DamageNum.tscn")

# Speed settings
var spd_move = GameData.move_speed
var spd_anim = GameData.anim_speed
var spd_wait = GameData.wait_time

# Movement variables:
var curr_tile = null
var move_tiles = []
var move_target = null
var move_path = []
# Format for map_grid entries: {index:{tile, neighbors[]}}
var map_grid = {}
# Format for nav_paths entries: {index:{root, distance}}
var nav_paths = {}
# Format for priority_list entries: [{tile, priority}]
var priority_list = []

# Attack/targeting variables
var attack_tiles = []
var attack_target = null
var attack_wpn = null
var unit_list = []
var weapon_list = []
var item_list = []

# Turn/action variables:
var is_dead = false
var is_stunned = false
var dont_act = false
var dont_move = false
var is_thinking = false
var is_moving = false
var has_attacked = false
var in_combat = false
var turn_finished = true
var state = MechState.DONE
var nextState = MechState.DONE
var ai_state = AIState.NORMAL
var timer = 0
var effects = []
var step = 0

# mech attributes:
var partData = {}
var direction = Vector3.RIGHT
var mechData = null
var move_range = 1
var jump_height = 1
var bodyHP = 5 setget set_bodyHP
var armRHP = 5 setget set_armRHP
var armLHP = 5 setget set_armLHP
var legsHP = 5 setget set_legsHP
var dodge_total = 0
var team = 0
var num = 0

# Custom sort class for sorting list vars
class CustomSort:
	# Sort by priority, descending
	static func priority(a, b):
		if a["priority"] > b["priority"]:
			return true
		return false
	# Sort by damage, descending
	static func damage(a, b):
		if a["damage"] > b["damage"]:
			return true
		return false
	# Sort by target AND threat value, descending
	static func target_sort(a, b):
		if a["target"] > b["target"]:
			return true
		elif a["threat"] > b["threat"]:
			return true
		return false
	# Sort by distance, ascending
	static func distance(a, b):
		if a["distance"] < b["distance"]:
			return true
		return false


func set_bodyHP(value):
	if value <= 0:
		bodyHP = 0
		if !is_dead:
			mechData.dead = 1
			emit_signal("talk", self, "death")
			emit_signal("dead", self)
			is_dead = true
			#print("Mech is dead")
	else:
		sparks.body.emitting = (value < mechData.body.hp / 2)
		smoke.emitting = (value < mechData.body.hp / 2)
		bodyHP = value


func set_armRHP(value):
	if value <= 0:
		if armRHP > 0:
			if !prop_mode:
				play_fx("explode_sm")
			mechData.part_lost += 1
			toggle_part("arm_r", false)
		armRHP = 0
	else:
		if armRHP <= 0:
			toggle_part("arm_r", true)
		sparks.arm_r.emitting = (value < mechData.arm_r.hp / 2)
		armRHP = value
	update_wpn()


func set_armLHP(value):
	if value <= 0:
		if armLHP > 0:
			if !prop_mode:
				play_fx("explode_sm")
			mechData.part_lost += 1
			toggle_part("arm_l", false)
		armLHP = 0
	else:
		if armLHP <= 0:
			toggle_part("arm_l", true)
		sparks.arm_l.emitting = (value < mechData.arm_l.hp / 2)
		armLHP = value
	update_wpn()


func set_legsHP(value):
	if value <= 0:
		if legsHP > 0:
			if !prop_mode:
				play_fx("explode_sm")
			mechData.part_lost += 1
			toggle_part("legs", false)
		move_range = int(mechData.legs.move / 2)
		jump_height = max(1, int(mechData.legs.jump / 2))
		legsHP = 0
	else:
		if legsHP <= 0:
			toggle_part("legs", true)
		sparks.legs.emitting = (value < mechData.legs.hp / 2)
		move_range = mechData.legs.move
		jump_height = mechData.legs.jump
		legsHP = value


# Get shortest path distance to tile
func get_distance(tile):
	var d_min = 999.0
	for n_index in map_grid[tile.index].neighbors:
		if nav_paths[n_index].distance < d_min && nav_paths[n_index].distance > 0:
			d_min = float(nav_paths[n_index].distance)
	return d_min


# Get Manhattan distance between nav points
func get_range(from, to):
	var manhattan = (abs(to.grid_pos.x - from.grid_pos.x) + abs(to.grid_pos.z - from.grid_pos.z))
	return manhattan


# functions:
func _ready():
	# Set mech params
	if GameData.fast_wait:
		spd_wait = GameData.wait_time_fast
	else:
		spd_wait = GameData.wait_time
	if GameData.fast_combat:
		spd_move = GameData.move_speed_fast
		spd_anim = GameData.anim_speed_fast
	else:
		spd_move = GameData.move_speed
		spd_anim = GameData.anim_speed


func _physics_process(delta):
	match state:
		MechState.READY:
			if !is_thinking:
				is_thinking = true
				think_move()
		MechState.MOVE:
			if is_moving:
				move(delta)
			else:
				mech_anim.stop()
				check_item()
				emit_signal("move_done")
				think_action()
		MechState.ACTION:
			if !has_attacked:
				has_attacked = true
				in_combat = true
				get_attack_tiles()
				yield(get_tree().create_timer(0.5), "timeout")
				for tile in attack_tiles:
					tile.can_atk = false
				emit_signal("run_combat", self, attack_target)
			elif !in_combat:
				#print("ATTACK state done")
				nextState = MechState.DONE
				state = MechState.WAIT
		MechState.DONE:
			if !turn_finished:
				mech_anim.stop()
				turn_finished = true
				#print("Team " + str(team) + ", Mech " + str(num) + " turn finished")
		MechState.WAIT:
			if timer >= spd_wait:
				timer = 0
				state = nextState
			else:
				timer += delta

func setup(var my_arena):
	# Link to map's nav grid
	if my_arena != null:
		map_grid = my_arena.nav_grid
	# Build basic stats
	self.bodyHP = mechData.body.hp
	self.armRHP = mechData.arm_r.hp
	self.armLHP = mechData.arm_l.hp
	self.legsHP = mechData.legs.hp
	move_range = mechData.legs.move
	jump_height = mechData.legs.jump
	dodge_total = (mechData.body.dodge + 
	mechData.arm_r.dodge + mechData.arm_l.dodge + 
	mechData.legs.dodge + mechData.pilot.dodge / 100.0)
	# Clear old body parts
	for part in mech_parts:
		for piece in mech_parts[part]:
			if piece.obj != null:
				piece.obj.free()
	# Set up new body parts
	var part_set = "0"
	var part_inst = null
	var team_mat = load("res://Parts/team_" + str(team) + ".material")
	for part in mech_parts:
		var this_part = mech_parts[part]
		if part in ["wpn_r", "wpn_l"]:
			part_set = mechData[part].type + mechData[part].model
		else:
			part_set = mechData[part].model
		for piece in this_part:
			if part in ["pod_r", "pod_l", "wpn_r", "wpn_l"]:
				var part_path = "res://scenes/parts/%s%s.tscn" % [piece.model, part_set]
				part_inst = load(part_path).instance()
				piece.point.add_child(part_inst)
				piece.obj = part_inst
			else:
				part_inst = MeshInstance.new()
				piece.point.add_child(part_inst)
				piece.obj = part_inst
				part_inst.mesh = load(part_path + piece.model + part_set + ".obj")
				part_inst.set_surface_material(0, part_mat)
				if piece.model in ["Torso", "ArmUp"]:
					part_inst.set_surface_material(1, team_mat)
			if part in ["pod_r", "pod_l"]:
				part_inst.translation += Vector3(0, 0.15, 0)
			if piece.has("offset"):
				part_inst.translation += piece.offset
			if piece.has("rotate"):
				part_inst.rotation_degrees += piece.rotate
			if piece.has("flip"):
				part_inst.rotation_degrees += piece.flip
	# Set up spark emitters
	for spark in sparks:
		sparks[spark].emitting = false
	# Build weapon list
	weapon_list.clear()
	if mechData.wpn_l != null:
		weapon_list.append(mechData.wpn_l.get_data())
		weapon_list.back()["stability"] = mechData.arm_l.stability
		weapon_list.back()["muzzle"] = mech_parts.wpn_l[0].obj.get_node("Muzzle")
		weapon_list.back()["side"] = "left"
		weapon_list.back()["active"] = true
	if mechData.wpn_r != null:
		weapon_list.append(mechData.wpn_r.get_data())
		weapon_list.back()["stability"] = mechData.arm_r.stability
		weapon_list.back()["muzzle"] = mech_parts.wpn_r[0].obj.get_node("Muzzle")
		weapon_list.back()["side"] = "right"
		weapon_list.back()["active"] = true
	if mechData.pod_l != null:
		weapon_list.append(mechData.pod_l.get_data())
		weapon_list.back()["stability"] = mechData.arm_l.stability
		weapon_list.back()["muzzle"] = mech_parts.pod_l[0].obj.get_node("Muzzle")
		weapon_list.back()["side"] = "left"
		weapon_list.back()["active"] = true
	if mechData.pod_r != null:
		weapon_list.append(mechData.pod_r.get_data())
		weapon_list.back()["stability"] = mechData.arm_r.stability
		weapon_list.back()["muzzle"] = mech_parts.pod_r[0].obj.get_node("Muzzle")
		weapon_list.back()["side"] = "right"
		weapon_list.back()["active"] = true
	weapon_list.sort_custom(CustomSort, "damage")
	# Build target list
	var is_friend = true
	if my_arena != null:
		for mech in my_arena.turns_queue:
			if mech != self:
				is_friend = (mech.team == self.team)
				unit_list.append({
					"mech":mech, "friend":is_friend,
					"target":0.0, "aggro":0.0,
					"last_attack":1.0, "last_dmg":0.0})


func toggle_part(part, flag):
	for piece in mech_parts[part]:
		piece.point.visible = flag
	if part == "arm_l":
		mech_parts.wpn_l[0].point.visible = flag
	elif part == "arm_r":
		mech_parts.wpn_r[0].point.visible = flag


func reset_acts():
	if !is_dead:
		is_thinking = false
		is_moving = false
		has_attacked = false
		in_combat = false
		attack_target = null
		move_target = null
		turn_finished = false
		state = MechState.READY

# aux functions:
func impact(part, damage, crit, hitsound):
	var dmgtxt = obj_dmgtext.instance()
	add_child(dmgtxt)
	if part == "repair":
		dmgtxt.translation = sparks.body.translation
		dmgtxt.label.modulate = Color(0, 1, 0, 1)
	elif part == "miss":
		dmgtxt.translation = sparks.body.translation
	else:
		dmgtxt.translation = sparks[part].translation
	dmgtxt.label.text = str(damage)
	if crit > 1:
		dmgtxt.label.modulate = Color(1, 0, 0, 1)
	if hitsound != "none":
		play_fx(hitsound)

# Update recent damage amount of attacker
func update_threats(attacker, damage):
	for unit in unit_list:
		if unit.mech == attacker:
			unit.last_attack = 1
			unit.last_dmg = damage

# Update weapon availability based on weapon ammo or arm HP
func update_wpn():
	var hp_check = 0
	for weapon in weapon_list:
		if weapon.side == "left":
			hp_check = armLHP
		else:
			hp_check = armRHP
		if hp_check > 0:
			weapon.active = true
			if "ammo" in weapon:
				weapon.active = (weapon.ammo > 0)
		else:
			weapon.active = false

# Get tiles in attack range
func get_attack_tiles():
	# Check Manhattan distance between curr_tile and mapTiles to see if they're in range
	if attack_wpn != null:
		var this_tile = null
		for index in map_grid:
			this_tile = map_grid[index].tile
			var distance = (abs(curr_tile.grid_pos.x - this_tile.grid_pos.x) + 
			abs(curr_tile.grid_pos.z - this_tile.grid_pos.z))
			if (distance >= attack_wpn.range_min) && (distance <= attack_wpn.range_max):
				if curr_tile.get_los(this_tile):
					this_tile.can_atk = true
					attack_tiles.append(this_tile)

# Repair parts when ending turn on a wreck
func repair(percent):
	# Need to use self to force trigger the set/get function
	self.bodyHP += mechData.body.hp * percent
	self.armRHP += mechData.arm_r.hp * percent
	self.armLHP += mechData.arm_l.hp * percent
	self.legsHP += mechData.legs.hp * percent
	impact("repair", "+" + str(int(percent * 100)) + "%", 1, "none")

# Add an effect to this mech
func add_effect(new_effect):
	# Top up effect duration if already applied
	var existing = false
	for effect in effects:
		if effect.type == new_effect.type:
			existing = true
			if effect.duration < new_effect.duration:
				effect.duration = new_effect.duration
	# Add new effect if not already applied
	if !existing:
		match new_effect.type:
			"stun":
				is_stunned = true
				$Effects/Stun.visible = true
				effects.append(new_effect)
			"burn":
				$Effects/Fire.visible = true
				effects.append(new_effect)

# Check for active effects and act appropriately
func proc_effects():
	# Update count of turns since units last attacked us
	for unit in unit_list:
		if !unit.friend:
			unit.last_attack += 1
	# Apply active effects and update timers
	for effect in effects:
		match effect.type:
			"stun":
				if effect.duration > 0:
					is_stunned = true
					effect.duration -= 1
				else:
					$Effects/Stun.visible = false
					is_stunned = false
					effects.erase(effect)
			"burn":
				if effect.duration > 0:
					for part in ["body", "arm_r", "arm_l", "legs"]:
						damage({"type":"fire", 
						"part":part, 
						"dmg":15, 
						"crit":1, 
						"effect":{"type":"none", "duration":0}})
					effect.duration -= 1
				else:
					$Effects/Fire.visible = false
					effects.erase(effect)


func check_item():
	for item in item_list:
		if is_instance_valid(item) && (item.translation - self.translation).length() < 0.1:
			if item.is_in_group("repair"):
				repair(item.repair_value)
				item.queue_free()
			if item.is_in_group("mine"):
				item.visible = true
				item.detonate(self)


# Decision making function for movement
func think_move():
	move_target = null
	is_moving = false
	# Don't do anything if stunned, dead, or move disabled
	if is_stunned || is_dead || dont_move:
		nextState = MechState.MOVE
		state = MechState.WAIT
		return
	# Calculate paths from starting point and get movement tiles
	for tile in move_tiles:
		tile.unmark()
	move_tiles.clear()
	calc_paths(curr_tile)
	var this_node = null
	var this_tile = null
	for index in nav_paths:
		this_tile = map_grid[index].tile
		this_node = nav_paths[index]
		# Tile available for standing and within move range
		if this_node.distance <= move_range && this_node.distance > 0:
			if this_tile.curr_mech == null:
				this_tile.can_move = true
				move_tiles.append(this_tile)
	
	for unit in unit_list:
		if !unit.mech.is_dead:
			unit.threat = 0.0
			unit.threat += float(unit.mech.armRHP / unit.mech.mechData.arm_r.hp) * 0.5
			unit.threat += float(unit.mech.armLHP / unit.mech.mechData.arm_l.hp) * 0.5
			unit.target = 0.0
			unit.target += float(unit.mech.bodyHP / unit.mech.mechData.body.hp) * 0.5
			unit.target += float(unit.mech.armRHP / unit.mech.mechData.arm_r.hp) * 0.2
			unit.target += float(unit.mech.armLHP / unit.mech.mechData.arm_l.hp) * 0.2
			unit.target += float(unit.mech.legsHP / unit.mech.mechData.legs.hp) * 0.1
			unit.aggro = 0.0
			if !unit.friend:
				unit.aggro += float(unit.last_dmg / unit.last_attack)
	unit_list.sort_custom(CustomSort, "target_sort")
	
	# Nearest repair kit
	var near_repair = null
	var d_min = 999
	for item in item_list:
		if item.is_in_group("repair"):
			var item_dist = get_distance(item.curr_tile)
			if item_dist < d_min:
				d_min = item_dist
				near_repair = item.curr_tile
	
	# Determine our AI state
	var aggression = 1.0
	if (armRHP <= 0 and armLHP <= 0):
		aggression = 0
		ai_state = AIState.RETREAT
	else:
		aggression = float(bodyHP / mechData.body.hp) * 0.5
		aggression += float(armLHP / mechData.arm_l.hp) * 0.2
		aggression += float(armRHP / mechData.arm_r.hp) * 0.2
		aggression += float(legsHP / mechData.legs.hp) * 0.1
		if aggression >= 0.5:
			ai_state = AIState.NORMAL
		else:
			ai_state = AIState.DEFENSIVE
	var tile_goal = null
	match ai_state:
		# Aggressive: Attack nearest armed target, ignore repair kits and cover
		AIState.AGGRESSIVE:
			tile_goal = unit_list[0].mech.curr_tile
		# Standard: Attack nearest armed target, consider cover
		AIState.NORMAL:
			tile_goal = unit_list[0].mech.curr_tile
		# Defensive: Only attack safe targets, consider cover and repair kits
		AIState.DEFENSIVE:
			if !(near_repair == null):
				tile_goal = near_repair
			else:
				tile_goal = unit_list[0].mech.curr_tile
		# Retreat: Avoid enemies, seek repair kits and cover, move toward allies
		AIState.RETREAT:
			if !(near_repair == null):
				tile_goal = near_repair
	
	# Go through movement squares and calculate position values
	update_wpn()
	priority_list.clear()
	var priority = 0
	#var unit_tile = null
	for tile in move_tiles:
		var unit_dist = 0
		var unit_range = 0
		var enemy_attack_threats = 0
		var goal_dist = 0
		priority = 0
		calc_paths(tile)
		if !(tile_goal == null):
			goal_dist = get_distance(tile_goal)
			priority += clamp((move_range / goal_dist), 0, 1)
		for unit in unit_list:
			if !unit.mech.is_dead:
				unit_dist = get_distance(unit.mech.curr_tile)
				if !unit.friend:
					priority += clamp((move_range / unit_dist), 0, 1) * unit.target * ai_weights[ai_state].enemy
					unit_range = get_range(tile, unit.mech.curr_tile)
					if tile.get_los(unit.mech.curr_tile):
						var in_range_count = 0.0
						for weapon in weapon_list:
							if weapon.active && (unit_range >= weapon.range_min && unit_range <= weapon.range_max):
								in_range_count += 0.25
						priority += in_range_count * ai_weights[ai_state].enemy
						for weapon in unit.mech.weapon_list:
							if weapon.active && (unit_range >= weapon.range_min && unit_range <= weapon.range_max):
								enemy_attack_threats += 1
				else:
					priority += clamp((move_range / unit_dist), 0, 1) * ai_weights[ai_state].allies
		priority += (1.0 - float(enemy_attack_threats/16.0)) * ai_weights[ai_state].cover
		for item in item_list:
			if item.is_in_group("repair"):
				if (tile == item.curr_tile):
					priority += ai_weights[ai_state].repair
				else: 
					var item_dist = get_distance(item.curr_tile)
					priority += clamp((move_range / item_dist), 0, 1) * ai_weights[ai_state].repair
			if item.is_in_group("bomb"):
				priority += get_range(tile, item.curr_tile) * ai_weights[ai_state].splash
		priority_list.append({"tile":tile, "priority":priority})
	
	# If priority_list isn't empty, choose a move target, default to current tile if empty
	if !priority_list.empty():
		# Sort priority list, get max values
		priority_list.sort_custom(CustomSort, "priority")
		var max_list = []
		for item in priority_list:
			if item.priority == priority_list[0].priority:
				max_list.append(item)
		# Pick one of the max priority tiles, get the path to it
		if max_list.size() == 1:
			move_target = max_list[0].tile
		else:
			move_target = max_list[randi() % max_list.size()].tile
	else:
		move_target = curr_tile
	#print("READY state done")
	get_move_path()
	if GameData.debug_mode:
		yield(get_tree().create_timer(0.5), "timeout")
	is_moving = true
	is_thinking = false
	nextState = MechState.MOVE
	state = MechState.WAIT

# Decision making function for action
func think_action():
	# Prep attack variables and update weapons
	update_wpn()
	attack_target = null
	attack_wpn = null
	# Don't do anything if stunned, dead, or act disabled
	if is_stunned || is_dead || dont_act:
		nextState = MechState.DONE
		state = MechState.WAIT
		return
	# Check Manhattan distance of enemy units,
	# and find the highest damage weapon within range
	var unit_range = 0
	for unit in unit_list:
		if (!unit.friend && !unit.mech.is_dead && curr_tile.get_los(unit.mech.curr_tile)):
			unit_range = get_range(curr_tile, unit.mech.curr_tile)
			for weapon in weapon_list:
				if (weapon.active && 
				unit_range >= weapon.range_min &&
				unit_range <= weapon.range_max):
					attack_target = unit.mech
					attack_wpn = weapon
					break
			break
	if is_instance_valid(attack_target):
		nextState = MechState.ACTION
	else:
		nextState = MechState.DONE
	state = MechState.WAIT

# Calculate pathing from origin, where origin is a NavPoint
func calc_paths(origin):
	nav_paths.clear()
	# Reminder: for loop on Dictionaries will loop through KEYS only
	for point in map_grid:
		nav_paths[point] = {"root":null, "distance":0}
	if origin == null:
		print("Null origin tile, can't generate paths")
	else:
		# Reminder: queue is an array of index strings, the front is the frontier
		# Reminder: frontier is an index string, look up all related vars appropriately
		var queue = []
		var frontier = origin.index
		var next_dist = 0
		var front_tile = null
		var n_tile = null
		queue.push_back(frontier)
		while !queue.empty():
			frontier = queue.pop_front()
			#print("Frontier has " + str(frontier.neighbors.size()) + " neighbors")
			for n_index in map_grid[frontier].neighbors:
				front_tile = map_grid[frontier].tile
				n_tile = map_grid[n_index].tile
				next_dist = nav_paths[frontier].distance + n_tile.move_cost
				# not too high
				if abs(n_tile.translation.y - front_tile.translation.y) <= jump_height:
					if n_tile != origin:
						# not rooted yet
						if nav_paths[n_index].root == null:
							# TODO: This conditional is fucking up the distance calcs
							# Problem: Enemy mech squares are treated as impassable, and 'disconnected' from nav_paths{}
							# So, when we go to get the move distance to an enemy square, it returns 0
							# Solution: Take closest distance of neighboring squares?
							# tile available (or used by team-mate)
							if n_tile.curr_mech == null || n_tile.curr_mech.team == team || n_tile.curr_mech.is_dead:
								nav_paths[n_index].root = frontier
								nav_paths[n_index].distance = next_dist
								queue.push_back(n_index)
						# already rooted, update if distance is shorter
						elif next_dist < nav_paths[n_index].distance:
							nav_paths[n_index].root = frontier
							nav_paths[n_index].distance = next_dist
							queue.push_back(n_index)

# Get shortest path to move_target tile
func get_move_path():
	move_path.clear()
	calc_paths(curr_tile)
	if move_target != null && move_target != curr_tile:
		# Start at move_target, trace back to origin through root tiles
		var path_head = move_target.index
		while nav_paths[path_head].root != null:
			move_path.push_front(map_grid[path_head].tile)
			path_head = nav_paths[path_head].root
	else:
		move_path.push_front(curr_tile)

func move(delta):
	if !move_tiles.empty() && !move_path.empty():
		if mech_anim.current_animation != "walk":
			mech_anim.play("walk", -1, spd_anim, false)
		var from = global_transform.origin
		var to = move_path.front().global_transform.origin
		var look = to
		look.y = from.y
		direction = to - from
		if direction.length() < (spd_move * delta * 2):
			if step == 0:
				play_fx("step0")
				step = 1
			else:
				play_fx("step1")
				step = 0
			self.global_transform.origin = to
			move_path.pop_front()
		else:
			if global_transform.origin != look:
				look_at(look, Vector3.UP)
			var vel = direction.normalized() * spd_move
			if direction.y > 1.0:
				vel = Vector3.UP * spd_move
			vel = move_and_slide(vel, Vector3.UP)
		if move_path.empty():
			for tile in move_tiles:
				tile.unmark()
			move_tiles.clear()
			is_moving = false
			#print("Move finished")
	else:
		mech_anim.stop()
		for tile in move_tiles:
			tile.unmark()
		move_tiles.clear()
		is_moving = false

# Damage function
func damage(data):
	# Get current part hp values
	var sfx = "bullet_hit"
	var part_hp = {
		"body":bodyHP,
		"arm_r":armRHP,
		"arm_l":armLHP,
		"legs":legsHP
		}
	if data.part != "miss":
		if "effect" in data:
			add_effect(data.effect)
		match data.type:
			"melee":
				sfx = "step_mech"
			"missile":
				sfx = "explode_sm"
			"flame":
				sfx = "none"
		# If a destroyed arm/leg was hit, apply half damage to the body instead
		if data.part != "body" && part_hp[data.part] <= 0:
			data.part = "body"
			data.dmg = data.dmg/2
		impact(data.part, data.dmg, data.crit, sfx)
		match data.part:
			"body":
				self.bodyHP -= data.dmg
			"arm_r":
				self.armRHP -= data.dmg
			"arm_l":
				self.armLHP -= data.dmg
			"legs":
				self.legsHP -= data.dmg
		mechData.dmg_in += data.dmg
	else:
		sfx = "bullet_miss"
		match data.type:
			"melee":
				sfx = "none"
			"missile":
				sfx = "none"
			"flame":
				sfx = "none"
		impact(data.part, "miss", data.crit, sfx)

# Spawn bullet for attack
func projectile(target, object, hardpoint, speed, spread, data):
	var proj_inst = object.instance()
	add_child(proj_inst)
	proj_inst.global_transform.origin = hardpoint.global_transform.origin
	proj_inst.data = data
	proj_inst.set_target(target, spread)
	proj_inst.speed = speed
	return proj_inst

# Perform attack animation and deal damage to target
func do_attack(shot_list):
	if shot_list == null || !is_instance_valid(attack_target):
		yield(get_tree(), "idle_frame")
		emit_signal("attack_done")
		return
	# Attack start animation
	var aim = attack_target.global_transform.origin
	aim.y = self.global_transform.origin.y
	look_at(aim, Vector3.UP)
	var point = attack_wpn.muzzle
	if attack_wpn.type == "missile":
		mech_anim.play("launch_in_" + attack_wpn.side, -1, spd_anim, false)
		yield(mech_anim, "animation_finished")
	elif attack_wpn.type != "melee":
		mech_anim.play("shoot_in_" + attack_wpn.side, -1, spd_anim, false)
		yield(mech_anim, "animation_finished")
	if attack_wpn.type + "_ready" in sound_fx.keys():
		play_fx(attack_wpn.type + "_ready")
	$Effects/Flash.global_transform.origin = point.global_transform.origin
	# Play effects/anims, fire projectiles
	var last_shot
	for shot in shot_list:
		var bullet
		match (attack_wpn.type):
			# If weapon is melee, spawn invisible bullet, animate
			"melee":
				mech_anim.stop()
				mech_anim.play("melee_" + attack_wpn.side, -1, spd_anim, false)
				bullet = projectile(shot.target, bullet_obj, point, 20, 0, shot)
				bullet.visible = false
				yield(mech_anim, "animation_finished")
			# If weapon is shotgun, spawn bullets all at once, animate start only
			"sgun":
				if shot_list.find(shot) == 0:
					mech_anim.stop()
					mech_anim.play("shoot_" + attack_wpn.side, -1, spd_anim, false)
					$Effects/AnimEffect.play("shoot_flash")
					play_fx("sgun_shoot")
					yield(mech_anim, "animation_finished")
				bullet = projectile(shot.target, bullet_obj, point, 20, 0.4, shot)
			# If weapon is flamer, spawn invisible bullets with pause, no animation
			"flame":
				if shot_list.find(shot) == 0:
					play_fx("flame_shoot")
					$Effects/Flame.global_transform.origin = point.global_transform.origin
					$Effects/Flame.look_at(attack_target.global_transform.origin + Vector3.UP, Vector3.UP)
					$Effects/Flame.emitting = true
					$Effects/Flash.visible = true
					$Effects/AnimEffect.play("flame_glow")
				bullet = projectile(shot.target, bullet_obj, point, 30, 0.4, shot)
				bullet.visible = false
				yield(get_tree().create_timer(0.1), "timeout")
			"missile":
				mech_anim.play("launch_" + attack_wpn.side, -1, spd_anim, false)
				play_fx("missile_shoot")
				$Effects/AnimEffect.play("shoot_flash")
				bullet = projectile(shot.target, missile_obj, point, 20, 0, shot)
				yield(mech_anim, "animation_finished")
			"mgun":
				mech_anim.stop()
				mech_anim.play("shoot_" + attack_wpn.side, -1, spd_anim * 2, false)
				play_fx("mgun_shoot")
				$Effects/AnimEffect.play("shoot_flash")
				bullet = projectile(shot.target, bullet_obj, point, 30, 0.6, shot)
				yield(mech_anim, "animation_finished")
			"rifle":
				mech_anim.stop()
				mech_anim.play("shoot_" + attack_wpn.side, -1, spd_anim, false)
				play_fx("rifle_shoot")
				$Effects/AnimEffect.play("shoot_flash")
				bullet = projectile(shot.target, bullet_obj, point, 30, 0.2, shot)
				yield(mech_anim, "animation_finished")
		if shot_list.find(shot) == shot_list.size()-1:
			last_shot = bullet
	# Attack end animation
	$Effects/Flame.emitting = false
	$Effects/Flash.visible = false
	$Effects/AnimEffect.stop()
	mech_anim.stop()
	if attack_wpn.type == "missile":
		mech_anim.play("launch_in_" + attack_wpn.side, -1, -spd_anim, true)
	elif attack_wpn.type != "melee":
		mech_anim.play("shoot_in_" + attack_wpn.side, -1, -spd_anim, true)
	if attack_wpn.type != "melee":
		if is_instance_valid(last_shot):
			yield(last_shot, "tree_exited")
		else:
			yield(mech_anim, "animation_finished")
	#print("Team " + str(team) + ", Mech " + str(num) + " attack done")
	emit_signal("attack_done")

func get_counter_wpn(target):
	var distance = (abs(target.curr_tile.grid_pos.x - self.curr_tile.grid_pos.x) + 
	abs(target.curr_tile.grid_pos.z - self.curr_tile.grid_pos.z))
	attack_target = target
	attack_wpn = null
	update_wpn()
	var d_max = 0
	# Can't counter if in Stun or Don't Act
	if !is_stunned && !dont_act:
		for weapon in weapon_list:
			if !("ammo" in weapon):
				if (weapon.active && 
				(distance >= weapon.range_min) && 
				(distance <= weapon.range_max)):
					if weapon.damage > d_max:
						d_max = weapon.damage
						attack_wpn = weapon


func glow(skl_name):
	play_fx("skill_activate")
	$Effects/AnimEffect.play("skill_proc")
	emit_signal("skill_proc", self, skl_name)
	yield($Effects/AnimEffect, "animation_finished")
	emit_signal("glow_done")


# Randomly play effect in the corresponding array in the effect dictionary
func play_fx(fx_name):
	var player = AudioStreamPlayer.new()
	player.connect("finished", player, "queue_free")
	add_child(player)
	if fx_name in sound_fx.keys():
		player.stream = $Resources.get_resource(fx_name + str(randi() % sound_fx[fx_name]))
	else:
		player.stream = $Resources.get_resource(fx_name)
	player.play()


func _on_Area_area_entered(area):
	if area.is_in_group("projectiles"):
		if area.target_mech == self:
			damage(area.data)
			if area.data.type == "missile" && area.data.part != "miss":
				for part in ["body", "arm_r", "arm_l", "legs"]:
					if area.data.part != part:
						damage({"type":"splash", 
						"part":part, 
						"dmg":int(area.data.dmg / 5.0), 
						"crit":1,
						"effect":{"type":"none", "duration":0}})
			area.queue_free()
