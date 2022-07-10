extends Particles

var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	started = true
	emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if started and !emitting:
		queue_free()
