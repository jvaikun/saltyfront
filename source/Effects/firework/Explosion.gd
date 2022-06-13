extends Spatial


onready var particles = $Particles


# Called when the node enters the scene tree for the first time.
func _ready():
	particles.one_shot = true
	particles.color_ramp = load("res://Effects/firework/explosion%d_gradient.tres" % (randi() % 6))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !particles.emitting:
		queue_free()
	pass
