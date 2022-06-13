extends PanelContainer

onready var top = $Content/TopRow
onready var bottom = $Content/BottomRow
onready var msg1 = $Content/MidRow/Message1
onready var msg2 = $Content/MidRow/Message2

var intro_text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var data_path : String = "../data/"
	var file = File.new()
	file.open(data_path + "intro_text.json", File.READ)
	var json = file.get_as_text()
	intro_text = JSON.parse(json).result
	file.close()
	visible = false


func start() -> void:
	var intro_num = randi() % intro_text.intro.size()
	var intro_set = intro_text.intro[intro_num]
	top.text = intro_set[0]
	msg1.text = intro_text.ready[randi() % intro_text.ready.size()]
	msg2.text = intro_text.start[randi() % intro_text.start.size()]
	bottom.text = intro_set[1]
	visible = true
	$AnimationPlayer.play("intro")


func outro(msg_top, msg_mid, msg_bot) -> void:
	visible = true
	top.text = msg_top
	msg1.text = msg_mid
	msg2.text = msg_mid
	bottom.text = msg_bot
	$AnimationPlayer.play_backwards("intro")


func _on_AnimationPlayer_animation_finished(anim_name) -> void:
	if anim_name == "intro":
		visible = false
