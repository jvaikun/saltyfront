extends Control

onready var systems = {
	"video":$Column1/Video,
	"comms":$Column1/Comms,
	"ecommerce":$Column1/ECommerce,
	"legal":$Column2/Legal,
	"security":$Column2/Security,
	"safety":$Column2/Safety
	}

signal boot_done

var boot_text


func _ready():
	var file = File.new()
	var data_path : String = "../data/"
	file.open(data_path + "bootup.json", File.READ)
	var json = file.get_as_text()
	boot_text = JSON.parse(json).result
	file.close()


func start(tour_num):
	visible = true
	var time = OS.get_datetime()
	var timestamp = "%d-%02d-%02dT%02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	var scroll_text = (boot_text.intro % [timestamp, tour_num]) + boot_text.credits
	$ColumnCenter/BootText.text = scroll_text
	$ColumnCenter/BootText.percent_visible = 0
	$ColumnCenter/IntroText.percent_visible = 0
	var sys_list = systems.keys()
	for system in sys_list:
		systems[system].clear_list()
		boot_text[system].shuffle()
		for i in systems[system].task_list.size():
			systems[system].task_text[i] = boot_text[system][i]
	sys_list.shuffle()
	for system in sys_list:
		systems[system].popup()
		yield(get_tree().create_timer(0.25), "timeout")
	$AnimationPlayer.play("boot_scroll")


func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"boot_scroll":
			yield(get_tree().create_timer(1), "timeout")
			$AnimationPlayer.play("intro_scroll")
		"intro_scroll":
			$AnimationPlayer.play("intro_glow")
		"intro_glow":
			yield(get_tree().create_timer(1), "timeout")
			visible = false
			emit_signal("boot_done")

