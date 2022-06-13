extends KinematicBody

enum MechState {READY, MOVE, ATTACK, DONE, WAIT}

const skills = ["melee", "short", "long"]
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
const PORT_SIZE = 72

onready var mech_anim = $Viewport/MechSprite/MechAnim
onready var hit_anim = $Viewport/MechSprite/HitAnim
onready var podL = $Viewport/MechSprite/Body/ArmL/PodL
onready var armL = $Viewport/MechSprite/Body/ArmL
onready var wpnL = $Viewport/MechSprite/Body/ArmL/WeaponL
onready var legL = $Viewport/MechSprite/Body/LegL
onready var pack = $Viewport/MechSprite/Body/Pack
onready var body = $Viewport/MechSprite/Body
onready var legR = $Viewport/MechSprite/Body/LegR
onready var wpnR = $Viewport/MechSprite/Body/ArmR/WeaponR
onready var armR = $Viewport/MechSprite/Body/ArmR
onready var podR = $Viewport/MechSprite/Body/ArmR/PodR
onready var smoke = $Effects/Smoke
onready var sparks = {
	"arm_r":$Viewport/MechSprite/Body/ArmR/Sparks,
	"arm_l":$Viewport/MechSprite/Body/ArmL/Sparks,
	"leg_r":$Viewport/MechSprite/Body/LegR/Sparks,
	"leg_l":$Viewport/MechSprite/Body/LegL/Sparks,
}

var bullet_obj = preload("res://Mech/Bullet.tscn")
var missile_obj = preload("res://Mech/Missile.tscn")

signal move_done
signal attack_done
signal end_turn
signal dead
signal talk
signal run_combat
signal skill_proc(world_pos, skill_name)
signal glow_done

# Speed variables
var spd_move = GameData.move_speed
var spd_anim = GameData.anim_speed
var spd_wait = GameData.wait_time

# pathfinding and targeting variables:
var debug_move = false
var move_tiles = []
var move_target = null
var move_path = []

var enemy_list = []
var weapon_list = []
var item_list = []

var attack_tiles = []
var attack_target = null
var attack_wpn = null

var curr_tile = null
var arena = null

# turn/action variables:
var is_dead = false
var is_stunned = false
var dont_act = false
var dont_move = false
var idle_turn = true
var is_moving = false
var has_attacked = false
var in_combat = false
var is_done = true
var state = MechState.DONE
var nextState = MechState.DONE
var timer = 0
var effects = []
var step = 0

# mech attributes:
var partData = {}
var direction = Vector3.RIGHT
var facing = Vector3.ZERO
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
	static func target(a, b):
		if a["target"] > b["target"]:
			return true
		return false
	# Sort by distance, ascending
	static func distance(a, b):
		if a["distance"] < b["distance"]:
			return true
		return false
	# Sort by damage, descending
	static func damage(a, b):
		if a["damage"] > b["damage"]:
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
			$Viewport/MechSprite.set_color(Color(0.1, 0.1, 0.1))
			#print("Mech is dead")
	elif value < mechData.body.hp / 2:
		bodyHP = value
		smoke.emitting = true
	else:
		bodyHP = value
		smoke.emitting = false
	update_sprite()

func set_armRHP(value):
	if value <= 0:
		if armRHP > 0:
			play_fx("explode_sm")
			mechData.part_lost += 1
		armRHP = 0
		partData.arm_r.id = "B"
		partData.pod_r.sprite.visible = false
		partData.wpn_r.sprite.visible = false
		sparks.arm_r.emitting = true
	elif value < mechData.arm_r.hp / 2:
		armRHP = value
		partData.arm_r.id = mechData.arm_r.sprite
		partData.pod_r.sprite.visible = true
		partData.wpn_r.sprite.visible = true
		sparks.arm_r.emitting = true
	else:
		armRHP = value
		partData.arm_r.id = mechData.arm_r.sprite
		partData.pod_r.sprite.visible = true
		partData.wpn_r.sprite.visible = true
		sparks.arm_r.emitting = false
	update_wpn()
	update_sprite()

func set_armLHP(value):
	if value <= 0:
		if armLHP > 0:
			play_fx("explode_sm")
			mechData.part_lost += 1
		armLHP = 0
		partData.arm_l.id = "B"
		partData.pod_l.sprite.visible = false
		partData.wpn_l.sprite.visible = false
		sparks.arm_l.emitting = true
	elif value < mechData.arm_l.hp / 2:
		armLHP = value
		partData.arm_l.id = mechData.arm_l.sprite
		partData.pod_l.sprite.visible = true
		partData.wpn_l.sprite.visible = true
		sparks.arm_l.emitting = true
	else:
		armLHP = value
		partData.arm_l.id = mechData.arm_l.sprite
		partData.pod_l.sprite.visible = true
		partData.wpn_l.sprite.visible = true
		sparks.arm_l.emitting = false
	update_wpn()
	update_sprite()

func set_legsHP(value):
	if value <= 0:
		if legsHP > 0:
			play_fx("explode_sm")
			mechData.part_lost += 1
		legsHP = 0
		partData.leg_l.id = "B"
		partData.leg_r.id = "B"
		sparks.leg_l.emitting = true
		sparks.leg_r.emitting = true
		move_range = mechData.legs.move / 2
		jump_height = 2
		dodge_total = (mechData.legs.dodge / 2.0) + (mechData.pilot.dodge / 100.0)
	elif value < mechData.legs.hp / 2:
		legsHP = value
		partData.leg_l.id = mechData.legs.sprite
		partData.leg_r.id = mechData.legs.sprite
		move_range = mechData.legs.move
		jump_height = mechData.legs.jump
		dodge_total = mechData.legs.dodge + mechData.pilot.dodge / 100.0
		sparks.leg_l.emitting = true
		sparks.leg_r.emitting = true
	else:
		legsHP = value
		partData.leg_l.id = mechData.legs.sprite
		partData.leg_r.id = mechData.legs.sprite
		move_range = mechData.legs.move
		jump_height = mechData.legs.jump
		dodge_total = mechData.legs.dodge + mechData.pilot.dodge / 100.0
		sparks.leg_l.emitting = false
		sparks.leg_r.emitting = false
	update_sprite()

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
			# Scan for potential targets and set movement path
			proc_effects()
			act_prepare()
			nextState = MechState.MOVE
			#print("READY state done")
			state = MechState.WAIT
		MechState.MOVE:
			if is_moving:
				if mech_anim.current_animation != "walk_dr":
					mech_anim.play("walk_dr", -1, spd_anim, false)
				_move(delta)
			else:
				mech_anim.stop()
				for item in item_list:
					if is_instance_valid(item) && (item.translation - self.translation).length() < 0.1:
						if item.is_in_group("repair"):
							repair(item.repair_value)
							item.queue_free()
						if item.is_in_group("mine"):
							item.visible = true
							item.detonate(self)
				if is_instance_valid(attack_target):
					nextState = MechState.ATTACK
				else:
					nextState = MechState.DONE
				state = MechState.WAIT
				emit_signal("move_done")
				#print("MOVE state done")
		MechState.ATTACK:
			if !has_attacked:
				has_attacked = true
				in_combat = true
				idle_turn = false
				get_attack_tiles()
				emit_signal("run_combat", self, attack_target)
			elif !in_combat:
				nextState = MechState.DONE
				#print("ATTACK state done")
				state = MechState.WAIT
		MechState.DONE:
			if !is_done:
				mech_anim.stop()
				is_done = true
				#print("Team " + str(team) + ", Mech " + str(num) + " turn finished")
				emit_signal("end_turn", idle_turn)
		MechState.WAIT:
			if timer >= spd_wait:
				timer = 0
				state = nextState
			else:
				timer += delta
	update_sprite()

func setup(var my_arena):
	# Set part data
	partData = {
		"pod_l": {"sprite":podL, "img":"pod_l", "id":mechData.pod_l.sprite},
		"arm_l": {"sprite":armL, "img":"arm_l", "id":mechData.arm_l.sprite},
		"wpn_l": {"sprite":wpnL, "img":"wpn_l", "id":mechData.wpn_l.sprite},
		"leg_l": {"sprite":legL, "img":"leg_l", "id":mechData.legs.sprite},
		"pack": {"sprite":pack, "img":"pack", "id":mechData.pack.sprite},
		"body": {"sprite":body, "img":"body", "id":mechData.body.sprite},
		"leg_r": {"sprite":legR, "img":"leg_r", "id":mechData.legs.sprite},
		"wpn_r": {"sprite":wpnR, "img":"wpn_r", "id":mechData.wpn_r.sprite},
		"arm_r": {"sprite":armR, "img":"arm_r", "id":mechData.arm_r.sprite},
		"pod_r": {"sprite":podR, "img":"pod_r", "id":mechData.pod_r.sprite},
		}
	# Build basic stats
	bodyHP = mechData.body.hp
	armRHP = mechData.arm_r.hp
	armLHP = mechData.arm_l.hp
	legsHP = mechData.legs.hp
	move_range = mechData.legs.move
	jump_height = mechData.legs.jump
	dodge_total = mechData.legs.dodge + mechData.pilot.dodge / 100.0
	# Build weapon list
	if mechData.wpn_l != null:
		weapon_list.append(mechData.wpn_l.duplicate())
		weapon_list.back()["arm"] = mechData.arm_l
		weapon_list.back()["active"] = true
	if mechData.wpn_r != null:
		weapon_list.append(mechData.wpn_r.duplicate())
		weapon_list.back()["arm"] = mechData.arm_r
		weapon_list.back()["active"] = true
	if mechData.pod_l != null:
		weapon_list.append(mechData.pod_l.duplicate())
		weapon_list.back()["arm"] = mechData.arm_l
		weapon_list.back()["active"] = true
	if mechData.pod_r != null:
		weapon_list.append(mechData.pod_r.duplicate())
		weapon_list.back()["arm"] = mechData.arm_r
		weapon_list.back()["active"] = true
	weapon_list.sort_custom(CustomSort, "damage")
	arena = my_arena
	# Build target list
	for mech in arena.turns_queue:
		if mech.team != self.team:
			enemy_list.append({
				"mech":mech,
				"target":0, 
				"threat":0,
				"last_attack":1,
				"last_dmg":0})
	var material = $Mesh.get_surface_material(0)
	$Viewport/MechSprite.set_color(GameData.teamColors[self.team])
	$Mesh.set_surface_material(0, material)

func reset_acts():
	is_stunned = false
	dont_act = false
	dont_move = false
	idle_turn = true
	is_moving = false
	has_attacked = false
	in_combat = false
	attack_target = null
	move_target = null
	is_done = false
	state = MechState.READY

# aux functions:
func impact(anim, damage, crit, hitsound):
	var dmgtxt = EffectManager.scn_dmgtxt.instance()
	self.add_child(dmgtxt)
	dmgtxt.label.text = str(damage)
	if crit > 1:
		dmgtxt.label.modulate = Color(1, 0, 0, 1)
	if anim == "repair":
		hit_anim.play("hit_body", -1, spd_anim, false)
		dmgtxt.label.modulate = Color(0, 1, 0, 1)
	elif anim != "miss":
		hit_anim.play(anim, -1, spd_anim, false)
	if hitsound != "none":
		play_fx(hitsound)

# Update sprites, sprite positions, and sprite z-indexes based on direction/state
func update_sprite():
	# Set sprite order, part order, facing, and flip toggle based on our current direction
	# NOTE: Sprite and part order can be opposite depending on orientation!
	var spriteOrder = []
	var partOrder = []
	var face = "_front"
	var flip = false #toggle flip_h
	var faceX = "xf"
	var faceY = "yf"
	
	var unit_dir = direction.normalized()
	var dot_max = -1.0
	for dir in [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]:
		var dot_prod = unit_dir.dot(dir)
		if dot_prod > dot_max:
			dot_max = dot_prod
			facing = dir
	
	match facing:
		Vector3.RIGHT: #DR
			partOrder = ["pod_l", "arm_l", "wpn_l", "leg_l", "pack", "body", "leg_r", "wpn_r", "arm_r", "pod_r"];
			spriteOrder = ["pod_l", "arm_l", "wpn_l", "leg_l", "pack", "body", "leg_r", "wpn_r", "arm_r", "pod_r"];
			face = "_front"
			flip = false
			faceX = "xf"
			faceY = "yf"
		Vector3.BACK: #DL
			partOrder = ["pod_r", "arm_r", "wpn_r", "leg_r", "pack", "body", "leg_l", "wpn_l", "arm_l", "pod_l"];
			spriteOrder = ["pod_l", "arm_l", "wpn_l", "leg_l", "pack", "body", "leg_r", "wpn_r", "arm_r", "pod_r"];
			face = "_front"
			flip = true
			faceX = "xf"
			faceY = "yf"
		Vector3.LEFT: #UL
			partOrder = ["pod_r", "arm_r", "wpn_r", "leg_r", "body", "pack", "leg_l", "wpn_l", "arm_l", "pod_l"];
			spriteOrder = ["pod_r", "arm_r", "wpn_r", "leg_r", "body", "pack", "leg_l", "wpn_l", "arm_l", "pod_l"];
			face = "_back"
			flip = false
			faceX = "xb"
			faceY = "yb"
		Vector3.FORWARD: #UR
			partOrder = ["pod_l", "arm_l", "wpn_l", "leg_l", "body", "pack", "leg_r", "wpn_r", "arm_r", "pod_r"];
			spriteOrder = ["pod_r", "arm_r", "wpn_r", "leg_r", "body", "pack", "leg_l", "wpn_l", "arm_l", "pod_l"];
			face = "_back"
			flip = true
			faceX = "xb"
			faceY = "yb"
	
	# Set up part sprites using parameters
	var counter = 0
	for part in partOrder:
		partData[part].img = spriteOrder[counter]
		var img = partData[part].img
		if (img == "pod_l" || img == "pod_r"):
			img = "pod"
		if (img == "wpn_l" || img == "wpn_r"):
			img = "wpn"
		var partID = partData[part].id
		var imgPath = "res://Parts/" + img + face + partID + ".png"
		if (partID == "none"):
			partData[part].sprite.texture = null
		else:
			partData[part].sprite.texture = load(imgPath)
		# Set z-index based on sprite order
		partData[part].sprite.z_index = counter
		counter += 1
	
	# Set spark emitter positions
	for spark in sparks:
		var item = sparks[spark]
		item.position.x = item.get_parent().texture.get_width() / 2
		item.position.y = item.get_parent().texture.get_height() / 2
	
	# Set body position to center of viewport, because it's the root part
	# Set position and scale of root part based on if we're flipped or not
	if flip:
		partData.body.sprite.position.x = (PORT_SIZE * 0.45) + GameData.spriteData.body[partData.body.id][faceX]
		partData.body.sprite.scale.x = -1
	else:
		partData.body.sprite.position.x = (PORT_SIZE * 0.45) - GameData.spriteData.body[partData.body.id][faceX]
		partData.body.sprite.scale.x = 1
	partData.body.sprite.position.y = (PORT_SIZE - 32) - GameData.spriteData.body[partData.body.id][faceY]
	
	# Set part positions using parameters
	for part in ["body", "pack", "arm_l", "arm_r", "leg_l", "leg_r", "pod_l", "pod_r", "wpn_l", "wpn_r"]:
		var thisImg = partData[part].img
		var thisID = partData[part].id
		var partChildren = GameData.spriteData[part][thisID].children
		var imgChildren = GameData.spriteData[thisImg][thisID].children
		
		var childCount = 0
		for child in partChildren:
			var childPart = partData[child.part].img
			if (partData[part].img != part):
				childPart = child.part
			
			var childX = imgChildren[childCount][faceX]
			var childY = imgChildren[childCount][faceY]
			
			var childID = partData[child.part].id
			var childSprite = imgChildren[childCount].part
			var offX = GameData.spriteData[childSprite][childID][faceX]
			var offY = GameData.spriteData[childSprite][childID][faceY]
			
			# childPart's coordinates set with childSprite's info
			partData[childPart].sprite.position.x = childX - offX
			partData[childPart].sprite.position.y = childY - offY
			childCount += 1

func get_move_tiles():
	move_tiles.clear()
	if curr_tile != null:
		var queue = []
		var frontier = curr_tile
		var nextDist = 0
		frontier.root = null
		move_tiles.append(frontier)
		queue.push_back(frontier)
		while !queue.empty():
			frontier = queue.pop_front()
			#print("Frontier has " + str(frontier.neighbors.size()) + " neighbors")
			for tile in frontier.neighbors:
				nextDist = frontier.distance + tile.move_cost
				# not too high
				if abs(tile.translation.y - frontier.translation.y) <= jump_height:
					if tile != curr_tile:
						# not rooted yet
						if tile.root == null:
							# tile available (or used by team-mate)
							if tile.curr_mech == null || tile.curr_mech.team == team || tile.curr_mech.is_dead:
								tile.root = frontier
								tile.distance = nextDist
								# tile available for standing and within move range
								if tile.distance <= move_range:
									if tile.curr_mech == null:
										tile.can_move = true
										move_tiles.append(tile)
#									elif tile.curr_mech.is_dead:
#										tile.can_move = true
#										move_tiles.append(tile)
								queue.push_back(tile)
						# already rooted, update if distance is shorter
						elif nextDist < tile.distance:
							tile.distance = nextDist
							tile.root = frontier
							queue.push_back(tile)
		#print("Generated list of " + str(move_tiles.size()) + " move tiles")
	else:
		#print("Null current tile, can't generate move tiles")
		pass

func update_threats(attacker, damage):
	for enemy in enemy_list:
		if enemy.mech == attacker:
			enemy.last_attack = 1
			enemy.last_dmg = damage

# Get list of active enemies, assigning target and threat priority based on various criteria
# Weight of criteria are different based on AI personality
# Enemy info dictionary: {mech, target level, threat level, turns since last attack, damage dealt}
func get_targets():
	var target = 0
	var threat = 0
	for enemy in enemy_list:
		if !enemy.mech.is_dead:
			# How damaged is mech?
			target = int((enemy.mech.bodyHP / enemy.mech.mechData.body.hp) * 10)
			# How close is mech?
			if enemy.mech.curr_tile.distance <= move_range * 2:
				target += 5
			if enemy.mech.curr_tile.distance <= move_range:
				target += 10
			# Is mech armed?
			if enemy.mech.armRHP > 0:
				target += 5
			if enemy.mech.armLHP > 0:
				target += 5
			# How mobile is mech?
			if enemy.mech.legsHP > 0:
				target += 2
			# Reference enemy info
			# How recently did this mech attack us?
			# How much damage has this mech dealt to us?
			# Recent threat index = last attack damage / turns since last attack
			threat += enemy.last_dmg / enemy.last_attack
			enemy.target = target
			enemy.threat = threat
	enemy_list.sort_custom(CustomSort, "target")
	#print("Generated list of " + str(enemy_list.size()) + " targets")

# Update weapon availability based on arm HP
func update_wpn():
	for weapon in weapon_list:
		if weapon.arm == mechData.arm_l:
			if armLHP > 0:
				weapon.active = true
			else:
				weapon.active = false
		if weapon.arm == mechData.arm_r:
			if armRHP > 0:
				weapon.active = true
			else:
				weapon.active = false
		if "ammo" in weapon:
			if weapon.ammo <= 0:
				weapon.active = false

# Get tiles in attack range
func get_attack_tiles():
	# Check Manhattan distance between curr_tile and mapTiles to see if they're in range
	if attack_wpn != null:
		for tile in arena.nav_grid.get_children():
			var distance = abs(curr_tile.grid_pos.x - tile.grid_pos.x) + abs(curr_tile.grid_pos.z - tile.grid_pos.z)
			if (distance >= attack_wpn.range_min) && (distance <= attack_wpn.range_max):
				if curr_tile.get_los(tile):
					tile.can_atk = true
					attack_tiles.append(tile)

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
				$Effects/Fire.emitting = true
				effects.append(new_effect)

# Check for active effects and act appropriately
func proc_effects():
	for effect in effects:
		match effect.type:
			"stun":
				if effect.duration > 0:
					is_stunned = true
					effect.duration -= 1
				else:
					$Effects/Stun.visible = false
					effects.erase(effect)
			"burn":
				if effect.duration > 0:
					for part in ["body", "arm_r", "arm_l", "legs"]:
						damage({"type":"fire", 
						"part":part, 
						"dmg":20, 
						"crit":1, 
						"effect":{"type":"none", "duration":0}})
					effect.duration -= 1
				else:
					$Effects/Fire.emitting = false
					effects.erase(effect)

# Scan map to calculate movement distances, target priorities
func act_prepare():
	# Prepare vars for where to move, what to attack, and what weapon to use
	move_target = null
	attack_target = null
	attack_wpn = null
	is_moving = false
	# Don't do anything if stunned or dead
	if is_stunned || is_dead:
		return
	# Calculate move distances of all tiles
	get_move_tiles()
	# Update weapon list
	update_wpn()
	
	# Calculate behavior state based on condition
	# Passive if too damaged, aggressive if not
	var found_item = false
	var found_target = false
	
	# Calculate target/threat priorities
	get_targets()
	
	# Calculate priority values for each nav point in movement range
	# Distance to targets/threats
	# Distance to allies
	# Distance to repair items
	# Within attack range
	
	# If we're very damaged or disarmed, search for repair items
	# If we're OK, check if any mech in enemy_list is in range of a weapon in weapon_list
	var target_max = 0
	if (armLHP <= 0 && armRHP <= 0) || bodyHP <= mechData.body.hp * 0.3:
		var d_min = 10000
		for item in item_list:
			if is_instance_valid(item) && item.is_in_group("repair"):
				if item.curr_tile.distance < d_min:
					move_target = item.curr_tile
					d_min = item.curr_tile.distance
					found_item = true
	if !found_item:
		var thisDist = 0
		for tile in move_tiles:
			if (tile.curr_mech == null or tile.curr_mech == self):
				for enemy in enemy_list:
					if !enemy.mech.is_dead:
						thisDist = (abs(enemy.mech.curr_tile.grid_pos.x - tile.grid_pos.x) + 
						abs(enemy.mech.curr_tile.grid_pos.z - tile.grid_pos.z))
						for weapon in weapon_list:
							if (weapon.active && (thisDist >= weapon.range_min) && (thisDist <= weapon.range_max)):
								if enemy.target > target_max && tile.get_los(enemy.mech.curr_tile):
									target_max = enemy.target
									move_target = tile
									attack_target = enemy.mech
									attack_wpn = weapon
									found_target = true
	# If no target has been picked yet, move toward the highest priority target that we can approach
	if !found_item && !found_target:
		if enemy_list.empty():
			print("Enemy list empty!")
			move_target = curr_tile
		else:
			var d_min = 10000
			target_max = 0
			for enemy in enemy_list:
				if enemy.target > target_max:
					enemy.mech.curr_tile.neighbors.sort_custom(CustomSort, "distance")
					for tile in enemy.mech.curr_tile.neighbors:
						if tile.distance < d_min:
							find_path(tile)
							trim_path()
							if !move_path.empty() and move_path.back() != curr_tile:
								move_target = tile
								d_min = tile.distance
								target_max = enemy.target
	find_path(move_target)
	trim_path()
	is_moving = true

# Get shortest path to move_target tile
func find_path(destination):
	move_path.clear()
	if destination != null && destination != curr_tile:
		# Start at destination, trace back to origin through root tiles
		var path_head = destination
		while path_head.root != null:
			move_path.push_front(path_head)
			path_head = path_head.root

# Trim path to be within movement range, then update move_target
func trim_path():
	# If the end of the path is further than our movement range, remove it
	while !move_path.empty() and !move_path.back().can_move:
		move_path.pop_back()
	if move_path.empty():
		move_path.push_front(curr_tile)
	move_target = move_path.back()

func _move(delta):
	if !move_tiles.empty() && !move_path.empty():
		var from = global_transform.origin
		var to = move_path.front().global_transform.origin
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
			"missile":
				sfx = "explode_sm"
			"flame":
				sfx = "none"
		# If a destroyed arm/leg was hit, apply half damage to the body instead
		if data.part != "body" && part_hp[data.part] <= 0:
			data.part = "body"
			data.dmg = data.dmg/2
		impact("hit_" + data.part, data.dmg, data.crit, sfx)
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
			"missile":
				sfx = "none"
			"flame":
				sfx = "none"
		impact(data.part, "miss", data.crit, sfx)

# Spawn bullet for attack
func projectile(target, object, offset, speed, spread, data):
	var proj_inst = object.instance()
	add_child(proj_inst)
	proj_inst.transform.origin = offset
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
	$Mounts.look_at(aim, Vector3.UP)
	var side = "right"
	var offset = $Mounts/ArmR.transform.origin
	if attack_wpn.arm == mechData.arm_l:
		side = "left"
		offset = $Mounts/ArmL.transform.origin
	mech_anim.play("shoot_" + side + "_in", -1, spd_anim, false)
	if attack_wpn.type + "_ready" in sound_fx.keys():
		play_fx(attack_wpn.type + "_ready")
	else:
		play_fx("mgun_ready")
	yield(mech_anim, "animation_finished")
	
	# Play effects/anims, fire projectiles
	var last_shot
	for shot in shot_list:
		# If weapon is shotgun, spawn bullets all at once, animate start only
		var bullet
		if attack_wpn.type == "sgun":
			if shot_list.find(shot) == 0:
				mech_anim.stop()
				mech_anim.play("shoot_" + side, -1, spd_anim, false)
				play_fx("sgun_shoot")
				yield(mech_anim, "animation_finished")
			bullet = projectile(shot.target, bullet_obj, offset, 20, 0.4, shot)
		# If weapon is flamer, spawn invisible bullets with pause, no animation
		elif attack_wpn.type == "flame":
			if shot_list.find(shot) == 0:
				play_fx("flame_shoot")
				$Effects/Flame.transform.origin = offset
				$Effects/Flame.look_at(attack_target.global_transform.origin + Vector3.UP, Vector3.UP)
				$Effects/Flame.emitting = true
			bullet = projectile(shot.target, bullet_obj, offset, 30, 0.4, shot)
			bullet.visible = false
			# TODO: Roll chance to start fire DoT
			yield(get_tree().create_timer(0.1), "timeout")
		# If weapon is anything else, spawn bullet with animation
		else:
			mech_anim.stop()
			mech_anim.play("shoot_" + side, -1, spd_anim, false)
			match shot.type:
				"mgun":
					play_fx("mgun_shoot")
					bullet = projectile(shot.target, bullet_obj, offset, 30, 0.6, shot)
				"rifle":
					play_fx("rifle_shoot")
					bullet = projectile(shot.target, bullet_obj, offset, 30, 0.2, shot)
				"missile":
					play_fx("missile_shoot")
					bullet = projectile(shot.target, missile_obj, offset, 20, 0, shot)
			yield(mech_anim, "animation_finished")
		if shot_list.find(shot) == shot_list.size()-1:
			last_shot = bullet
	
	# Attack end animation
	$Effects/Flame.emitting = false
	mech_anim.stop()
	mech_anim.play("shoot_" + side + "_in", -1, -spd_anim, true)
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
	$Effects/Tween.interpolate_property($Effects/Glow, "material_override:albedo_color",
	Color(0.5, 0.5, 1, 0), Color(0.5, 0.5, 1, 1),
	0.25)
	$Effects/Tween.start()
	emit_signal("skill_proc", self, skl_name)

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
						"dmg":area.data.dmg / 5.0, 
						"crit":1,
						"effect":{"type":"none", "duration":0}})
			area.queue_free()

func _on_Tween_tween_completed(object, _key):
	if object == $Effects/Glow:
		$Effects/Tween.stop($Effects/Glow)
		if $Effects/Glow.material_override.albedo_color == Color(0.5, 0.5, 1, 1):
			$Effects/Tween.interpolate_property($Effects/Glow, "material_override:albedo_color",
			Color(0.5, 0.5, 1, 1), Color(0.5, 0.5, 1, 0),
			0.25)
			$Effects/Tween.start()
		else:
			emit_signal("glow_done")
