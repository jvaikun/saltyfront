extends Spatial

const anim_top = ["weld_torso0", "weld_torso1", "weld_torso2"]
const anim_side = ["weld_leg_low", "weld_leg_up", "weld_arm_low", "weld_arm_up"]

var top = false
var active = true
var anim_in = true

func _ready():
	active = true
	anim_in = true
	$Timer.start(randf())


func reset_arm():
	active = false
	$Timer.stop()
	$Tween.stop_all()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("0default")
	$Tween.interpolate_property($Armature, "translation", $Armature.translation, Vector3.ZERO, 0.25)
	$Tween.start()


func _on_Timer_timeout():
	var anim = "0default"
	if top:
		anim = anim_top[randi() % anim_top.size()]
		$Tween.interpolate_property($Armature, "translation", 
		$Armature.translation, Vector3(((randi() % 3) - 1) * 0.5, 0, 0), 0.5)
		$Tween.start()
	else:
		anim = anim_side[randi() % anim_side.size()]
		if anim in ["weld_arm_low", "weld_arm_up"]:
			if $Armature.translation.z == 0:
				$Tween.interpolate_property($Armature, "translation", Vector3.ZERO, Vector3(0, 0, -1), 0.5)
				$Tween.start()
		elif $Armature.translation.z != 0:
			$Tween.interpolate_property($Armature, "translation", Vector3(0, 0, -1), Vector3.ZERO, 0.5)
			$Tween.start()
	$AnimationPlayer.play(anim)


func _on_AnimationPlayer_animation_finished(anim_name):
	if active:
		if anim_in:
			anim_in = false
			$Armature/Skeleton/Wrist/Sparks.emitting = true
			yield(get_tree().create_timer(0.2), "timeout")
			$AnimationPlayer.play_backwards(anim_name)
		else:
			anim_in = true
			$Timer.start(randf())

