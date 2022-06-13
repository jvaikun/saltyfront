extends Control

const ANIM_SPD = 2

var nbr_of_shards = 64
var threshhold = 128
var triangles = []
var from_list = []
var to_list = []
var shards = []
var do_anim = false
var progress = 0

func _ready():
	randomize()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		$AnimationPlayer.play("dissolve2")
		yield(get_tree().create_timer(1.25), "timeout")
		$AnimationPlayer.play("melt")
		yield(get_tree().create_timer(1.25), "timeout")
		$AnimationPlayer.play("dissolve")
		yield(get_tree().create_timer(1.25), "timeout")
		$AnimationPlayer.play_backwards("dissolve")
		yield(get_tree().create_timer(1.25), "timeout")
		$AnimationPlayer.play_backwards("melt")
		yield(get_tree().create_timer(1.25), "timeout")
		$AnimationPlayer.play_backwards("dissolve2")
	if Input.is_action_just_pressed("ui_home"):
		$TextureRect2.visible = true
		yield(get_tree(), "idle_frame")
		triangles.clear()
		var scrn_size = get_viewport().size
		var points = []
		for i in range(0, scrn_size.x+1, 64):
			for j in range(0, scrn_size.y+1, 64):
				var x_off = (randf() * 32) - 16
				var y_off = (randf() * 32) - 16
				points.append(Vector2(i + x_off, j + y_off))
		var delaunay = Geometry.triangulate_delaunay_2d(points)
		for i in range(0, delaunay.size(), 3):
			triangles.append([points[delaunay[i + 2]], points[delaunay[i + 1]], points[delaunay[i]]])
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		var screenshot = ImageTexture.new()
		screenshot.create_from_image(img)
		$TextureRect2.visible = false
		for shard in shards:
			shard.free()
		shards.clear()
		from_list.clear()
		to_list.clear()
		for t in triangles:
			var shard = Polygon2D.new()
			var center = Vector2((t[0].x + t[1].x + t[2].x)/3.0,(t[0].y + t[1].y + t[2].y)/3.0)
			var offset_t = [t[0] - center, t[1] - center, t[2] - center]
			var start_pos = Vector2(center.x, scrn_size.y)
			# Vector2(scrn_size.x/2, scrn_size.y/2) 
			# Vector2(randi() % int(scrn_size.x), randi() % int(scrn_size.y))
			# Vector2(rand_range(0, scrn_size.x), scrn_size.y)
			shards.append(shard)
			from_list.append(start_pos)
			to_list.append(center)
			add_child(shard)
			shard.texture = screenshot
			shard.polygon = offset_t
			shard.texture_offset = center
			shard.position = start_pos
			#shard.rotation_degrees = randi() % 360
		update()
		for i in shards.size():
			$Tween.interpolate_property(shards[i], "position",
			to_list[i], from_list[i], rand_range(0.5, 1.0), Tween.TRANS_EXPO, Tween.EASE_IN)
		$Tween.start()

