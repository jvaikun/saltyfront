extends Node

# Table column headers, used when parsing data files
const ROSTER_SIZE = 8
const TEAM_SIZE = 4
const MECH_HEADER = ["id","pilot_type","name","face","melee","short","long","dodge",
"body","legs","arm_r","wpn_r","pod_r","arm_l","wpn_l","pod_l","pack"]
const TOUR_HEADER = ["id", "start_time", "end_time", "win_team", "new_champ"]
const MATCH_HEADER = ["id","tour_id","match","turns","start_time","end_time","result","map","team1","team2","win_team",
"team1_1","team1_1_kill","team1_1_dead","team1_1_hit","team1_1_crit","team1_1_miss","team1_1_dmg_in","team1_1_dmg_out",
"team1_2","team1_2_kill","team1_2_dead","team1_2_hit","team1_2_crit","team1_2_miss","team1_2_dmg_in","team1_2_dmg_out",
"team1_3","team1_3_kill","team1_3_dead","team1_3_hit","team1_3_crit","team1_3_miss","team1_3_dmg_in","team1_3_dmg_out",
"team1_4","team1_4_kill","team1_4_dead","team1_4_hit","team1_4_crit","team1_4_miss","team1_4_dmg_in","team1_4_dmg_out",
"team2_1","team2_1_kill","team2_1_dead","team2_1_hit","team2_1_crit","team2_1_miss","team2_1_dmg_in","team2_1_dmg_out",
"team2_2","team2_2_kill","team2_2_dead","team2_2_hit","team2_2_crit","team2_2_miss","team2_2_dmg_in","team2_2_dmg_out",
"team2_3","team2_3_kill","team2_3_dead","team2_3_hit","team2_3_crit","team2_3_miss","team2_3_dmg_in","team2_3_dmg_out",
"team2_4","team2_4_kill","team2_4_dead","team2_4_hit","team2_4_crit","team2_4_miss","team2_4_dmg_in","team2_4_dmg_out"]
const TEAM_DEFS = [
	{ "name":"red", "color":Color(1, 0, 0), "material":"res://Parts/team_0.material" },
	{ "name":"blue", "color":Color(0, 0, 1), "material":"res://Parts/team_1.material" },
	{ "name":"green", "color":Color(0, 0.75, 0), "material":"res://Parts/team_2.material" },
	{ "name":"yellow", "color":Color(1, 1, 0), "material":"res://Parts/team_3.material" },
	{ "name":"white", "color":Color(1, 1, 1), "material":"res://Parts/team_5.material" },
	{ "name":"black", "color":Color(0.3, 0.3, 0.3), "material":"res://Parts/team_4.material" },
	{ "name":"purple", "color":Color(0.5, 0, 0.5), "material":"res://Parts/team_6.material" },
	{ "name":"brown", "color":Color(0.65, 0.15, 0.15), "material":"res://Parts/team_7.material" },
	{ "name":"champion", "color":Color(1, 0.75, 0), "material":"res://Parts/team_8.material" },
]
const MATCH_TEMPLATE = [
	{ "name":"Quarterfinal 1", "teams": [0, 1], "next": [4, 0] },
	{ "name":"Quarterfinal 2", "teams": [2, 3], "next": [4, 1] },
	{ "name":"Quarterfinal 3", "teams": [4, 5], "next": [5, 0] },
	{ "name":"Quarterfinal 4", "teams": [6, 7], "next": [5, 1] },
	{ "name":"Semifinal 1", "teams": [-1, -1], "next": [6, 0] },
	{ "name":"Semifinal 2", "teams": [-1, -1], "next": [6, 1] },
	{ "name":"Final", "teams": [-1, -1], "next": [7, 0] },
	{ "name":"Championship", "teams": [-1, 8], "next": [] },
]
const PILOT_CLASS = {
	"melee": {"melee":"high", "short":"low", "long":"low", "dodge":"mid"},
	"short": {"melee":"low", "short":"high", "long":"low", "dodge":"mid"},
	"long": {"melee":"low", "short":"low", "long":"high", "dodge":"mid"},
	"mixms": {"melee":"mid", "short":"mid", "long":"low", "dodge":"mid"},
	"mixml": {"melee":"mid", "short":"low", "long":"mid", "dodge":"mid"},
	"mixsl": {"melee":"low", "short":"mid", "long":"mid", "dodge":"mid"}
}
const MECH_LOADOUT = {
	"melee": {"light":{}, "heavy":{}},
	"short": {"light":{}, "heavy":{}},
	"long": {"light":{}, "heavy":{}},
	"mixms": {"light":{}, "heavy":{}},
	"mixml": {"light":{}, "heavy":{}},
	"mixsl": {"light":{}, "heavy":{}}
}

signal update_bracket(roster, champ)
signal update_stats(team1, team2)
signal next_match
signal next_tournament

var fight_queue = []
var roster : Array
var champ : Dictionary = { "team": 0, "streak": 0, "data": [] }
var tour_count : int = 1
var tour_stats : Dictionary = { 
	"teams":[], "matches":[],
	"start":0, "end":0, "avg_time":0, "avg_turns":0, "kills_per_minute":0,
	"ranking":{
		"hit":[],
		"crit":[],
		"miss":[],
		"dmg_in":[],
		"dmg_out":[],
		"part_lost":[],
		"part_dest":[],
		"bonuses":[]
	}
}
var current_winner : int = -1
var current_loser : int = -1
var match_index : int = 0
var matches : Array = MATCH_TEMPLATE
var tour_done : bool = false
var current_match : Dictionary = {
	"tour":"",
	"name":"",
	"teams":[
		{ "name":"", "index":0, "color":Color(1,1,1), "mechs":[] },
		{ "name":"", "index":0, "color":Color(1,1,1), "mechs":[] },
	],
}
var file = File.new()
var tour_file = ""
var match_file = ""
var mech_file = ""
var stats_file = ""
var champ_file = ""
var tour_id : int = 0
var match_id : int = 0
var mech_id : int = 0
var team_stats : Array = []
var champ_stats : Array = []

class CustomSort:
	static func value_desc(a, b):
		if a["value"] > b["value"]:
			return true
		return false


func _ready() -> void:
	var config = ConfigFile.new()
	var err = config.load("settings.cfg")
	var rec_path = "../data/records/"
	if err == OK:
		print("Config file loaded, getting Tournament settings...")
		rec_path = config.get_value("paths", "recs", "../data/records/")
	else:
		print("Error loading config file, using defaults...")
	# Set up file paths for records
	# If files exist, scan for the highest ID and set the index accordingly
	# If not, create the file and start the index at 0
	var read_buffer = []
	var id_column = 0
	tour_file = "%stbl_tour.csv" % rec_path
	if file.file_exists(tour_file):
		file.open(tour_file, File.READ)
		read_buffer = Array(file.get_csv_line())
		id_column = read_buffer.find("id")
		while !file.eof_reached():
			read_buffer = file.get_csv_line()
			if int(read_buffer[id_column]) > tour_id:
				tour_id = int(read_buffer[id_column])
		tour_id += 1
	else:
		file.open(tour_file, File.WRITE)
		file.store_csv_line(TOUR_HEADER)
		tour_id = 0
	file.close()
	match_file = "%stbl_match.csv" % rec_path
	if file.file_exists(match_file):
		file.open(match_file, File.READ)
		read_buffer = Array(file.get_csv_line())
		id_column = read_buffer.find("id")
		while !file.eof_reached():
			read_buffer = file.get_csv_line()
			if int(read_buffer[id_column]) > match_id:
				match_id = int(read_buffer[id_column])
		match_id += 1
	else:
		file.open(match_file, File.WRITE)
		file.store_csv_line(MATCH_HEADER)
		match_id = 0
	file.close()
	mech_file = "%stbl_mech.csv" % rec_path
	if file.file_exists(mech_file):
		file.open(mech_file, File.READ)
		read_buffer = Array(file.get_csv_line())
		id_column = read_buffer.find("id")
		while !file.eof_reached():
			read_buffer = file.get_csv_line()
			if int(read_buffer[id_column]) > mech_id:
				mech_id = int(read_buffer[id_column])
		mech_id += 1
	else:
		file.open(mech_file, File.WRITE)
		file.store_csv_line(MECH_HEADER)
		mech_id = 0
	file.close()
	# Load team stats from file. If not, initialize stats.
	stats_file = "%steam_stats.json" % rec_path
	team_stats.clear()
	if file.file_exists(stats_file):
		file.open(stats_file, File.READ)
		while file.get_position() < file.get_len():
			var teamData = parse_json(file.get_line())
			team_stats.append(teamData)
		file.close()
	else:
		for team in TEAM_DEFS:
			team_stats.append({"name":team.name, "win":0, "lose":0, "champ":0})
	# Load previous champion data
	champ_file = "%schamp_rec.json" % rec_path
	champ_stats.clear()
	if file.file_exists(champ_file):
		file.open(champ_file, File.READ)
		while file.get_position() < file.get_len():
			var champ_data = parse_json(file.get_line())
			champ_stats.append(champ_data)
		file.close()


# Initialize tournament
func new_tournament() -> void:
	tour_done = false
	new_roster()
	tour_stats.teams.clear()
	for i in ROSTER_SIZE:
		tour_stats.teams.append({"name":TEAM_DEFS[i].name, 
		"hit":0, "crit":0, "miss":0, 
		"dmg_out":0, "dmg_in":0, 
		"part_dest":0, "part_lost":0,
		"bonuses":0 })
	tour_stats.matches.clear()
	for bout in matches:
		tour_stats.matches.append({"name":bout.name, "turns":0, "time":0})
	matches = MATCH_TEMPLATE
	match_index = 0
	var time = OS.get_datetime()
	tour_stats.start = "%d-%02d-%02dT%02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	update_match_info()


# Update match lineup
func match_end(fight_data) -> void:
	# Set current winner/loser
	if current_match.teams[0].index == fight_data.winner:
		current_winner = current_match.teams[0].index
		current_loser = current_match.teams[1].index
	else:
		current_winner = current_match.teams[1].index
		current_loser = current_match.teams[0].index
	if current_loser != ROSTER_SIZE:
		roster[current_loser].active = false
	# Add mech stats to tournament stats
	for team in current_match.teams:
		if team.index < 8:
			for mech in roster[team.index].data:
				tour_stats.teams[team.index].hit += mech.hit
				tour_stats.teams[team.index].crit += mech.crit
				tour_stats.teams[team.index].miss += mech.miss
				tour_stats.teams[team.index].dmg_out += mech.dmg_out
				tour_stats.teams[team.index].dmg_in += mech.dmg_in
				tour_stats.teams[team.index].part_dest += mech.part_dest
				tour_stats.teams[team.index].part_lost += mech.part_lost
				tour_stats.teams[team.index].bonuses += mech.bonuses.size()
	tour_stats.matches[match_index].turns = fight_data.turns
	tour_stats.matches[match_index].time = fight_data.end - fight_data.start
	var turns_total = 0
	var time_total = 0
	var count = 0
	for item in tour_stats.matches:
		if (item.turns > 0 and item.time > 0):
			count += 1
			turns_total += item.turns
			time_total += item.time
	tour_stats.avg_turns = int(turns_total / count)
	tour_stats.avg_time = int(time_total / count)
	record_match(str(fight_data.start), str(fight_data.end), fight_data.result, fight_data.turns, fight_data.map)
	# If it's the final and there is no champ yet:
	#	Copy champ data and info
	#	Generate summary stats
	#	Flag tournament as over
	# If it's the championship:
	#	If there's a new champ:
	#		Archive old champ
	#		Copy new champ data and info
	#		Generate summary stats
	#		Flag tournament as over
	#	If there's not:
	#		Increment champ streak
	#		Generate summary stats
	#		Flag tournament as over
	if (match_index == 6 and champ.data.empty()):
		champ.team = current_winner
		champ.streak = 1
		champ.data = roster[current_winner].data.duplicate()
		tour_done = true
		calc_summary()
	elif (match_index == 7):
		tour_done = true
		calc_summary()
		if current_winner == ROSTER_SIZE:
			champ.streak += 1
		else:
			save_champ()
			champ.team = current_winner
			champ.streak = 1
			champ.data = roster[current_winner].data.duplicate()
	else:
		var link_match = matches[match_index].next[0]
		var link_slot = matches[match_index].next[1]
		matches[link_match].teams[link_slot] = current_winner
	save_stats()


# Calculate summary stats for end of tournament display
func calc_summary():
	for stat in tour_stats.ranking:
		tour_stats.ranking[stat].clear()
	for team in roster:
		for mech in team.data:
			for stat in tour_stats.ranking:
				tour_stats.ranking[stat].append({"label":mech.pilot.name, "value":mech.total_stats[stat]})
	for stat in tour_stats.ranking:
		tour_stats.ranking[stat].sort_custom(CustomSort, "value_desc")


# Update current match info
func update_match_info() -> void:
	current_match.tour = tour_count
	current_match.name = matches[match_index].name
	for i in current_match.teams.size():
		current_match.teams[i].name = TEAM_DEFS[matches[match_index].teams[i]].name
		current_match.teams[i].index = matches[match_index].teams[i]
		current_match.teams[i].color = TEAM_DEFS[matches[match_index].teams[i]].color
		if matches[match_index].teams[i] == ROSTER_SIZE:
			current_match.teams[i].mechs = champ.data
		else:
			current_match.teams[i].mechs = roster[matches[match_index].teams[i]].data


# Proceed to next match
func next_match() -> void:
	if tour_done:
		record_tour()
		tour_count += 1
		emit_signal("next_tournament")
	else:
		match_index += 1
		update_match_info()
		emit_signal("next_match")


# Roll a new mech stat block
func new_mech(type) -> MechStats:
	var this_class = ""
	if type == "rand":
		this_class = PILOT_CLASS[PILOT_CLASS.keys()[randi() % PILOT_CLASS.size()]]
	else:
		this_class = PILOT_CLASS[type]
	var weights = []
	for stat in this_class.keys():
		for i in this_class[stat]:
			weights.append(stat)
	var mech = MechStats.new()
	mech.id = mech_id
	mech_id += 1
	mech.pilot = MechPilot.new()
	mech.pilot.id = 0
	mech.pilot.name = "pilotname"
	mech.pilot.face = randi() % 32
	mech.pilot.melee = 20
	mech.pilot.short = 20
	mech.pilot.long = 20
	mech.pilot.dodge = 20
	for i in 16:
		var pick = weights[randi() % weights.size() - 1]
		mech.pilot[pick] += 5
	mech.pilot.skill0 = 0
	mech.pilot.skill1 = 0
	mech.pilot.skill2 = 0
	mech.pilot.skill3 = 0
	var skill_list = [
		{"skill": "melee", "value": mech.pilot.melee}, 
		{"skill": "short", "value": mech.pilot.short}, 
		{"skill": "long", "value": mech.pilot.long}
	]
	skill_list.sort_custom(CustomSort, "value_desc")
	var rand_ind = str(randi() % PartDB.body.size())
	mech.body = PartDB.body[rand_ind]
	rand_ind = str(randi() % PartDB.arm.size())
	mech.arm_r = PartDB.arm[rand_ind]
	rand_ind = str(randi() % PartDB.arm.size())
	mech.arm_l = PartDB.arm[rand_ind]
	rand_ind = str(randi() % PartDB.legs.size())
	mech.legs = PartDB.legs[rand_ind]
	#rand_ind = str(randi() % PartDB.weapon.size())
	mech.wpn_r = PartDB.get_weapon(skill_list[0].skill, skill_list[1].skill) #PartDB.weapon[rand_ind]
	#rand_ind = str(randi() % PartDB.weapon.size())
	mech.wpn_l = PartDB.get_weapon(skill_list[0].skill, skill_list[1].skill) #PartDB.weapon[rand_ind]
	rand_ind = str(randi() % PartDB.pod.size())
	mech.pod_r = PartDB.pod[rand_ind]
	rand_ind = str(randi() % PartDB.pod.size())
	mech.pod_l = PartDB.pod[rand_ind]
	rand_ind = str(randi() % PartDB.pack.size())
	mech.pack = PartDB.pack[rand_ind]
	return mech


# Roll new roster
func new_roster() -> void:
	roster.clear()
	var pick_list = []
	file.open(mech_file, File.READ_WRITE)
	file.seek_end()
	while pick_list.size() < (ROSTER_SIZE * TEAM_SIZE) && !fight_queue.empty():
		fight_queue.shuffle()
		for slot in fight_queue:
			if randf()*100 <= UserDB.users[slot.user].priority:
				UserDB.users[slot.user].priority = 30
				pick_list.append(slot)
				fight_queue.erase(slot)
				if pick_list.size() == (ROSTER_SIZE * TEAM_SIZE):
					break
	if !fight_queue.empty():
		for slot in fight_queue:
			UserDB.users[slot.user].priority += 30
	if pick_list.size() < (ROSTER_SIZE * TEAM_SIZE):
		var diff = (ROSTER_SIZE * TEAM_SIZE) - fight_queue.size()
		var drone_ids = []
		for i in PartDB.drone.size():
			drone_ids.append(str(i))
		drone_ids.shuffle()
		for i in diff:
			pick_list.append({"user":"npc", "pilot":"rand"})
	for i in ROSTER_SIZE:
		var team_dict = {"active":true, "open":0, "data":[]}
		for j in TEAM_SIZE:
			var pilot_id = pick_list[i + j*ROSTER_SIZE].pilot
			var pilot_type = "npc"
			var mech = new_mech(pilot_id)
			if str(pick_list[i + j*ROSTER_SIZE].user) != "npc":
				mech.pilot.name = UserDB.users[pick_list[i + j*ROSTER_SIZE].user].name
				mech.user_id = pick_list[i + j*ROSTER_SIZE].user
				pilot_type = "user"
			else:
				mech.pilot.name = PartDB.drone[str(i*TEAM_SIZE + j)].name
				mech.pilot.face = PartDB.drone[str(i*TEAM_SIZE + j)].face
				mech.user_id = "npc"
				team_dict.open += 1
			team_dict.data.append(mech)
			# Record mech stats to file
			var data_row = [mech.id, pilot_type,
			mech.pilot.name, mech.pilot.melee, mech.pilot.short, mech.pilot.long, mech.pilot.dodge,
			mech.body.id, mech.legs.id, 
			mech.arm_r.id, mech.wpn_r.id, mech.pod_r.id, 
			mech.arm_l.id, mech.wpn_l.id, mech.pod_l.id, 
			mech.pack.id]
			file.store_csv_line(data_row)
		roster.append(team_dict)
	roster.shuffle()
	for i in roster.size():
		for mech in roster[i].data:
			mech.team = i
	file.close()
	emit_signal("update_bracket", roster, champ)


# Check signup list status
func signup_status() -> String:
	if fight_queue.empty():
		return("roster_empty")
	elif fight_queue.size() <= (ROSTER_SIZE * TEAM_SIZE * 0.25):
		return("roster_low")
	elif fight_queue.size() >= (ROSTER_SIZE * TEAM_SIZE * 0.75):
		return("roster_high")
	return ""


# Update roster for late signups
func update_roster() -> void:
	var slots_open = false
	for team in roster:
		if team.active && team.open > 0:
			slots_open = true
	if !fight_queue.empty():
		while slots_open && !fight_queue.empty():
			fight_queue.shuffle()
			for slot in fight_queue:
				if randf()*100 <= UserDB.users[slot.user].priority:
					UserDB.users[slot.user].priority = 30
					# Swap out a NPC for a user pilot in the queue
					var slot_max = 0
					var dest_team = null
					for team in roster:
						if team.open > slot_max:
							dest_team = team
							slot_max = team.open
					if dest_team != null:
						for mech in dest_team:
							if mech.pilot.user_id == "npc":
								mech.user_id = slot.user
								mech.pilot = PartDB.pilot[slot.pilot]
								fight_queue.erase(slot)
								break
					slots_open = false
					for team in roster:
						if team.active && team.open > 0:
							slots_open = true


# WRITE DATA FUNCTIONS
# Copy current champ data to champ archive before updating
func save_champ() -> void:
	var champ_data = {
		"team":champ.team,
		"streak":champ.streak,
		"mechdata":[],
		}
	for mech in champ.data:
		var temp_data = {
			"name":mech.pilot.name,
			"type":"",
			"face":mech.pilot.face,
			"melee":mech.pilot.melee,
			"short":mech.pilot.short,
			"long":mech.pilot.long,
			"dodge":mech.pilot.dodge,
			"body":mech.body.id,
			"legs":mech.legs.id,
			"arm_r":mech.arm_r.id,
			"wpn_r":mech.wpn_r.id,
			"pod_r":mech.pod_r.id,
			"arm_l":mech.arm_l.id,
			"wpn_l":mech.wpn_l.id,
			"pod_l":mech.pod_l.id,
			"pack":mech.pack.id
		}
		if mech.user_id == "npc":
			temp_data.type = "npc"
		else:
			temp_data.type = "user"
		champ_data.mechdata.append(temp_data)
	UserDB.champ_stats.append(champ_data)


# Save stats
func save_stats() -> void:
	# Write team stats to file
	file.open(stats_file, File.WRITE)
	for team in team_stats:
		file.store_line(to_json(team))
	file.close()
	# Write champ data to file
	file.open(champ_file, File.WRITE)
	for data in champ_stats:
		file.store_line(to_json(data))
	file.close()


# Record match results
func record_match(start: String, end: String, result : String, turns : int, map : String) -> void:
	var match_row = [match_id, tour_id, match_index, turns, start, end, result, map,
	current_match.teams[0].index, current_match.teams[1].index, current_winner]
	for mech in (current_match.teams[0].mechs + current_match.teams[1].mechs):
		match_row.append_array([mech.id, mech.kill, mech.dead, 
		mech.hit, mech.crit, mech.miss, mech.dmg_in, mech.dmg_out])
	emit_signal("update_stats", current_match.teams[0], current_match.teams[1])
	file.open(match_file, File.READ_WRITE)
	file.seek_end()
	file.store_csv_line(match_row)
	file.close()
	match_id += 1


# Record tournament results
func record_tour():
	var new_champ = (current_winner != ROSTER_SIZE)
	var time = OS.get_datetime()
	tour_stats.end = "%d-%02d-%02dT%02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	var tour_row = [tour_id, tour_stats.start, tour_stats.end, current_winner, new_champ]
	file.open(tour_file, File.READ_WRITE)
	file.seek_end()
	file.store_csv_line(tour_row)
	file.close()
	tour_id += 1
