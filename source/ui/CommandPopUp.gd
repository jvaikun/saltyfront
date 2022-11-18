extends PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("anim_popup")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "anim_popup":
		yield(get_tree().create_timer(1.0), "timeout")
		queue_free()
