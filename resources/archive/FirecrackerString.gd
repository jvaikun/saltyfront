extends Spatial


func burn():
	for cracker in $Crackers.get_children():
		cracker.body.visible = true
	$AnimationPlayer.play("fuse_burn")


func _on_Area_area_entered(area):
	area.get_parent().explode()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fuse_burn":
		pass

