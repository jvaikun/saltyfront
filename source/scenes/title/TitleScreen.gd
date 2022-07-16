extends Control

const validation = {
	"data": ["announcer.json", "bet_ai.json", "bootup.json", "intro_text.json", "pilot_talk.json", "streams.json"],
	"user": ["user_data.csv"],
	"records": ["champ_rec.json", "command_log.csv", "error_log.csv", "tbl_match.csv", "tbl_mech.csv", "tbl_tour.csv", "team_stats.json"],
	"parts": ["arm.csv", "body.csv", "drone.csv", "leg.csv", "pack.csv", "pod.csv", "weapon.csv"]
}

func _ready():
	# Check for config file and display settings
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	if err == OK:
		print("Config file found, displaying settings...")
		var dir = Directory.new()
		var file_list = []
		# Check BGM directory and file count
		err = dir.open(config.get_value("paths", "bgm", "../bgm/"))
		if err:
			$VBoxContainer2/Music/Body/List.text = "Invalid directory!"
		else:
			$VBoxContainer2/Music/Body/List.text = "File count: "
			file_list = get_file_list(dir)
			$VBoxContainer2/Music/Body/List.text += str(file_list.size())
		# Check text data directory and verify files
		err = dir.open(config.get_value("paths", "data", "../data/"))
		if err:
			$VBoxContainer2/Text/Body/List.text = "Invalid directory!"
		else:
			$VBoxContainer2/Text/Body/List.text = ""
			file_list = get_file_list(dir)
			for item in validation.data:
				if item in file_list:
					$VBoxContainer2/Text/Body/List.text += "%s: Valid\n" % item
				else:
					$VBoxContainer2/Text/Body/List.text += "%s: Invalid\n" % item
		# Check parts data directory and verify files
		err = dir.open(config.get_value("paths", "parts", "../data/parts/"))
		if err:
			$VBoxContainer/Parts/Body/List.text = "Invalid directory!"
		else:
			$VBoxContainer/Parts/Body/List.text = ""
			file_list = get_file_list(dir)
			for item in validation.parts:
				if item in file_list:
					$VBoxContainer/Parts/Body/List.text += "%s: Valid\n" % item
				else:
					$VBoxContainer/Parts/Body/List.text += "%s: Invalid\n" % item
		err = dir.open(config.get_value("paths", "recs", "../data/records/"))
		if err:
			$VBoxContainer/Records/Body/List.text = "Invalid directory!"
		else:
			$VBoxContainer/Records/Body/List.text = ""
			file_list = get_file_list(dir)
			for item in validation.records:
				if item in file_list:
					$VBoxContainer/Records/Body/List.text += "%s: Valid\n" % item
				else:
					$VBoxContainer/Records/Body/List.text += "%s: Invalid\n" % item
		err = dir.open(config.get_value("paths", "user", "../data/user/"))
		if err:
			$VBoxContainer/Users/Body/List.text = "Invalid directory!"
		else:
			$VBoxContainer/Users/Body/List.text = ""
			file_list = get_file_list(dir)
			for item in validation.user:
				if item in file_list:
					$VBoxContainer/Users/Body/List.text += "%s: Valid\n" % item
				else:
					$VBoxContainer/Users/Body/List.text += "%s: Invalid\n" % item
		err = dir.open(config.get_value("paths", "screenshot", "../screenshot/"))
		if err:
			$VBoxContainer2/Misc/Body/List.text = "Screenshot dir: Invalid!"
		else:
			$VBoxContainer2/Misc/Body/List.text = "Screenshot dir: Valid"
	else:
		print("Config file not found!")
	$MainCont/Settings/Offline.pressed = GameData.offline_mode
	$MainCont/Settings/FastWait.pressed = GameData.fast_wait
	$MainCont/Settings/FastCombat.pressed = GameData.fast_combat
	for channel in GameData.streams:
		$MainCont/Settings/Channel.add_item(channel)
	$MainCont/Settings/Channel.selected = 0
	if !OS.is_window_maximized():
		OS.set_window_maximized(true)


func get_file_list(dir):
	var file_list = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			file_list.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return file_list


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

