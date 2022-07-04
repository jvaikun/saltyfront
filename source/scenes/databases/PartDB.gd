extends Node

const MECH_LOADOUT = {
	"melee": {"light":{}, "heavy":{}},
	"short": {"light":{}, "heavy":{}},
	"long": {"light":{}, "heavy":{}},
	"mixms": {"light":{}, "heavy":{}},
	"mixml": {"light":{}, "heavy":{}},
	"mixsl": {"light":{}, "heavy":{}}
}

var pilot : Dictionary
var drone: Dictionary
var body : Dictionary
var arm : Dictionary
var legs : Dictionary
var weapon : Dictionary
var pod : Dictionary
var pack : Dictionary

var data_path : String = "../data/"
var part_path : String = "../data/parts/"
var user_path : String = "../data/user/"

func _ready():
	# Load settings from settings.cfg, or defaults if not available
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	if err == OK:
		print("Config file loaded, getting PartDB settings...")
		data_path = config.get_value("paths", "data", "../data/")
		part_path = config.get_value("paths", "parts", "../data/parts/")
		user_path = config.get_value("paths", "user", "../data/user/")
	else:
		print("Error loading config file, using PartDB defaults...")
	# Part data source files
	var data_files = {
		"pilot":user_path + "pilot_data.csv",
		"drone":part_path + "drone.csv",
		"body":part_path + "body.csv",
		"arm":part_path + "arm.csv",
		"legs":part_path + "leg.csv",
		"weapon":part_path + "weapon.csv",
		"pod":part_path + "pod.csv",
		"pack":part_path + "pack.csv",
	}
	# Load mech part data from file
	var file = File.new()
	for part in data_files.keys():
		file.open(data_files[part], File.READ)
		var header = file.get_csv_line()
		while file.get_position() < file.get_len():
			var tempData = file.get_csv_line()
			var row = tempData[0]
			match part:
				"pilot", "drone":
					get(part)[row] = MechPilot.new()
				"body":
					get(part)[row] = MechBody.new()
				"arm":
					get(part)[row] = MechArm.new()
				"legs":
					get(part)[row] = MechLegs.new()
				"weapon":
					get(part)[row] = MechWeapon.new()
				"pod":
					get(part)[row] = MechPod.new()
				"pack":
					get(part)[row] = MechPack.new()
				_:
					get(part)[row] = {}
			for i in tempData.size():
				get(part)[row][header[i]] = tempData[i]
		file.close()


func get_weapon(primary, secondary):
	var weapon_pool = []
	for w_key in weapon.keys():
		if weapon[w_key].skill in [primary, secondary]:
			weapon_pool.append(w_key)
	var weapon_id = weapon_pool[randi() % weapon_pool.size()]
	return weapon[weapon_id]
