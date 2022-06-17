extends Spatial

var curr_tile = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("explosive")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Model.rotation_degrees.y += 180 * delta
