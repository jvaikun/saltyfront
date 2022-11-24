extends Spatial

const file_path = "res://scenes/parts/%s/mech_%s.tscn"
const part_ids = ["00","01","02","03","04","05","06","07","08","09","10",]
const part_list = [
	"arml",
	"armr",
	"body",
	"legs",
]

var anim_arml
var anim_armr
var anim_body
var anim_legs

# Called when the node enters the scene tree for the first time.
func _ready():
	var legs_inst = load(file_path % ["legs", "legs" + part_ids[randi() % part_ids.size()]]).instance()
	add_child(legs_inst)
	anim_legs = legs_inst.get_node("AnimationPlayer")
	
	var body_inst = load(file_path % ["body", "body" + part_ids[randi() % part_ids.size()]]).instance()
	legs_inst.get_node("Armature/Skeleton/Hip").add_child(body_inst)
	#anim_body = body_inst.get_node("AnimationPlayer")
	
	var arml_inst = load(file_path % ["arml", "arml" + part_ids[randi() % part_ids.size()]]).instance()
	body_inst.get_node("Armature/Skeleton/ArmL").add_child(arml_inst)
	anim_arml = arml_inst.get_node("AnimationPlayer")
	
	var armr_inst = load(file_path % ["armr", "armr" + part_ids[randi() % part_ids.size()]]).instance()
	body_inst.get_node("Armature/Skeleton/ArmR").add_child(armr_inst)
	anim_armr = armr_inst.get_node("AnimationPlayer")
	
	var pack_inst = load(file_path % ["pack", "pack00"]).instance()
	body_inst.get_node("Armature/Skeleton/Pack").add_child(pack_inst)
	
	var wpn1_inst = load("res://scenes/parts/weapon/melee1.tscn").instance()
	wpn1_inst.rotation_degrees.y = 180
	arml_inst.get_node("Armature/Skeleton/Hand").add_child(wpn1_inst)
	
	var wpn2_inst = load("res://scenes/parts/weapon/mgun0.tscn").instance()
	wpn2_inst.rotation_degrees.y = 180
	armr_inst.get_node("Armature/Skeleton/Hand").add_child(wpn2_inst)

	var pod1_inst = load("res://scenes/parts/pod/pod0.tscn").instance()
	arml_inst.get_node("Armature/Skeleton/Shoulder").add_child(pod1_inst)
	
	var pod2_inst = load("res://scenes/parts/pod/pod1.tscn").instance()
	armr_inst.get_node("Armature/Skeleton/Shoulder").add_child(pod2_inst)
	
	anim_idle()


func anim_idle():
	anim_arml.play("idle")
	anim_armr.play("idle")
	anim_legs.play("idle")


func anim_walk():
	anim_arml.play("walk")
	anim_armr.play("walk")
	anim_legs.play("walk")

