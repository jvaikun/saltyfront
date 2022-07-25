extends Node

# Team constants
const teamNames = ["red", "blue", "green", "yellow", "white", "black", "purple", "brown", "champion"]
const matchNames = ["Quarterfinal 1", "Quarterfinal 2", "Quarterfinal 3", "Quarterfinal 4", 
"Semifinal 1", "Semifinal 2", "Final", "Championship"]
const teamColors = [Color(1, 0, 0, 1), Color(0, 0, 1, 1), Color(0, 0.75, 0, 1), Color(1, 1, 0, 1), 
Color(1, 1, 1, 1), Color(0.3, 0.3, 0.3, 1), Color(0.5, 0, 0.5, 1), Color(0.65, 0.15, 0.15, 1),
Color(1, 0.75, 0, 1)]
const mech_colors = [Color(1, 0, 0, 1), Color(0, 0, 1, 1), Color(0, 0.75, 0, 1), Color(1, 1, 0, 1), 
Color(0.9, 0.9, 0.9, 1), Color(0.2, 0.2, 0.2, 1), Color(0.5, 0, 0.5, 1), Color(0.65, 0.15, 0.15, 1),
Color(1, 0.5, 0, 1)]

# File system variables
var file = File.new()
var rec_path = "../data/records/"
var screenshot_path = "../screenshot"
var screenshot_count = 0
var streams : Dictionary

# Game variables
var debug_mode = false
var offline_mode = true
var fast_wait = true
var fast_combat = false

# Twitch credentials for chatbot
var NICK : String
var CLIENT_ID : String
var CHANNEL : String
var OAUTH : String


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	# Load settings from settings.cfg, or defaults if not available
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	if err == OK:
		print("Config file loaded, getting settings...")
		rec_path = config.get_value("paths", "recs", "../data/records/")
		offline_mode = config.get_value("flags", "offline_mode", false)
		fast_combat = config.get_value("flags", "fast_combat", false)
		fast_wait = config.get_value("flags", "fast_wait", false)
	else:
		print("Error loading config file, using defaults...")
	# Load announcer commentary
	var json = ""
	file.open("../data/streams.json", File.READ)
	json = file.get_as_text()
	streams = JSON.parse(json).result
	file.close()


func set_channel(chan_name):
	NICK = streams[chan_name].nick
	CLIENT_ID = streams[chan_name].client
	CHANNEL = streams[chan_name].channel
	OAUTH = streams[chan_name].oauth


func write_log(row : String, type : String):
	var time = OS.get_datetime()
	var timestamp = "%d-%02d-%02dT%02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	var file_name = "%s%s_log.csv" % [rec_path, type]
	if file.file_exists(file_name):
		file.open(file_name, File.READ_WRITE)
	else:
		file.open(file_name, File.WRITE)
	file.seek_end()
	file.store_string("%s,%s\n" % [row, timestamp])
	file.close()


func log_transaction(user, value, type):
	write_log("%s,%d,%s" % [user, value, type], "transaction")


func screenshot():
	var time = OS.get_datetime()
	var timestamp = "%s%s%sT%s%s%s" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	image.save_png("%s/shot%s.png" % [screenshot_path, timestamp])

