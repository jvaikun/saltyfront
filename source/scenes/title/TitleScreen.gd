extends Control

func _ready():
	var err = $Timer.connect("timeout", self, "_on_MainGame_pressed")
	if err != OK:
		print("Error connecting auto start timer to script!")
	$Timer.one_shot = true
	$Timer.start(120)
	$MainCont/Settings/Offline.pressed = GameData.offline_mode
	$MainCont/Settings/FastWait.pressed = GameData.fast_wait
	$MainCont/Settings/FastCombat.pressed = GameData.fast_combat
	for channel in GameData.streams:
		$MainCont/Settings/Channel.add_item(channel)
	$MainCont/Settings/Channel.selected = 0
	if !OS.is_window_maximized():
		OS.set_window_maximized(true)


func _process(_delta):
	$MainCont/Title/Countdown.text = "Auto start in " + str(int($Timer.time_left)) + " seconds"


func _on_MainGame_pressed():
	GameData.set_channel($MainCont/Settings/Channel.get_item_text($MainCont/Settings/Channel.selected))
	var err = get_tree().change_scene("res://Game/Game.tscn")
	if err != OK:
		print("Error loading main game!")


func _on_TestRoom_pressed():
	var err = get_tree().change_scene("res://Test/TestRoom.tscn")
	if err != OK:
		print("Error loading test room!")


func _on_Exit_pressed():
	get_tree().quit()


func _on_Offline_toggled(button_pressed):
	GameData.offline_mode = button_pressed
	$MainCont/Settings/Channel.disabled = button_pressed


func _on_FastWait_toggled(button_pressed):
	GameData.fast_wait = button_pressed


func _on_FastCombat_toggled(button_pressed):
	GameData.fast_combat = button_pressed

