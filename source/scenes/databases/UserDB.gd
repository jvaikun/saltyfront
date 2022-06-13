extends Node

const USER_HEADER = "id,name,money,insurance,priority,pilot0,pilot1,pilot2,pilot3,equip00,equip01,equip02,equip03,equip04,equip05,equip06,equip07,equip08,equip09"
const PILOT_HEADER = "id,name,face,melee,short,long,dodge,skill0,skill1,skill2,skill3"

var file = File.new()
var user_file : String = "user_data.csv"
var user_path : String = "../data/user/"
var rec_path : String = "../data/records/"
var users: Dictionary = {}
var team_stats : Array = []
var champ_stats : Array = []

func _ready():
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	if err == OK:
		print("Config file loaded, getting UserDB settings...")
		user_path = config.get_value("paths", "user", "../data/user/")
		rec_path = config.get_value("paths", "recs", "../data/records/")
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
	# Load team stats from file. If not, initialize stats.
	team_stats.clear()
	if file.file_exists(rec_path + "team_stats.json"):
		file.open(rec_path + "team_stats.json", File.READ)
		while file.get_position() < file.get_len():
			var teamData = parse_json(file.get_line())
			team_stats.append(teamData)
		file.close()
	else:
		for team_name in ["red", "blue", "green", "yellow", "white", "black", "purple", "brown", "champion"]:
			team_stats.append({"name":team_name, "win":0, "lose":0, "champ":0})
	# Load previous champion data
	if file.file_exists(rec_path + "champ_rec.json"):
		file.open(rec_path + "champ_rec.json", File.READ)
		while file.get_position() < file.get_len():
			var champ_data = parse_json(file.get_line())
			champ_stats.append(champ_data)
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
		"pilot0": -1,
		"pilot1": -1,
		"pilot2": -1,
		"pilot3": -1,
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
	# Roll new pilot
	var pilot_id = 0
	for pilot in PartDB.pilot:
		if int(pilot) > pilot_id:
			pilot_id = int(pilot)
	pilot_id = str(pilot_id + 1)
	var spread = []
	var total = 0
	for i in 4:
		var temp = randf()
		total += temp
		spread.append(temp)
	PartDB.pilot[pilot_id] = MechPilot.new()
	PartDB.pilot[pilot_id].id = pilot_id
	PartDB.pilot[pilot_id].name = username
	PartDB.pilot[pilot_id].face = randi() % 32
	PartDB.pilot[pilot_id].melee = 20 + int((spread[0]/total) * 60)
	PartDB.pilot[pilot_id].short = 20 + int((spread[1]/total) * 60)
	PartDB.pilot[pilot_id].long = 20 + int((spread[2]/total) * 60)
	PartDB.pilot[pilot_id].dodge = 20 + int((spread[3]/total) * 60)
	PartDB.pilot[pilot_id].skill0 = 0
	PartDB.pilot[pilot_id].skill1 = 0
	PartDB.pilot[pilot_id].skill2 = 0
	PartDB.pilot[pilot_id].skill3 = 0
	users[new_id].pilot0 = pilot_id
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
		str(thisUser.pilot0) + "," +
		str(thisUser.pilot1) + "," +
		str(thisUser.pilot2) + "," +
		str(thisUser.pilot3) + "," +
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
	# Write pilot data to file
	file.open(user_path + "pilot_data.csv", File.WRITE)
	file.store_line(PILOT_HEADER)
	for pilot_id in PartDB.pilot.keys():
		var thisPilot = PartDB.pilot[pilot_id]
		var pilotRow = (str(thisPilot.id) + "," +
		str(thisPilot.name) + "," +
		str(thisPilot.face) + "," +
		str(thisPilot.melee) + "," +
		str(thisPilot.short) + "," +
		str(thisPilot.long) + "," +
		str(thisPilot.dodge) + "," +
		str(thisPilot.skill0) + "," +
		str(thisPilot.skill1) + "," +
		str(thisPilot.skill2) + "," +
		str(thisPilot.skill3)
		)
		file.store_line(pilotRow)
	file.close()


func save_stats() -> void:
	# Write team stats to file
	file.open(rec_path + "team_stats.json", File.WRITE)
	for team in team_stats:
		file.store_line(to_json(team))
	file.close()
	# TODO: Write champ data (current + archive) to file
	file.open(rec_path + "champ_rec.json", File.WRITE)
	for champ in champ_stats:
		file.store_line(to_json(champ))
	file.close()


func save_data() -> void:
	save_users()
	save_stats()

