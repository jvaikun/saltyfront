extends Spatial

const TILE_WIDTH = 2
const X_OFFSET = 1
const Z_OFFSET = 1
const PITCH_MIN = -45
const PITCH_MAX = 0
const nav_obj = preload("res://Arena/NavPoint.tscn")
const obj_firework = preload("res://Effects/firework/Explosion.tscn")
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

onready var debug_info = $Debug/DebugInfo
onready var mech_prod = $Mechs/Mech1
onready var cam_base = $MapCamera
onready var cam_pivot = $MapCamera.pivot
onready var cam_camera = $MapCamera.cam

var nav_grid = {}
var turns_queue = []
var arena_map = null
var emit_point = null
var nav_toggle = true
var nav_focus = 0
var part_set = 0
var mouse_sensitivity = 0.05
var mech_select = 0


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


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	load_map()
	$Debug/Vectors.camera = cam_camera
	$Debug/Vectors.focus_mech = mech_prod
	$Debug/Vectors.nav_points = $Nav.get_children()
	$MapCamera.rotation_degrees.y = 0
	$MapCamera/Pivot.rotation_degrees.x = -90
	mech_prod.connect("move_done", self, "nav_update")
	turns_queue = $Mechs.get_children()
	for mech in turns_queue:
		if mech == mech_prod:
			mech.team = 0
		else:
			mech.team = 1
	for mech in turns_queue:
		roll_stats(mech)
		mech.state = mech.MechState.DONE
	nav_update()
	cam_base.follow_mech(turns_queue[mech_select])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		calc_values(mech_prod)
	if Input.is_action_just_pressed("ui_end"):
		reroll_all()
	# Screenshot
	if Input.is_action_just_pressed("ui_screenshot"):
		GameData.screenshot()
	$Debug/Vectors.update()


func reroll_all():
	for mech in $Mechs.get_children():
		roll_stats(mech)


func roll_stats(mech):
	# Create new mech stat block
	var stats = MechStats.new()
	stats.id = 0
	stats.pilot = PartDB.drone["0"]
	# var partSet = str(randi() % PartDB.body.size())
	var partSet = str(part_set)
	part_set += 1
	if part_set >= PartDB.body.size():
		part_set = 0
	stats.body = PartDB.body[partSet]
	stats.arm_r = PartDB.arm[partSet]
	stats.arm_l = PartDB.arm[partSet]
	stats.legs = PartDB.legs[partSet]
	var wpnSet = "4" #str(randi() % PartDB.weapon.size())
	stats.wpn_r = PartDB.weapon[wpnSet]
	stats.wpn_l = PartDB.weapon[wpnSet]
	var podSet = str(randi() % PartDB.pod.size())
	stats.pod_r = PartDB.pod[podSet]
	stats.pod_l = PartDB.pod[podSet]
	stats.pack = PartDB.pack[str(randi() % PartDB.pack.size())]
	# Attach stat block to mech
	mech.mechData = stats
	mech.setup(self)


func nav_update():
	nav_reset()
	var mechs = $Mechs.get_children()
	for point in $Nav.get_children():
		point.curr_mech = null
		point.curr_item = null
		for mech in mechs:
			if !mech.is_dead:
				if (point.translation - mech.translation).length() < 0.1:
					point.curr_mech = mech
					mech.curr_tile = point


func nav_reset():
	for point in $Nav.get_children():
		point.reset_data()


func load_map():
	arena_map = $Map
	var map_min = Vector3.ZERO
	var map_max = Vector3.ZERO
	
	# Setup light direction and intensity
	if is_instance_valid($Map/DirectionalLight):
		$Map/DirectionalLight.light_energy = map_lights["Mid-day"].energy
		$Map/DirectionalLight.rotation_degrees.x = map_lights["Dawn"].angle
	# Load world environment
	if is_instance_valid($Map/WorldEnvironment):
		$Map/WorldEnvironment.environment = load(map_lights["Mid-day"].env)
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
				$Nav.add_child(nav_inst)
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
	for point in $Nav.get_children():
		nav_grid[point.index] = {"tile":point, "neighbors":[]}
		for n_point in $Nav.get_children():
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
					nav_grid[point.index].neighbors.append(n_point.index)
	var world_min = arena_map.tiles.map_to_world(map_min.x, map_min.y, map_min.z)
	var world_max = arena_map.tiles.map_to_world(map_max.x, map_max.y, map_max.z)
	cam_base.origin = 0.5 * (world_min + world_max)
	nav_update()


func calc_values(focus_mech):
	focus_mech.move_target = null
	# Calculate paths from starting point and get movement tiles
	for tile in focus_mech.move_tiles:
		tile.unmark()
	focus_mech.move_tiles.clear()
	focus_mech.calc_paths(focus_mech.curr_tile)
	var this_node = null
	var this_tile = null
	for index in focus_mech.nav_paths:
		this_tile = focus_mech.map_grid[index].tile
		this_node = focus_mech.nav_paths[index]
		# Tile available for standing and within move range
		if this_node.distance <= focus_mech.move_range && this_node.distance > 0:
			if this_tile.curr_mech == null:
				this_tile.can_move = true
				focus_mech.move_tiles.append(this_tile)
	for unit in focus_mech.unit_list:
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
	focus_mech.unit_list.sort_custom(CustomSort, "target_sort")
	# Nearest repair kit
	var near_repair = null
	var d_min = 999
	for item in focus_mech.item_list:
		if item.is_in_group("repair"):
			var item_dist = focus_mech.get_distance(item.curr_tile)
			if item_dist < d_min:
				d_min = item_dist
				near_repair = item.curr_tile
	# Determine our AI state
	var aggression = 1.0
	if (focus_mech.armRHP <= 0 and focus_mech.armLHP <= 0):
		aggression = 0
		focus_mech.ai_state = focus_mech.AIState.RETREAT
	else:
		aggression = float(focus_mech.bodyHP / focus_mech.mechData.body.hp) * 0.5
		aggression += float(focus_mech.armLHP / focus_mech.mechData.arm_l.hp) * 0.2
		aggression += float(focus_mech.armRHP / focus_mech.mechData.arm_r.hp) * 0.2
		aggression += float(focus_mech.legsHP / focus_mech.mechData.legs.hp) * 0.1
		if aggression >= 0.5:
			focus_mech.ai_state = focus_mech.AIState.NORMAL
		else:
			focus_mech.ai_state = focus_mech.AIState.DEFENSIVE
	var tile_goal = null
	match focus_mech.ai_state:
		# Aggressive: Attack nearest armed target, ignore repair kits and cover
		focus_mech.AIState.AGGRESSIVE:
			tile_goal = focus_mech.unit_list[0].mech.curr_tile
		# Standard: Attack nearest armed target, consider cover
		focus_mech.AIState.NORMAL:
			tile_goal = focus_mech.unit_list[0].mech.curr_tile
		# Defensive: Only attack safe targets, consider cover and repair kits
		focus_mech.AIState.DEFENSIVE:
			if !(near_repair == null):
				tile_goal = near_repair
			else:
				tile_goal = focus_mech.unit_list[0].mech.curr_tile
		# Retreat: Avoid enemies, seek repair kits and cover, move toward allies
		focus_mech.AIState.RETREAT:
			if !(near_repair == null):
				tile_goal = near_repair
	# Go through movement squares and calculate position values
	focus_mech.update_wpn()
	focus_mech.priority_list.clear()
	var priority = 0
	var max_priority = 0
	if $Debug/PanelContainer/VBoxContainer/CheckBox.pressed:
		max_priority += 1
	if $Debug/PanelContainer/VBoxContainer/CheckBox2.pressed:
		max_priority += 1
	if $Debug/PanelContainer/VBoxContainer/CheckBox3.pressed:
		max_priority += 1
	if $Debug/PanelContainer/VBoxContainer/CheckBox4.pressed:
		max_priority += 1
	if max_priority == 0:
		max_priority = 1
	for tile in focus_mech.move_tiles:
		var goal_dist = 0
		priority = 0
		focus_mech.calc_paths(tile)
		# Distance to main target
		if $Debug/PanelContainer/VBoxContainer/CheckBox.pressed:
			if !(tile_goal == null):
				goal_dist = focus_mech.get_distance(tile_goal)
				priority += clamp((focus_mech.move_range / goal_dist), 0, 1)
		# Distance to repair kit
		if $Debug/PanelContainer/VBoxContainer/CheckBox2.pressed:
			for item in focus_mech.item_list:
				if item.is_in_group("repair"):
					if (tile == item.curr_tile):
						priority += 1.0
					else: 
						var item_dist = focus_mech.get_distance(item.curr_tile)
						priority += clamp((focus_mech.move_range / item_dist), 0, 1)
		# Has line of sight to enemy
		if $Debug/PanelContainer/VBoxContainer/CheckBox3.pressed:
			if tile.get_los(focus_mech.curr_tile):
				priority += 1.0
		if $Debug/PanelContainer/VBoxContainer/CheckBox4.pressed:
			pass
		focus_mech.priority_list.append({"tile":tile, "priority":priority})
	# If priority_list isn't empty, choose a move target, default to current tile if empty
	if !focus_mech.priority_list.empty():
		var heat_min = Color(0, 0, 1)
		var heat_max = Color(1, 0, 0)
		var heat_color = Color(0, 0, 1)
		for item in focus_mech.priority_list:
			heat_color = heat_min.linear_interpolate(heat_max, item.priority / max_priority)
			item.tile.highlight.material_override.albedo_color = heat_color
		# Sort priority list, get max values
		focus_mech.priority_list.sort_custom(CustomSort, "priority")
		var max_list = []
		for item in focus_mech.priority_list:
			if item.priority == focus_mech.priority_list[0].priority:
				max_list.append(item)
		# Pick one of the max priority tiles, get the path to it
		if max_list.size() == 1:
			focus_mech.move_target = max_list[0].tile
		else:
			focus_mech.move_target = max_list[randi() % max_list.size()].tile
	else:
		focus_mech.move_target = focus_mech.curr_tile
	focus_mech.get_move_path()
