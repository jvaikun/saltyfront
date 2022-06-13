extends MarginContainer

onready var message = $Panels/Intro/Body/Message
onready var counter = $Panels/Intro/Body/Counter
onready var user_list = $Panels/Intro/Body/UserList

func add_user(label):
	user_list.add_child(label)

func clear_users():
	var children = user_list.get_children()
	for child in children:
		child.free()
