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


# Called when the node enters the scene tree for the first time.
func _ready():
	load_map()
	var mech_list = $Mechs.get_children()
	for i in 2:
		for j in 4:
			roll_stats(mech_list[i*4 + j])
			turn_queue[i*4 + j].team = i
			mech_list[i*4 + j].connect("turn_done", self, "next_turn")
	start_match()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_instance_valid(active_mech):
		map_cam.follow_mech(active_mech)
	update_markers()


# --- MAP ---
func load_map():
	arena_map = $Map
	var map_min = Vector3.ZERO
	var map_max = Vector3.ZERO
	
	# Setup light direction and intensity
	if is_instance_valid($Map/DirectionalLight):
		$Map/DirectionalLight.light_energy = map_lights["Night"].energy
		$Map/DirectionalLight.rotation_degrees.x = map_lights["Night"].angle
	# Load world environment
	if is_instance_valid($Map/WorldEnvironment):
		$Map/WorldEnvironment.environment = load(map_lights["Night"].env)
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
				nav_inst.base_move = tile_data[this_cell].move
				nav_inst.move_cost = tile_data[this_cell].move
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
	var world_min = arena_map.tiles.map_to_world(map_min.x, map_min.y, map_min.z)
	var world_max = arena_map.tiles.map_to_world(map_max.x, map_max.y, map_max.z)
	map_cam.origin = 0.5 * (world_min + world_max)
	nav_reset()


func spawn_mech():
	pass


func clear_map():
	for mech in $Mechs.get_children():
		mech.queue_free()
	for item in $Items.get_children():
		item.queue_free()


# --- TURNS ---
func start_match():
	active_mech = turn_queue.front().mech_actor
	active_mech.move()


func next_turn():
	turn_queue.push_back(turn_queue.pop_front())
	while turn_queue.front().is_dead:
		turn_queue.push_back(turn_queue.pop_front())
	active_mech = turn_queue.front().mech_actor
	active_mech.move()


func update_markers():
	if is_instance_valid(active_mech):
		$Markers/Select.translation = active_mech.translation + Vector3(0, 0.02, 0)
		$Markers/Select.visible = true
		if is_instance_valid(active_mech.move_target):
			$Markers/Move.translation = active_mech.move_target.translation + Vector3(0, 0.02, 0)
			$Markers/Move.visible = true
		else:
			$Markers/Move.visible = false
		if is_instance_valid(active_mech.attack_target):
			$Markers/Target.translation = active_mech.attack_target.translation + Vector3(0, 0.02, 0)
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


func get_distance(tile):
	var d_min = 999.0
	for n_index in map_grid[tile.index].neighbors:
		if nav_paths[n_index].distance < d_min && nav_paths[n_index].distance > 0:
			d_min = float(nav_paths[n_index].distance)
	return d_min


func attack_calc():
	pass


func combat_run():
	pass

