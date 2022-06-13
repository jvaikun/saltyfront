extends Spatial

onready var tiles = $GridMap
onready var deploy_points = $DeployPoints.get_children()
onready var flyby_track = $Path/PathFollow
onready var flyby_cam = $Path/PathFollow/FlyCam

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
