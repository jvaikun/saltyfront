extends Spatial


func flip():
	$Particles.emitting = false
	$Tween.interpolate_property($prosperity, "rotation_degrees:x", -45, -225, 2, 
	Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()


func _on_Tween_tween_all_completed():
	$Particles.emitting = true

