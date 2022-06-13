extends PanelContainer

export (String) var title

onready var header = $Body/Header
onready var task_list = [$Body/Task1, $Body/Task2, $Body/Task3, $Body/Task4]

var task_text = ["", "", "", ""]


# Called when the node enters the scene tree for the first time.
func _ready():
	header.text = title.to_upper()


func clear_list():
	for i in task_list.size():
		task_list[i].text = ""


func popup():
	for i in task_list.size():
		task_list[i].text = task_text[i]
		yield(get_tree().create_timer(randf()), "timeout")

