extends Spatial

func unroll():
	$Tween.interpolate_property($Lower, "translation:y", -0.5, -5, 2.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.interpolate_property($tiger_scroll.material_override, "shader_param/progress", 0.12, 1, 2.0,
	Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
