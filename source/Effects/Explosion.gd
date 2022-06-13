extends Spatial

onready var sprite = $ExpSprite
onready var frags = $ExpParticle
onready var wave = $Shockwave

func _ready():
	var sounds = $Sounds.get_resource_list()
	$Player.stream = $Sounds.get_resource(sounds[randi() % sounds.size()])
	$Player.play()
	sprite.visible = true
	sprite.frame = 0
	sprite.play()
	frags.emitting = true
	wave.emitting = true

func _process(_delta):
	if (sprite.frame >= sprite.frames.get_frame_count("default")-1):
		sprite.visible = false
	if (!frags.emitting && !wave.emitting):
		queue_free()
