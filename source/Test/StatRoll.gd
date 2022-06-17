extends GridContainer

const PILOT_CLASS = {
	"Melee": {"melee":6, "short":1, "long":1, "dodge":3},
	"Short": {"melee":1, "short":6, "long":1, "dodge":3},
	"Long": {"melee":1, "short":1, "long":6, "dodge":3},
	"Melee/Short": {"melee":3, "short":3, "long":1, "dodge":3},
	"Melee/Long": {"melee":3, "short":1, "long":3, "dodge":3},
	"Short/Long": {"melee":1, "short":3, "long":3, "dodge":3}
}
const MECH_LOADOUT = {
	"Melee": {"light":{}, "heavy":{}},
	"Short": {"light":{}, "heavy":{}},
	"Long": {"light":{}, "heavy":{}},
	"Melee/Short": {"light":{}, "heavy":{}},
	"Melee/Long": {"light":{}, "heavy":{}},
	"Short/Long": {"light":{}, "heavy":{}}
}

onready var stats = {
	"melee":{"value":0, "bar":$TextureProgress, "label":$Label5},
	"short":{"value":0, "bar":$TextureProgress2, "label":$Label6},
	"long":{"value":0, "bar":$TextureProgress3, "label":$Label7},
	"dodge":{"value":0, "bar":$TextureProgress4, "label":$Label8},
}
onready var lbl_class = $LblClass2

# Called when the node enters the scene tree for the first time.
func _ready():
	update_values()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		var class_list = PILOT_CLASS.keys()
		var class_key = class_list[randi() % class_list.size()]
		var pilot_class = PILOT_CLASS[class_key]
		var weights = []
		for stat in pilot_class.keys():
			for i in pilot_class[stat]:
				weights.append(stat)
		lbl_class.text = class_key
		for stat in stats.keys():
			stats[stat].value = 20
		for i in 16:
			var pick = weights[randi() % weights.size() - 1]
			stats[pick].value += 5
			#print([pick, stats[pick].value])
		update_values()


func update_values():
	for stat in stats.keys():
		stats[stat].bar.value = stats[stat].value
		stats[stat].label.text = str(stats[stat].value)
