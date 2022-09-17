extends Spatial

enum HitTable {Body = 20, ArmR = 20, ArmL = 20, Leg = 40}

# Preloaded resources
const debris_obj = preload("res://Effects/Debris.tscn")
const repair_small_obj = preload("res://scenes/items/RepairSmall.tscn")
const repair_large_obj = preload("res://scenes/items/RepairLarge.tscn")
const mine_obj = preload("res://scenes/items/Mine.tscn")
const mech_obj = preload("res://test/MechActor.tscn")
const nav_obj = preload("res://Arena/NavPoint.tscn")
const msg_obj = preload("res://ui/DialogText.tscn")
const obj_explosion = preload("res://Effects/Explosion.tscn")

# Reference constants
const TILE_WIDTH = 2
const X_OFFSET = 1
const Z_OFFSET = 1
const skills = ["melee", "short", "long"]
const tile_data = [
	{"name":"wallA", "height":2, "angle":0, "move":2},
	{"name":"wallA_window", "height":2, "angle":0, "move":2},
	{"name":"wallA_garage", "height":2, "angle":0, "move":2},
	{"name":"wallA_door", "height":2, "angle":0, "move":2},
	{"name":"wallA_roof_top", "height":1, "angle":0, "move":4},
	{"name":"wallA_roof_side", "height":0.5, "angle":30, "move":3},
	{"name":"wallA_low", "height":1, "angle":0, "move":2},
	{"name":"wallB", "height":2, "angle":0, "move":2},
	{"name":"wallB_window", "height":2, "angle":0, "move":2},
	{"name":"wallB_garage", "height":2, "angle":0, "move":2},
	{"name":"wallB_door", "height":2, "angle":0, "move":2},
	{"name":"wallB_roof_top", "height":1, "angle":0, "move":4},
	{"name":"wallB_roof_side", "height":0.5, "angle":30, "move":3},
	{"name":"road_center", "height":0, "angle":0, "move":2},
	{"name":"road_side", "height":0, "angle":0, "move":2},
	{"name":"road_corner_in", "height":0, "angle":0, "move":2},
	{"name":"road_corner_out", "height":0, "angle":0, "move":2},
	{"name":"dirt", "height":0, "angle":0, "move":3},
	{"name":"grass", "height":0, "angle":0, "move":4},
	{"name":"pavement", "height":0, "angle":0, "move":2},
	{"name":"pave_damage", "height":0, "angle":0, "move":3},
	{"name":"grass_low", "height":1, "angle":0, "move":4},
	{"name":"grass_tall", "height":2, "angle":0, "move":4},
	{"name":"dirt_low", "height":1, "angle":0, "move":3},
	{"name":"dirt_tall", "height":2, "angle":0, "move":3},
]
const map_lights = {
	"Dawn":{
		"energy":0.25,
		"angle":-30,
		"env":"res://scenes/maps/env_dawn.tres"
	},
	"Mid-day":{
		"energy":1,
		"angle":-85,
		"env":"res://scenes/maps/env_day.tres"
	},
	"Dusk":{
		"energy":0.25,
		"angle":-150,
		"env":"res://scenes/maps/env_dusk.tres"
	},
	"Night":{
		"energy":0.01,
		"angle":-150,
		"env":"res://scenes/maps/env_night.tres"
	}
}

# Accessor variables for child nodes
onready var map_cam = $MapCamera

# General variables
export var debug : bool = false

# Map variables
var arena_map = null
var deploy_points : Array = []
# Format for nav_points entries: {index:{point, neighbors[], root, distance}, ...}
var nav_points : Dictionary = {}
var map_props : Dictionary = {
	"index":0,
	"path":"",
	"name":"",
	"light":"mid",
	"effect":"none"
}

# Team variables
var team_list : Array = []
var turn_queue : Array = []
var win_team : int = 0
var mech_tags : Array = []
var active_mech = null

# Movement variables:
var move_tiles = []
var move_target = null
var move_path = []
# Format for priority_list entries: [{tile, priority}]
var priority_list = []

# Attack/targeting variables
var attack_tiles = []
var attack_target = null
var attack_wpn = null
var global_range_max = 0
var global_range_min = 0
var unit_list = []
var enemies = []
var friends = []
var weapon_list = []
var item_list = []

# Turn/action variables:
var ai_weights = {
	"target_dist":1, "target_range":0.5, 
	"threat_dist":0, "threat_range":0, 
	"friend_dist":0, "repair":0
}
var timer = 0
var effects = []
var step = 0

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
	# Sort by distance, ascending
	static func distance(a, b):
		if a["distance"] < b["distance"]:
			return true
		return false
	# Sort by target, descending
	static func target(a, b):
		if a["target"] > b["target"]:
			return true
		return false
	# Sort by threat, descending
	static func threat(a, b):
		if a["threat"] > b["threat"]:
			return true
		return false


# --- TEMP FUNCTIONS FOR TEST ONLY ---
# --- REMOVE WHEN DEPLOYING ---
func roll_stats(mech):
	# Create new mech stat block
	var mech_data = MechData.new()
	mech_data.id = 0
	mech_data.pilot = PartDB.drone["0"]
	var partSet = str(randi() % PartDB.body.size())
	mech_data.body = PartDB.body[partSet]
	mech_data.arm_r = PartDB.arm[partSet]
	mech_data.arm_l = PartDB.arm[partSet]
	mech_data.legs = PartDB.legs[partSet]
	var wpnSet = str(randi() % PartDB.weapon.size())
	mech_data.wpn_r = PartDB.weapon[wpnSet]
	mech_data.wpn_l = PartDB.weapon[wpnSet]
	var podSet = str(randi() % PartDB.pod.size())
	mech_data.pod_r = PartDB.pod[podSet]
	mech_data.pod_l = PartDB.pod[podSet]
	mech_data.pack = PartDB.pack[str(randi() % PartDB.pack.size())]
	mech_data.mech_actor = mech
	turn_queue.append(mech_data)


# --- MAIN FUNCTIONS ---
# Called when the node enters the scene tree for the first time.
func _ready():
	load_map()
	var mech_list = $Mechs.get_children()
	for i in 2:
		for j in 4:
			roll_stats(mech_list[i*4 + j])
			turn_queue[i*4 + j].team = i
			mech_list[i*4 + j].connect("move_done", self, "think_act")
			mech_list[i*4 + j].connect("turn_done", self, "next_turn")
	yield(get_tree(), "idle_frame")
	map_cam.cam_mode = map_cam.CamState.DEBUG
	start_match()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
#	if is_instance_valid(active_mech.mech_actor):
#		map_cam.follow_mech(active_mech.mech_actor)
	update_markers()


# --- MAP FUNCTIONS ---
func load_map():
	arena_map = $Map
	var map_min = Vector3.ZERO
	var map_max = Vector3.ZERO
	
	# Setup light direction and intensity
	if is_instance_valid($Map/DirectionalLight):
		$Map/DirectionalLight.light_energy = map_lights["Dawn"].energy
		$Map/DirectionalLight.rotation_degrees.x = map_lights["Dawn"].angle
	# Load world environment
	if is_instance_valid($Map/WorldEnvironment):
		$Map/WorldEnvironment.environment = load(map_lights["Dawn"].env)
	# Build list of navigation points
	var curr_index = 0
	for coord in arena_map.tiles.get_used_cells():
		# Get mesh index of the cell and double check that it's valid
		var this_cell = arena_map.tiles.get_cell_item(coord.x, coord.y, coord.z)
		if this_cell != -1:
			# Update min/max extents of gridmap
			map_min.x = min(map_min.x, coord.x)
			map_min.y = min(map_min.y, coord.y)
			map_min.z = min(map_min.z, coord.z)
			map_max.x = max(map_max.x, coord.x)
			map_max.y = max(map_max.y, coord.y)
			map_max.z = max(map_max.z, coord.z)
			# If the tile is 0 height, a mech can stand on it, so place a nav point
			# If it's taller than 0, check the cell above to see if it's clear
			# If the cell above is clear, place a nav point
			var clear = true
			var tile_height = tile_data[this_cell].height
			if tile_height > 0:
				if arena_map.tiles.get_cell_item(coord.x, coord.y+1, coord.z) != -1:
					clear = false
			if clear:
				var nav_inst = nav_obj.instance()
				$NavPoints.add_child(nav_inst)
				nav_inst.index = str(curr_index)
				curr_index += 1
				nav_inst.grid_pos = coord
				nav_inst.base_move = 2 #tile_data[this_cell].move
				nav_inst.move_cost = 2 #tile_data[this_cell].move
				nav_inst.translation = (
					arena_map.tiles.map_to_world(coord.x, coord.y, coord.z) + 
					Vector3(0, tile_height, 0))
	# Now, link nav points to their neighboring nav points
	yield(get_tree(), "idle_frame")
	var from = Vector3.ZERO
	var to = Vector3.ZERO
	var space_state
	var raycast
	for point in $NavPoints.get_children():
		nav_points[point.index] = {"point":point, "neighbors":[], "root": null, "distance": 0}
		for n_point in $NavPoints.get_children():
			var diff = n_point.translation - point.translation
			if (abs(diff.x) == TILE_WIDTH && diff.z == 0) || (abs(diff.z) == TILE_WIDTH && diff.x == 0):
				from = point.translation + Vector3.UP
				to = n_point.translation + Vector3.UP
				if diff.y < 0:
					from = point.translation + Vector3(diff.x/TILE_WIDTH, 1, diff.z/TILE_WIDTH)
				elif diff.y > 0:
					to = n_point.translation - Vector3(diff.x/TILE_WIDTH, 1, diff.z/TILE_WIDTH)
				space_state = get_world().direct_space_state
				raycast = space_state.intersect_ray(from, to, [], 1)
				if raycast.empty():
					nav_points[point.index].neighbors.append(n_point.index)
		if randf() <= 0.3:
			point.add_effect("burn")
	var world_min = arena_map.tiles.map_to_world(map_min.x, map_min.y, map_min.z)
	var world_max = arena_map.tiles.map_to_world(map_max.x, map_max.y, map_max.z)
	map_cam.global_translation = 0.5 * (world_min + world_max)
	nav_reset()


func spawn_mech():
	pass


func clear_map():
	for mech in $Mechs.get_children():
		mech.queue_free()
	for item in $Items.get_children():
		item.queue_free()


# --- TURN AND ACTION FUNCTIONS ---
func start_match():
	active_mech = turn_queue.front()
	nav_update_positions()
	update_lists()
	think_move()


func next_turn():
	for point in $NavPoints.get_children():
		point.proc_effects()
	turn_queue.push_back(turn_queue.pop_front())
	while turn_queue.front().is_dead:
		turn_queue.push_back(turn_queue.pop_front())
	active_mech = turn_queue.front()
	nav_reset()
	nav_update_positions()
	update_lists()
	think_move()


func update_lists():
	for mech in turn_queue:
		if mech != active_mech:
			var info = {"mech":mech, "target":0.0, "threat":0.0}
			if (mech.team == active_mech.team):
				friends.append(info)
			else:
				enemies.append(info)
	unit_list = friends + enemies


func think_move():
	move_target = null
	# Don't do anything if stunned, dead, or move disabled
	# Calculate paths from starting point and get movement tiles
	for tile in move_tiles:
		tile.unmark()
	move_tiles.clear()
	nav_calc_paths(active_mech.curr_point, active_mech)
	var this_point = null
	for index in nav_points:
		this_point = nav_points[index]
		# Tile available for standing and within move range
		if this_point.distance <= active_mech.move_range && this_point.distance > 0:
			if this_point.point.curr_mech == null:
				this_point.point.can_move = true
				move_tiles.append(this_point.point)
	# Calculate threat and target levels for other units
	var unit_dist = 0
	var max_dist = 100 
	var near_dist = active_mech.move_range * 2
	for unit in unit_list:
		if !unit.mech.is_dead:
			unit_dist = get_distance(unit.mech.curr_point)
			unit.threat = 0.0
			unit.threat += unit.mech.get_hp_pct("arm_r") * 0.5
			unit.threat += unit.mech.get_hp_pct("arm_l") * 0.5
			unit.threat += unit.threat * clamp(1 - (unit_dist / max_dist), 0, 1)
			unit.target = 0.0
			unit.target += unit.mech.get_hp_pct("body") * 0.5
			unit.target += unit.mech.get_hp_pct("arm_r") * 0.2
			unit.target += unit.mech.get_hp_pct("arm_l") * 0.2
			unit.target += unit.mech.get_hp_pct("legs") * 0.1
			unit.target += unit.target * clamp(1 - (unit_dist / max_dist), 0, 1)
	# Main target position
	var main_target = null
	var target_near = false
	enemies.sort_custom(CustomSort, "target")
	main_target = enemies[0].mech.curr_point
	if is_instance_valid(main_target):
		unit_dist = get_distance(main_target)
		if unit_dist <= near_dist:
			target_near = true
	# Main threat position
	var main_threat = null
	var threat_near = false
	enemies.sort_custom(CustomSort, "threat")
	main_threat = enemies[0].mech.curr_point
	if is_instance_valid(main_threat):
		unit_dist = get_distance(main_threat)
		if unit_dist <= near_dist:
			threat_near = true
	# Closest friend position
	var close_friend = null
	friends.sort_custom(CustomSort, "threat")
	close_friend = friends[0].mech.curr_point
	# Nearest repair kit position
	var close_repair = null
	var d_min = 999
	for item in item_list:
		if item.is_in_group("repair"):
			var item_dist = get_distance(item.curr_tile)
			if item_dist < d_min:
				d_min = item_dist
				close_repair = item.curr_tile
	# Damage percentages
	var total_pct = (active_mech.get_hp_pct("body") * 0.5 +
		active_mech.get_hp_pct("arm_r") * 0.2 +
		active_mech.get_hp_pct("arm_l") * 0.2 +
		active_mech.get_hp_pct("legs") * 0.1)
	if close_repair != null:
		ai_weights.repair = (int(active_mech.get_hp_pct("arm_r") > 0.25) * 0.5 + 
			int(active_mech.get_hp_pct("arm_l") > 0.25) * 0.5)
		ai_weights.repair += (1.0 - total_pct)
	else:
		ai_weights.repair = 0.0
	if target_near:
		ai_weights.target_dist = 0.5
		ai_weights.target_range = 1.0
		ai_weights.friend_dist = 0.0
	else:
		ai_weights.target_dist = 1.0
		ai_weights.target_range = 0.0
		ai_weights.friend_dist = 0.5
	if threat_near:
		ai_weights.threat_dist = 0.0
		ai_weights.threat_range = 0.0
	else:
		ai_weights.threat_dist = 0.0
		ai_weights.threat_range = 0.0
	# Go through movement squares and calculate position values
	priority_list.clear()
	var priority = 0
	var goal_dist = 0
	var goal_range = 0
	var tile_value = 0
	for tile in move_tiles:
		priority = 0
		nav_calc_paths(active_mech.curr_point, active_mech)
		if main_target != null:
			# Distance from tile to main target
			goal_dist = get_distance(main_target)
			tile_value = clamp(1 - (goal_dist / max_dist), 0, 1)
			priority += tile_value * ai_weights.target_dist
			# Can we shoot at this tile?
			if tile.get_los(main_target):
				tile_value = 0
				goal_range = get_range(tile, main_target)
				for weapon in weapon_list:
					if weapon.active and (goal_range >= weapon.range_min) and (goal_range <= weapon.range_max):
						tile_value = clamp(1 - (goal_range / weapon.range_max), 0, 1) * 0.25
				priority += tile_value * ai_weights.target_range
		if main_threat != null:
			# Distance from tile to main threat
			goal_dist = get_distance(main_threat)
			tile_value = clamp(goal_dist / max_dist, 0, 1)
			priority += tile_value * ai_weights.threat_dist
			# Can the threat shoot at this tile?
			if global_range_max != 0:
				if !tile.get_los(main_threat):
					goal_range = get_range(tile, main_threat)
					tile_value = clamp(goal_range / global_range_max, 0, 1)
					priority += tile_value * ai_weights.threat_range
		# Distance from tile to nearest repair kit
		if close_repair != null:
			if tile == close_repair:
				priority += ai_weights.repair
			else:
				goal_dist = get_distance(close_repair)
				tile_value = clamp(1 - (goal_dist / max_dist), 0, 1)
				priority += tile_value * ai_weights.repair
		# Distance to closest fighting ally
		if close_friend != null:
			goal_dist = get_distance(close_friend)
			tile_value = clamp(1 - (goal_dist / max_dist), 0, 1)
			priority += tile_value * ai_weights.friend_dist
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
		move_target = active_mech.curr_point
	#print("Think move")
	active_mech.mech_actor.move(move_target)


func think_act():
	#print("Think act")
	active_mech.mech_actor.act()


func update_markers():
	var this_actor = active_mech.mech_actor
	if is_instance_valid(this_actor):
		$Markers/Select.translation = this_actor.translation + Vector3(0, 0.02, 0)
		$Markers/Select.visible = true
		if is_instance_valid(move_target):
			$Markers/Move.translation = move_target.translation + Vector3(0, 0.02, 0)
			$Markers/Move.visible = true
		else:
			$Markers/Move.visible = false
		if is_instance_valid(attack_target):
			$Markers/Target.translation = attack_target.translation + Vector3(0, 0.02, 0)
			$Markers/Target.visible = true
		else:
			$Markers/Target.visible = false
	else:
		$Markers/Select.visible = false
		$Markers/Move.visible = false
		$Markers/Target.visible = false


# --- NAV MANAGEMENT ---
# Calculate navigation paths and distances for a given Mech object from a given origin point
# PARAM: 'origin' is a valid NavPoint object
# PARAM: 'mech' is a valid Mech object that is alive
func nav_calc_paths(origin, mech):
	# Reminder: for loop on Dictionaries will loop through KEYS only
	# Reminder: queue is an array of index strings, the front is the frontier
	# Reminder: frontier is an index string, look up all related vars appropriately
	nav_reset()
	var queue = []
	var frontier = origin.index
	var next_dist = 0
	var front_point = null
	var n_point = null
	queue.push_back(frontier)
	while !queue.empty():
		frontier = queue.pop_front()
		#print("Frontier has " + str(frontier.neighbors.size()) + " neighbors")
		for n_index in nav_points[frontier].neighbors:
			front_point = nav_points[frontier].point
			n_point = nav_points[n_index].point
			next_dist = nav_points[frontier].distance + n_point.move_cost
			# Within mech's jump height
			if abs(n_point.translation.y - front_point.translation.y) <= mech.jump_height:
				if n_point != origin:
					# Not rooted yet
					if nav_points[n_index].root == null:
						# TODO: This conditional is fucking up the distance calcs
						# Problem: Enemy mech squares are treated as impassable, and 'disconnected' from nav_paths{}
						# So, when we go to get the move distance to an enemy square, it returns 0
						# Solution: Take closest distance of neighboring squares?
						# Point available (or used by team-mate)
						if n_point.curr_mech == null || n_point.curr_mech.team == mech.team || n_point.curr_mech.is_dead:
							nav_points[n_index].root = frontier
							nav_points[n_index].distance = next_dist
							queue.push_back(n_index)
					# Already rooted, update if distance is shorter
					elif next_dist < nav_points[n_index].distance:
						nav_points[n_index].root = frontier
						nav_points[n_index].distance = next_dist
						queue.push_back(n_index)


# Update positions of all objects in map
func nav_update_positions():
	for mech in turn_queue:
		mech.curr_point = mech.mech_actor.update_pos()
	for item in $Items.get_children():
		pass


# Reset pathing variables (root and distance)
func nav_reset():
	for point in nav_points:
		nav_points[point].root = null
		nav_points[point].distance = 0


# --- UTILS ---
# Get Manhattan distance between nav points
func get_range(from, to):
	return (abs(to.grid_pos.x - from.grid_pos.x) + abs(to.grid_pos.z - from.grid_pos.z))


func get_distance(point):
	var d_min = 999.0
	for n_index in nav_points[point.index].neighbors:
		if nav_points[n_index].distance < d_min && nav_points[n_index].distance > 0:
			d_min = float(nav_points[n_index].distance)
	return d_min


func attack_calc():
	pass


func combat_run():
	pass

