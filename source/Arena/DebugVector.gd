extends Control

var camera = null
var focus_mech = null
var draw_vect = true
var map_grid
var font

# Called when the node enters the scene tree for the first time.
func _ready():
	font = DynamicFont.new()
	font.font_data = load("res://ui/fonts/font_square_mini.ttf")
	font.size = 16

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _draw():
	if focus_mech != null:
		var start = camera.unproject_position(focus_mech.global_transform.origin)
		var end = camera.unproject_position(focus_mech.global_transform.origin)
		for item in focus_mech.priority_list:
			draw_string(font, camera.unproject_position(item.tile.global_transform.origin), "%.3f" % (item.priority))
		for index in focus_mech.nav_paths:
			if focus_mech.nav_paths[index].root != null:
				var from = camera.unproject_position(map_grid[index].tile.global_transform.origin)
				var to = camera.unproject_position(map_grid[focus_mech.nav_paths[index].root].tile.global_transform.origin)
				draw_line(from, to, Color(1,1,1), 2)
		for tile in focus_mech.move_path:
			end = camera.unproject_position(tile.global_transform.origin)
			draw_line(start, end, Color(0, 0, 1), 4)
			start = camera.unproject_position(tile.global_transform.origin)
