extends Spatial

const TILE_WIDTH = 2
const X_OFFSET = 1
const Z_OFFSET = 1
const PITCH_MIN = -45
const PITCH_MAX = 0

const missile_obj = preload("res://scenes/projectile/MissileFire.tscn")
const nav_obj = preload("res://Arena/NavPoint.tscn")
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
onready var mech_targ = $Mechs/Mech2
onready var map_cam = $MapCamera

var nav_grid = {}
var turns_queue = []
var arena_map = null
var emit_point = null
var nav_toggle = true
var nav_focus = 0
var part_set = 0
var mouse_sensitivity = 0.05
var mech_select = 0
var lighting = "Dawn"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	load_map()
	#cam_flyby = $Map.flyby_cam
	$Debug/Vectors.camera = map_cam.cam
	$Debug/Vectors.focus_mech = mech_prod
	$Debug/Vectors.nav_points = $Nav.get_children()
	nav_update()
	mech_prod.connect("move_done", self, "nav_update")
	$Items/Bomb.connect("exploded", self, "test_aoe")
	turns_queue = $Mechs.get_children()
	for mech in turns_queue:
		mech.team = randi() % 8
	for mech in turns_queue:
		roll_stats(mech)
		mech.state = mech.MechState.DONE
	map_cam.follow_mech(turns_queue[mech_select])

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(1):
			var cam_fwd = map_cam.yaw_node.global_transform.basis.z
			var move_z = -cam_fwd * event.relative.y * mouse_sensitivity
			var move_y = cam_fwd.cross(Vector3.UP) * event.relative.x * mouse_sensitivity
			map_cam.global_translate(move_z + move_y)
		elif Input.is_mouse_button_pressed(2):
			map_cam.yaw -= event.relative.x * mouse_sensitivity
			map_cam.pitch -= event.relative.y * mouse_sensitivity
	elif event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN):
			map_cam.zoom += 2
		elif Input.is_mouse_button_pressed(BUTTON_WHEEL_UP):
			map_cam.zoom -= 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		#$Items/Bomb.explode()
		$ModularArmature.anim_walk()
		$ModularArmature2.anim_walk()
		$ModularArmature3.anim_walk()
		$ModularArmature4.anim_walk()
		var tween_time = 12
		var tween_offset = Vector3(0,0,-20)
		var tween = get_tree().create_tween()
		tween.tween_property($ModularArmature, "translation", $ModularArmature.translation + tween_offset, tween_time)
		tween.parallel().tween_property($ModularArmature2, "translation", $ModularArmature2.translation + tween_offset, tween_time)
		tween.parallel().tween_property($ModularArmature3, "translation", $ModularArmature3.translation + tween_offset, tween_time)
		tween.parallel().tween_property($ModularArmature4, "translation", $ModularArmature4.translation + tween_offset, tween_time)
		tween.play()
	if Input.is_key_pressed(KEY_1):
		$Items/Bomb.type = "acid"
	if Input.is_key_pressed(KEY_2):
		$Items/Bomb.type = "burn"
	if Input.is_key_pressed(KEY_3):
		$Items/Bomb.type = "chaff"
	if Input.is_key_pressed(KEY_4):
		$Items/Bomb.type = "smoke"
	if Input.is_action_just_pressed("ui_home"):
		if $Items.get_child_count() == 0:
			for point in $Nav.get_children():
				point.clear_effects()
			var bomb_obj = load("res://scenes/items/Bomb.tscn")
			var bomb_inst = bomb_obj.instance()
			$Items.add_child(bomb_inst)
			bomb_inst.name = "Bomb"
			bomb_inst.translation = Vector3(13, 0, 19)
			#bomb_inst.explode_radius = Vector3(8, 0.25, 8)
			bomb_inst.connect("exploded", self, "test_aoe")
			nav_update()
#		test_attack()
#		mech_select += 1
#		if mech_select >= turns_queue.size():
#			mech_select = 0
#		cam_base.follow_mech(turns_queue[mech_select])
	if Input.is_action_just_pressed("ui_end"):
		reroll_all()
	if Input.is_action_just_pressed("ui_page_down"):
		if map_cam.cam_mode == map_cam.CamState.NORMAL:
			map_cam.cam_mode = map_cam.CamState.PHOTO
		else:
			map_cam.cam_mode = map_cam.CamState.NORMAL
	# Screenshot
	if Input.is_action_just_pressed("ui_screenshot"):
		GameData.screenshot()
	$Debug/Vectors.update()

func test_aoe(center, radius, effect):
	var final_list = []
	var curr_list = []
	var next_list = []
	final_list.append(nav_grid[center])
	curr_list.append(nav_grid[center])
	nav_grid[center].tile.add_effect(effect)
	for i in radius:
		for point in curr_list:
			for neighbor in point.neighbors:
				if !(nav_grid[neighbor] in final_list):
					final_list.append(nav_grid[neighbor])
					nav_grid[neighbor].tile.add_effect(effect)
					next_list.append(nav_grid[neighbor])
		curr_list = next_list.duplicate(true)
		next_list.clear()
		#yield(get_tree().create_timer(0.2), "timeout")

func test_attack():
	var test_type = "mgun"
	mech_prod.attack_target = $Mechs/Mech2
	for weapon in mech_prod.weapon_list:
		if weapon.type == test_type:
			mech_prod.attack_wpn = weapon
	var shots = [
		{ "type":test_type, "target":$Mechs/Mech2, "part":"body", "dmg":5, "crit":1 },
		{ "type":test_type, "target":$Mechs/Mech2, "part":"body", "dmg":5, "crit":1 },
		{ "type":test_type, "target":$Mechs/Mech2, "part":"body", "dmg":5, "crit":1 },
		{ "type":test_type, "target":$Mechs/Mech2, "part":"body", "dmg":5, "crit":1 },
		{ "type":test_type, "target":$Mechs/Mech2, "part":"body", "dmg":5, "crit":1 },
	]
	mech_prod.do_attack(shots)

func next_mech():
	turns_queue.push_back(turns_queue.pop_front())
	turns_queue.front().reset_acts()

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
	var items = $Items.get_children()
	for point in $Nav.get_children():
		point.curr_mech = null
		point.curr_item = null
		for mech in mechs:
			if !mech.is_dead:
				if (point.translation - mech.translation).length() < 0.1:
					point.curr_mech = mech
					mech.curr_tile = point
		for item in items:
			if (point.translation - item.translation).length() < 0.1:
				point.curr_item = item
				item.curr_tile = point


func nav_reset():
	for point in $Nav.get_children():
		point.reset_data()


func load_map():
	arena_map = $Map
	var map_min = Vector3.ZERO
	var map_max = Vector3.ZERO
	
	# Setup light direction and intensity
	if is_instance_valid($Map/DirectionalLight):
		$Map/DirectionalLight.light_energy = map_lights[lighting].energy
		$Map/DirectionalLight.rotation_degrees.x = map_lights[lighting].angle
	# Load world environment
	if is_instance_valid($Map/WorldEnvironment):
		$Map/WorldEnvironment.environment = load(map_lights[lighting].env)
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
#		if randf() <= 0.3:
#			point.add_effect("smoke")
	var world_min = arena_map.tiles.map_to_world(map_min.x, map_min.y, map_min.z)
	var world_max = arena_map.tiles.map_to_world(map_max.x, map_max.y, map_max.z)
	map_cam.origin = 0.5 * (world_min + world_max)
	nav_update()

