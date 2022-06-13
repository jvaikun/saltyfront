extends PanelContainer

# Accessor variables
onready var msg_timer = $Timer
onready var msg_tween = $Tween
onready var msg_body = $Message

signal dialog_done


func set_msg(body):
	msg_body.text = body
	rect_size = rect_min_size


func slide(from, to, time):
	msg_tween.interpolate_property(self, "rect_position", from, to, 0.25)
	msg_tween.start()
	msg_timer.start(time)


func popup(time):
	msg_tween.interpolate_property(self, "rect_scale", Vector2(1, 0.1), Vector2.ONE, 0.25)
	msg_tween.start()
	msg_timer.start(time)


func _on_Timer_timeout():
	emit_signal("dialog_done")
	queue_free()
