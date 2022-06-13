extends Reference

enum HitTable {Body = 20, ArmR = 20, ArmL = 20, Leg = 40}

func roll_attack(attacker, target, weapon, to_hit):
	var atk_roll = randf()
	var dmg_mult = 1
	var hit_loc = "miss"
	var dmg_final = 0
	# Check to hit, and update attacker's hit/miss/crit stats
	# Also update attacker's dmg_out stats
	if atk_roll <= to_hit:
		if atk_roll <= to_hit * 0.1:
			dmg_mult = 2
			attacker.mechData.crit += 1
		else:
			attacker.mechData.hit += 1
		hit_loc = hit_location()
		attacker.mechData.dmg_out += weapon.damage * dmg_mult
		# Reduce damage by hit location's defense stat
		dmg_final = max(1, floor((weapon.damage * dmg_mult) - target.mechData[hit_loc].defense))
	else:
		attacker.mechData.miss += 1
	# Update target's dmg_in stat and recent attacker data
	if dmg_final > 0:
		target.mechData.dmg_in += dmg_final
		target.update_threats(attacker, dmg_final)
	return {
		"type":weapon.type,
		"target":target,
		"part":hit_loc, 
		"dmg":int(dmg_final), 
		"crit":dmg_mult,
		}

# Roll random hit location
func hit_location():
	var hitTotal = HitTable.Body + HitTable.ArmR + HitTable.ArmL + HitTable.Leg;
	var hitArmR = HitTable.Body + HitTable.ArmR;
	var hitArmL = hitArmR + HitTable.ArmL;
	# Roll hit location and deliver damage
	var loc_roll = randf() * hitTotal
	if loc_roll <= HitTable.Body:
		return "body"
	if loc_roll > HitTable.Body && loc_roll <= hitArmR:
		return "arm_r"
	if loc_roll > hitArmR && loc_roll <= hitArmL:
		return "arm_l"
	if loc_roll > hitArmL && loc_roll <= hitTotal:
		return "legs"


# Get Manhattan distance between nav points
func get_distance(from, to):
	var dist = (abs(to.grid_pos.x - from.grid_pos.x) + abs(to.grid_pos.z - from.grid_pos.z))
	return dist


# Double check if able to attack 
func check_attack(attacker, target):
	var weapon = attacker.attack_wpn
	var target_range = get_distance(attacker.curr_tile, target.curr_tile)
	if (!attacker.is_dead && is_instance_valid(target) && weapon.active):
		attacker.direction = (target.global_transform.origin - attacker.global_transform.origin)
		if (target_range >= weapon.range_min) or (target_range <= weapon.range_max):
			return true
		else:
			return false
	else:
		return false


# General skills
# Standard attack
func act_attack(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			shots.append(roll_attack(attacker, target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)


# Dual Wield skill
func act_dual(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			shots.append(roll_attack(attacker, target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Melee skills
func act_combo(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate * 2:
			shots.append(roll_attack(attacker, target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Kneecap skill
func act_kneecap(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"stun", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Skewer skill
func act_skewer(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			if shot.part != "miss":
				shot.dmg = weapon.damage
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Machine gun skills
# Mag Dump skill
func act_magdump(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack with double fire rate
		for i in weapon.fire_rate * 2:
			shots.append(roll_attack(attacker, target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Spray N' Pray skill
func act_spray(attacker, target):
	if check_attack(attacker, target):
		# Find enemy mechs within 2 squares
		var target_group = []
		for item in attacker.unit_list:
			if !item.friend && !item.mech.is_dead && item.mech.team != attacker.team:
				if get_distance(target.curr_tile, item.mech.curr_tile) <= 2 && attacker.curr_tile.get_los(item.mech.curr_tile):
					target_group.append(item.mech)
		if target_group.size() == 0:
			target_group.append(target)
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		var curr_target
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack with double fire rate, randomly selecting between targets
		for i in weapon.fire_rate * 2:
			curr_target = target_group[randi() % target_group.size()]
			target_range = get_distance(attacker.curr_tile, curr_target.curr_tile)
			acc_penalty = curr_target.dodge_total + weapon.acc_loss_h * (target_range - 1)
			shots.append(roll_attack(attacker, curr_target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Focus Fire skill
func act_focus(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		var hit_loc = hit_location()
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times, overriding hit location to the selected one
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			if shot.part != "miss":
				shot.part = hit_loc
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Shotgun skills
# Stunner skill
func act_stunner(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"stun", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Slug Shot skill
func act_slugshot(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		var hit_loc = hit_location()
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times, overriding hit location to the selected one
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			if shot.part != "miss":
				shot.part = hit_loc
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Street Sweeper skill
func act_sweeper(attacker, target):
	if check_attack(attacker, target):
		# Find enemy mechs within 2 squares
		var target_group = []
		for item in attacker.unit_list:
			if !item.friend && !item.mech.is_dead && item.mech.team != attacker.team:
				if get_distance(target.curr_tile, item.mech.curr_tile) <= 2 && attacker.curr_tile.get_los(item.mech.curr_tile):
					target_group.append(item.mech)
		if target_group.size() == 0:
			target_group.append(target)
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		var curr_target
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack with double fire rate, randomly selecting between targets
		for i in weapon.fire_rate * 2:
			curr_target = target_group[randi() % target_group.size()]
			target_range = get_distance(attacker.curr_tile, curr_target.curr_tile)
			acc_penalty = curr_target.dodge_total + weapon.acc_loss_h * (target_range - 1)
			shots.append(roll_attack(attacker, curr_target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Flamer skills
# Meltdown skill
func act_meltdown(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"burn", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Rifle skills
# Double Tap skill
func act_dbltap(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack with double rate of fire
		for i in weapon.fire_rate * 2:
			shots.append(roll_attack(attacker, target, weapon, to_hit - acc_penalty))
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Anti Armor skill
func act_antiarmor(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times, overriding damage to full weapon damage
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			if shot.part != "miss":
				shot.dmg = weapon.damage
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Disable skill
func act_disable(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"stun", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# Missile skills
# Incendiary Missils skill
func act_fire(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"burn", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)

# EMP Missile skill
func act_emp(attacker, target):
	if check_attack(attacker, target):
		#attacker.update_sprite()
		var weapon = attacker.attack_wpn
		var target_range = get_distance(attacker.curr_tile, target.curr_tile)
		var shots = []
		var skill = attacker.mechData.pilot[weapon.skill]
		var to_hit = weapon.accuracy * (1 + weapon.stability) + skill/100.0
		var acc_penalty = target.dodge_total + weapon.acc_loss_h * (target_range - 1)
		if "ammo" in weapon:
			weapon.ammo -= 1
		# Attack $fire_rate times
		for i in weapon.fire_rate:
			var shot = roll_attack(attacker, target, weapon, to_hit - acc_penalty)
			shot.effect = {"type":"stun", "duration":4}
			shots.append(shot)
		attacker.do_attack(shots)
	else:
		attacker.do_attack(null)
