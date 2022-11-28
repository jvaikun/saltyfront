extends Spatial

onready var mesh = $Mesh
onready var label = $Viewport/Label
onready var tween = $Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	tween.connect("tween_all_completed", self, "queue_free")
	var goal = self.get_translation()
	goal.x += (randi() % 5 - 2) * 0.3
	goal.y += (randi() % 5 - 2) * 0.1
	goal.z += (randi() % 5 - 2) * 0.3
	tween.interpolate_property(self, "translation", 
	self.get_translation(), goal, 0.4,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.interpolate_property(mesh.material_override, "albedo_color",
	Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.4,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
