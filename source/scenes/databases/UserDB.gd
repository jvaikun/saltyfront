extends Node

const USER_HEADER = "id,name,money,insurance,priority,equip00,equip01,equip02,equip03,equip04,equip05,equip06,equip07,equip08,equip09"

var file = File.new()
var user_file : String = "user_data.csv"
var user_path : String = "../data/user/"
var users: Dictionary = {}


func _ready():
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	if err == OK:
		print("Config file loaded, getting UserDB settings...")
		user_path = config.get_value("paths", "user", "../data/user/")
	else:
		print("Error loading config file, using UserDB defaults...")
	users.clear()
	if file.file_exists(user_path + user_file):
		file.open(user_path + user_file, File.READ)
		var header = file.get_csv_line()
		while file.get_position() < file.get_len():
			var userData = file.get_csv_line()
			var row = userData[0]
			users[row] = User.new()
			for i in userData.size():
				users[row][header[i]] = userData[i]
		file.close()


# Look up username and return user ID
func get_user_id(username) -> String:
	for user_id in users:
		if users[user_id].name == username:
			return users[user_id].id
	return ""


# Add a new user
func add_user(username) -> bool:
	var new_id = 0
	for user in users:
		if users[user].name == username:
			return false
		elif int(user) > new_id:
			new_id = int(user)
	new_id = str(new_id + 1)
	users[new_id] = {
		"id": new_id,
		"name": username,
		"money": 1000,
		"insurance": 100,
		"priority": 30,
		"equip00": -1,
		"equip01": -1,
		"equip02": -1,
		"equip03": -1,
		"equip04": -1,
		"equip05": -1,
		"equip06": -1,
		"equip07": -1,
		"equip08": -1,
		"equip09": -1,
	}
	save_users()
	return true


func save_users() -> void:
	file.open(user_path + user_file, File.WRITE)
	file.store_line(USER_HEADER)
	for user in users.keys():
		var thisUser = users[user]
		var userRow = (str(thisUser.id) + "," +
		str(thisUser.name) + "," +
		str(thisUser.money) + "," +
		str(thisUser.insurance) + "," +
		str(thisUser.priority) + "," +
		str(thisUser.equip00) + "," +
		str(thisUser.equip01) + "," +
		str(thisUser.equip02) + "," +
		str(thisUser.equip03) + "," +
		str(thisUser.equip04) + "," +
		str(thisUser.equip05) + "," +
		str(thisUser.equip06) + "," +
		str(thisUser.equip07) + "," +
		str(thisUser.equip08) + "," +
		str(thisUser.equip09)
		)
		file.store_line(userRow)
	file.close()

