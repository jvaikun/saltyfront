extends Spatial

onready var anim_arm_l = $mech_legs/Armature/Skeleton/Body/mech_body/Armature/Skeleton/ArmL/mech_arm_l/AnimationPlayer
onready var anim_arm_r = $mech_legs/Armature/Skeleton/Body/mech_body/Armature/Skeleton/ArmR/mech_arm_r/AnimationPlayer
onready var anim_legs = $mech_legs/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	anim_idle()
	pass # Replace with function body.


func anim_idle():
	anim_arm_l.play("idle")
	anim_arm_r.play("idle")
	anim_legs.play("idle")


func anim_walk():
	anim_arm_l.play("walk")
	anim_arm_r.play("walk")
	anim_legs.play("walk")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
