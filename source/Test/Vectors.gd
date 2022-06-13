extends Control

var camera = null
var focus_mech = null
var draw_vect = true
var nav_points = null
var focus_point = null
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
		for tile in focus_mech.move_path:
			end = camera.unproject_position(tile.global_transform.origin)
			draw_line(start, end, Color(1, 1, 1), 1)
			start = camera.unproject_position(tile.global_transform.origin)
	if focus_point != null:
		var line_start = camera.unproject_position(focus_point.global_transform.origin)
		for neighbor in focus_point.neighbors:
			var line_end = camera.unproject_position(neighbor.global_transform.origin)
			draw_line(line_start, line_end, Color(0, 0, 1), 2)
#	elif nav_points != null:
#		var counter = 0
#		for point in nav_points:
#			draw_string(font, camera.unproject_position(point.global_transform.origin), str(counter))
#			counter += 1
