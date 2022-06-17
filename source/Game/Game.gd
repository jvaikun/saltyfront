extends Spatial

# Game constants and enums
enum GameState {START, PREFIGHT, FIGHT, POSTFIGHT, TOUR_END, RESET, TRANSITION}

# Preload resources
const obj_label = preload("res://ui/obj_label.tscn")
const tex_bg1 = preload("res://Game/bg_shop.png")
const tex_bg2 = preload("res://Game/bg_arena.png")
const tex_bg3 = preload("res://Game/bg_town.png")
const shader_melt = preload("res://Effects/transition/doom_melt.shader")
const shader_dissolve = preload("res://Effects/transition/dissolve.shader")
const shader_mask = preload("res://Effects/transition/mask_dissolve.shader")
const stat_cycle = [["Hits", "hit"], ["Crits", "crit"], ["Misses", "miss"],
["Damage Dealt", "dmg_out"], ["Damage Taken", "dmg_in"],
["Parts Destroyed", "part_dest"], ["Parts Lost", "part_lost"]]

# Formatted strings for UI messages
const msg_signup = "Tournament #%d starting soon!"
const msg_signup_counter = "Signup Time Left: %d"
const msg_match_next = "NEXT MATCH\nTournament %d\n%s"
const msg_match_result = "MATCH RESULTS\nTournament %d\n%s"
const msg_next_counter = "- %d -"
const msg_bets = "Bet in chat with '!bet (amount) (team)'\n"
const msg_map_info = "%s\n%s"

# Accessor vars for game objects
onready var tournament = $Tournament
onready var arena = $Arena
onready var chatbot = $ChatBot
onready var bgm_player = $BGMPlayer

# Accessor vars for signup UI
onready var ui_signup = $UI/SignupUI

# Accessor vars for pre-fight UI
onready var header_versus = $UI/VersusHeader
onready var ui_bracket = $UI/TourBracket
onready var scrn_buffer = $UI/ScreenBuffer
onready var prefight = $UI/PreFight
onready var mech_info = $UI/PreFight/MechInfo
onready var bet_info = $UI/PreFight/Body/BetInfo

# Accessor vars for post-fight UI
onready var payout = $UI/Stats/MainBox/SideBox/Payout
onready var stats = $UI/Stats

onready var comment1 = $Announcer
onready var comment2 = $Announcer2

# Flags for offline test mode
var autoBet = false

# Game variables
var state = null
var next_state = null
var prep_timer = GameData.prep_time
var bet_timer = GameData.bet_time
var pay_timer = GameData.pay_time
var focus_timer = GameData.focus_time
var bracket_timer = 5
var bet_warned = false
var ping_timer = 0
var got_pong = false
var missed_pongs = 0
var did_comment = false
var comment_text : Dictionary
var regex_valid = RegEx.new()
var cycle_next : bool = false

# Bet and match tracking variables
var bet_ai : Dictionary = {}
var bets : Array = []
var books : Array = [
	{"team":0, "count":0, "total":0, "percent":0, "odds":0},
	{"team":0, "count":0, "total":0, "percent":0, "odds":0}
]
var active_users : Array = []
var next_queue : Array = []


# Main functions
func _ready():
	randomize()
	regex_valid.compile("\\D|^0")
	# Connect signals, load assets
	tournament.connect("update_bracket", ui_bracket, "set_teams")
	tournament.connect("update_stats", stats, "update_info")
	tournament.connect("next_match", self, "start_transition", [GameState.PREFIGHT])
	tournament.connect("next_tournament", self, "start_transition", [GameState.TOUR_END])
	$Hangar.connect("mechs_out", self, "start_transition", [GameState.FIGHT])
	arena.connect("match_end", self, "end_match")
	chatbot.connect("twitch_disconnected", self, "connect_chat")
	chatbot.connect("unhandled_message", self, "twitch_message")
	chatbot.connect("chat_message", self, "chat_msg")
	if GameData.fast_wait:
		prep_timer = GameData.prep_time_fast
		bet_timer = GameData.bet_time_fast
		pay_timer = GameData.pay_time_fast
	else:
		prep_timer = GameData.prep_time
		bet_timer = GameData.bet_time
		pay_timer = GameData.pay_time
	# Load announcer commentary
	var data_path : String = "../data/"
	var file = File.new()
	var json = ""
	file.open(data_path + "announcer.json", File.READ)
	json = file.get_as_text()
	comment_text = JSON.parse(json).result
	file.close()
	file.open(data_path + "bet_ai.json", File.READ)
	json = file.get_as_text()
	bet_ai = JSON.parse(json).result
	file.close()
	# Connect to chat
	if !GameData.offline_mode:
		startup()
	$Transition.visible = true
	start_transition(GameState.START)


func _process(delta):
	# Check for user input
	if Input.is_action_just_pressed("ui_screenshot"):
		GameData.screenshot()
	if Input.is_action_just_pressed("ui_page_down"):
		$BGMPlayer.visible = !$BGMPlayer.visible
		$Arena/MapUI.visible = !$Arena/MapUI.visible
	# If online, periodic ping every 150s (2.5m) to keep connection alive
	if !GameData.offline_mode:
		ping_timer += delta
		if ping_timer >= 150:
			ping_timer = 0
			chatbot.send("PING\r\n")
			if got_pong:
				got_pong = false
			else:
				missed_pongs += 1
				print_debug(str(missed_pongs) + " missed pongs")
	# Run state machine
	match state:
		GameState.START:
			if $Timer.time_left > 0:
				ui_signup.counter.text = msg_signup_counter % [int($Timer.time_left)]
				if ($Timer.time_left <= prep_timer / 2) && !did_comment:
					var status = tournament.signup_status()
					if status != "":
						did_comment = true
						commentary(status)
		GameState.PREFIGHT:
			if !autoBet:
				auto_bet()
				autoBet = true
			if $Timer.time_left > 0:
				if !ui_bracket.visible:
					header_versus.counter.text = msg_next_counter % [int($Timer.time_left)]
					if $Timer.time_left <= 10 and !bet_warned and !GameData.offline_mode:
						chatbot.chat("Betting closes in 10 seconds!")
						bet_warned = true
					if int($Timer.time_left) % focus_timer == 0:
						if !cycle_next:
							cycle_next = true
							var mech_list = []
							for team in tournament.current_match.teams:
								mech_list += team.mechs
							var mech_ind = fmod((bet_timer - $Timer.time_left)/focus_timer, 8)
							mech_info.focus_mech = mech_list[int(mech_ind)]
							mech_info.update_info()
							$Hangar.move_cam(mech_ind)
						elif cycle_next:
							cycle_next = false
		GameState.FIGHT:
			pass
		GameState.POSTFIGHT:
			if $Timer.time_left > 0:
				if !ui_bracket.visible:
					header_versus.counter.text = msg_next_counter % [int($Timer.time_left)]
		GameState.TOUR_END:
			if int($Timer.time_left) % focus_timer == 0:
				if !cycle_next:
					cycle_next = true
					var stat_ind = fmod((prep_timer - $Timer.time_left)/focus_timer, 7)
					$UI/TourStats.update_head(tournament.tour_stats)
					$UI/TourStats.update_stats(stat_cycle[stat_ind], tournament.tour_stats)
			elif cycle_next:
				cycle_next = false
		GameState.TRANSITION:
			pass


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		UserDB.save_data()
		get_tree().quit() # default behavior


# Support functions
# Commentary from announcers
func commentary(type):
	var msg_index = 0
	if comment_text[type].comments.size() > 1:
		msg_index = randi() % comment_text[type].comments.size()
	$Announcer.play_msg(comment_text[type].comments[msg_index], 0.5)
	yield(get_tree().create_timer(1), "timeout")
	msg_index = 0
	if comment_text[type].replies.size() > 1:
		msg_index = randi() % comment_text[type].replies.size()
	$Announcer2.play_msg(comment_text[type].replies[msg_index], 0.5)
	yield(get_tree().create_timer(5), "timeout")
	$Announcer.hide()
	$Announcer2.hide()


# Sign up user to fight queue, with the selected pilot
func signup(user_id, pilot_id):
	if state == GameState.START:
		tournament.fight_queue.append({"user":user_id, "pilot":pilot_id})
		var label = obj_label.instance()
		label.text = (UserDB.users[user_id].name + " (" + PartDB.pilot[pilot_id].name + ")")
		ui_signup.add_user(label)
		return true
#	elif tournament.slots_open():
#		for team in tournament.roster:
#			for mech in team.data:
#				if mech.mechData.user_id == user_id:
#					return false
#		tournament.fight_queue.append({"user":user_id, "pilot":pilot_id})
#		return true
	else:
		return false


# End of match housekeeping
func end_match(fight_data):
	active_users.clear()
	tournament.match_end(fight_data)
	$Hangar.update_hp(fight_data.hp_data)
	var message = (tournament.current_match.name + " over, " +
	GameData.teamNames[tournament.current_winner].capitalize() + " wins!")
	if GameData.offline_mode:
		print(message)
	else:
		chatbot.chat(message)
	if header_versus.team1.team_index != fight_data.winner:
		header_versus.team1.set_loss(true)
	if header_versus.team2.team_index != fight_data.winner:
		header_versus.team2.set_loss(true)
	ui_bracket.eliminate(tournament.current_loser)
	# Pay out bets and update stats
	for i in UserDB.team_stats.size():
		if i == tournament.current_winner:
			if tournament.match_index == tournament.ROSTER_SIZE:
				UserDB.team_stats[i].champ += 1
			else:
				UserDB.team_stats[i].win += 1
		if i == tournament.current_loser:
			UserDB.team_stats[i].lose += 1
	var win_side = 0
	if tournament.current_winner != tournament.current_match.teams[0].index:
		win_side = 1
	for bet in self.bets:
		if bet.team == tournament.current_winner:
			if bet.type == "user":
				for user in UserDB.users.keys():
					var thisUser = UserDB.users[user]
					if thisUser.name == bet.name:
						thisUser.money += round(bet.money * books[win_side].odds)
						thisUser.money = max(thisUser.money, thisUser.insurance)
						GameData.log_transaction(user, thisUser.money, "pay_out")
			if bet.type == "corp":
				for corp in bet_ai.corps:
					if corp == bet.name:
						bet_ai.corps[corp].funds += round(bet.money * books[win_side].odds)
	# Go through teams and pay out bonuses
	for mech in (tournament.current_match.teams[0].mechs + tournament.current_match.teams[1].mechs):
		for bonus in mech.bonuses:
			if mech.user_id != "drone":
				UserDB.users[mech.user_id].money += bonus.pay
				var title_str = bonus.title.to_lower().replace(" ", "_")
				GameData.log_transaction(mech.user_id, UserDB.users[mech.user_id].money, title_str)
				var debug_msg = "%s: %s, +%d" % [UserDB.users[mech.user_id].name, bonus.title, bonus.pay]
				print(debug_msg)
	UserDB.save_users()
	for child in payout.item_list.get_children():
		child.free()
	ui_update()
	start_transition(GameState.POSTFIGHT)


func calc_odds():
	var pool = 0
	for i in books.size():
		books[i].team = tournament.current_match.teams[i].index
		books[i].count = 0
		books[i].total = 0
		books[i].percent = 0
		books[i].odds = 0
		for bet in bets:
			if bet.team == books[i].team:
				books[i].count += 1
				books[i].total += bet.money
				pool += bet.money
	for team in books:
		if team.total > 0 && pool > 0:
			team.percent = float(team.total) / pool
			team.odds = float(pool) / team.total
		else:
			team.percent = 0.0
			team.odds = 0.0


# Automated betting
# Place bets according to parameters loaded from bet_ai.json
func auto_bet():
	var coin_flip = 0
	var money = 0
	# Drone pilot bets
	for team in tournament.roster:
		for mech in team.data:
			if mech.user_id == "drone":
				coin_flip = int(randf() / 0.5)
				money = (randi() % 5 + 1) * 100
				add_bet("drone", mech.pilot.name, money, tournament.current_match.teams[coin_flip].index)
	# Corporate sponsor bets
	for corp in bet_ai.corps:
		var this_corp = bet_ai.corps[corp]
		if randf() < 0.25 and this_corp.funds > 0:
			coin_flip = int(randf() / 0.5)
			money = stepify(rand_range(this_corp.bets[0], this_corp.bets[1]), this_corp.bets[2])
			if money > this_corp.funds:
				money = this_corp.funds
			this_corp.funds -= money
			add_bet("corp", corp, money, tournament.current_match.teams[coin_flip].index)


# Add a bet
func add_bet(type, name, money, team):
	# Validate user name and add bet to list if OK
	var newBet = {"type":type, "name": name, "money": money, "team": team}
	for user in UserDB.users.keys():
		var thisUser = UserDB.users[user]
		if thisUser.name == name:
			thisUser.money -= newBet.money
			thisUser.money = clamp(thisUser.money, thisUser.insurance, 1000000)
			GameData.log_transaction(user, thisUser.money, "place_bet")
	bets.append(newBet)
	calc_odds()
	ui_update()


# Cancel a bet
func cancel_bet(user_id):
	var thisUser = UserDB.users[user_id]
	for i in bets.size():
		if bets[i].name == thisUser.name:
			thisUser.money += ceil(0.9 * bets[i].money)
			GameData.log_transaction(user_id, thisUser.money, "cancel_bet")
			bets.remove(i)
			break
	ui_update()


# Update info
func ui_update():
	match state:
		GameState.PREFIGHT:
			var current_teams = []
			for team in tournament.current_match.teams:
				current_teams.append(team.index)
			bet_info.update_info(books, bets)
		GameState.POSTFIGHT:
			var win_side = 0
			if tournament.current_winner != tournament.current_match.teams[0].index:
				win_side = 1
			for bet in bets:
				if bet.team == tournament.current_winner:
					var lbl_inst = obj_label.instance()
					var betText = "%s, +%d (%d x %.2f)"
					lbl_inst.text = betText % [bet.name,
					bet.money * books[win_side].odds,
					bet.money,
					books[win_side].odds]
					match bet.type:
						"drone":
							lbl_inst.modulate = Color(1,1,1)
						"corp":
							lbl_inst.modulate = Color(1,0.85,0)
						"user":
							lbl_inst.modulate = Color(0,1,0)
						_:
							lbl_inst.modulate = Color(0,1,0)
					payout.item_list.add_child(lbl_inst)


# CHAT BOT FUNCTIONS
# add_command(cmd_name : String, instance : Object, instance_func : String, 
# max_args : int = 0, min_args : int = 0, 
# permission_level : int = PermissionFlag.EVERYONE, where : int = WhereFlag.CHAT)
func startup():
	chatbot.add_command("help", self, "cmd_help")
	chatbot.add_command("register", self, "cmd_register")
	chatbot.add_alias("register", "reg")
	chatbot.add_command("balance", self, "cmd_balance")
	chatbot.add_alias("balance", "bal")
	chatbot.add_command("bet", self, "cmd_bet", 2, 0)
	chatbot.add_command("allin", self, "cmd_allin", 1, 0)
	chatbot.add_command("fight", self, "cmd_fight", 2, 0)
	#chatbot.add_command("nextfight", self, "cmd_nextfight", 2, 0)
	connect_chat()


func connect_chat():
	chatbot.connect_to_twitch()
	yield(chatbot, "twitch_connected")
	chatbot.authenticate_oauth(GameData.CLIENT_ID, GameData.OAUTH)
	if(yield(chatbot, "login_attempt") == false):
		print("Invalid username or token.")
		return
	chatbot.join_channel(GameData.CHANNEL)
	chatbot.chat("Whatup big money hustlaz, SaltyFront is open for business! Throw bills or throw hands, whatever you want, just get in and get that paper!")


func twitch_message(message, _tags):
	if message == "PONG :tmi.twitch.tv":
		got_pong = true
		missed_pongs = 0


# CHAT MESSAGE HANDLER
func chat_msg(sender_data, message):
	var sender_id = UserDB.get_user_id(sender_data.user)
	if sender_id in active_users:
		arena.chat_msg(sender_id, message)


# CHAT COMMAND FUNCTIONS
# Help 
func cmd_help(cmd_info : CommandInfo):
	var user = cmd_info.sender_data.user
	chatbot.chat(user + ", chat command info is in the About section")


# Registration
func cmd_register(cmd_info : CommandInfo):
	var user = cmd_info.sender_data.user
	if UserDB.add_user(user) == true:
		chatbot.chat("Registered user " + user)
		GameData.write_log(user + ",register,ok", "command")
	else:
		chatbot.chat(user + ", you have already registered")
		GameData.write_log(user + ",register,err_existing", "command")
	return


# Check balance
func cmd_balance(cmd_info : CommandInfo):
	var user = cmd_info.sender_data.user
	var user_id = UserDB.get_user_id(user)
	if user_id != "":
		var thisUser = UserDB.users[user_id]
		chatbot.chat(user + ", your balance is "
		+ str(thisUser.money) + "G, with " + str(thisUser.insurance) + "G of insurance.")
		GameData.write_log(user + ",balance,ok", "command")
		return
	else:
		chatbot.chat("You have not registered yet.")
		GameData.write_log(user + ",balance,err_noreg", "command")
		return


# All in
# !allin ["left", "right", "random", team_name]
func cmd_allin(cmd_info : CommandInfo, arg_ary : PoolStringArray = []):
	var user = cmd_info.sender_data.user
	var user_id = UserDB.get_user_id(user)
	var thisUser = null
	if user_id == "":
		chatbot.chat(user + ", you have not registered yet. Please register to place bets.")
		GameData.write_log(user + ",allin,err_noreg", "command")
		return
	else:
		thisUser = UserDB.users[user_id]
	if self.state != GameState.PREFIGHT:
		chatbot.chat("Sorry " + user + ", betting is closed now!")
		GameData.write_log(user + ",allin,err_closed", "command")
		return
	# Only one param allowed, team name
	var current_teams = []
	for team in tournament.current_match.teams:
		current_teams.append(team.index)
	if arg_ary.size() == 1:
		for bet in bets:
			if bet.name == thisUser.name:
				chatbot.chat(thisUser.name + ", you've already placed a bet.")
				GameData.write_log(user + ",allin,err_existing", "command")
				return
		var betTeam = arg_ary[0].to_lower().strip_edges()
		if betTeam == "champ":
			betTeam = "champion"
		var teamIndex = GameData.teamNames.find(betTeam)
		match betTeam:
			"left":
				teamIndex = current_teams[0]
				betTeam = GameData.teamNames[teamIndex]
			"right":
				teamIndex = current_teams[1]
				betTeam = GameData.teamNames[teamIndex]
			"random":
				if randf() > 0.5:
					teamIndex = current_teams[0]
					betTeam = GameData.teamNames[teamIndex]
				else:
					teamIndex = current_teams[1]
					betTeam = GameData.teamNames[teamIndex]
			_:
				if teamIndex == -1 || !current_teams.has(teamIndex):
					chatbot.chat(thisUser.name + ", that team's not fighting right now.")
					GameData.write_log(user + ",bet,err_noteam", "command")
					return
		add_bet("user", thisUser.name, thisUser.money, teamIndex)
		var msg = thisUser.name + " bet it all on " + betTeam + "!"
		chatbot.chat(msg)
		GameData.write_log(user + ",allin,ok", "command")
		return
	else:
		chatbot.chat(thisUser.name + ", command error. Check the chat commands in the About section.")
		GameData.write_log(user + ",allin,err_syntax", "command")
		return


# Place bet on selected team
# !bet ["all", "half", bet_amt] ["left", "right", "random", team_name]
# !bet cancel: Cancels your current bet, if done before betting ends, bank keeps 10% cancellation fee.
# !bet: Gets your bet for the current match, and how much you stand to earn if you win.
func cmd_bet(cmd_info : CommandInfo, arg_ary : PoolStringArray = []):
	# Get user name, and check if they're registered, and if they can bet now
	var user = cmd_info.sender_data.user
	var user_id = UserDB.get_user_id(user)
	var thisUser = null
	if user_id == "":
		chatbot.chat(user + ", you have not registered yet. Please register to place bets.")
		GameData.write_log(user + ",bet,err_noreg", "command")
		return
	else:
		thisUser = UserDB.users[user_id]
	if self.state != GameState.PREFIGHT:
		chatbot.chat("Sorry " + user + ", betting is closed now!")
		GameData.write_log(user + ",bet,err_closed", "command")
		return
	# Validation cleared, prepare parameter variables
	var current_teams = []
	for team in tournament.current_match.teams:
		current_teams.append(team.index)
	var betMoney = 0
	var betTeam = ""
	var teamIndex = 0
	# Case 1: No parameters, get bet info and show it to user
	if arg_ary.size() == 0:
		for bet in bets:
			if bet.name == thisUser.name:
				chatbot.chat(thisUser.name +
				", you bet " + str(bet.money) +
				" on " + GameData.teamNames[bet.team].capitalize())
				GameData.write_log(user + ",bet,ok_check", "command")
				return
		chatbot.chat(thisUser.name + ", you haven't placed a bet.")
		GameData.write_log(user + ",bet,err_nobets", "command")
		return
	# Case 2: One parameter, check if it's the 'cancel' option or not
	elif arg_ary.size() == 1:
		if arg_ary[0].to_lower().strip_edges() == "cancel":
			for bet in bets:
				if bet.name == thisUser.name:
					cancel_bet(user_id)
					chatbot.chat(thisUser.name + ", you've cancelled your bet.")
					GameData.write_log(user + ",bet,ok_cancel", "command")
					return
			chatbot.chat(thisUser.name + ", you haven't placed a bet.")
			GameData.write_log(user + ",bet,err_nobets", "command")
			return
		else:
			chatbot.chat(thisUser.name + ", command error. Check the chat commands in the About section.")
			GameData.write_log(user + ",bet,err_syntax", "command")
			return
	# Case 3: Two parameters, check amount and team params
	elif arg_ary.size() > 1:
		for bet in bets:
			if bet.name == thisUser.name:
				chatbot.chat(thisUser.name + ", you've already placed a bet.")
				GameData.write_log(user + ",bet,err_existing", "command")
				return
		betMoney = arg_ary[0].to_lower().strip_edges()
		betTeam = arg_ary[1].to_lower().strip_edges()
		if betTeam == "champ":
			betTeam = "champion"
		teamIndex = GameData.teamNames.find(betTeam)
		match betTeam:
			"left":
				teamIndex = current_teams[0]
				betTeam = GameData.teamNames[teamIndex]
			"right":
				teamIndex = current_teams[1]
				betTeam = GameData.teamNames[teamIndex]
			"random":
				if randf() > 0.5:
					teamIndex = current_teams[0]
					betTeam = GameData.teamNames[teamIndex]
				else:
					teamIndex = current_teams[1]
					betTeam = GameData.teamNames[teamIndex]
			_:
				if teamIndex == -1 or !current_teams.has(teamIndex):
					chatbot.chat(thisUser.name + ", that team's not fighting right now.")
					GameData.write_log(user + ",bet,err_noteam", "command")
					return
		match betMoney:
			"all", "allin":
				var msg = thisUser.name + " bet it all on " + betTeam + "!"
				add_bet("user", thisUser.name, thisUser.money, teamIndex)
				chatbot.chat(msg)
				GameData.write_log(user + ",bet,ok_allin", "command")
				return
			"half", "halfin":
				var msg = thisUser.name + " bet half their money on " + betTeam + "!"
				add_bet("user", thisUser.name, floor(thisUser.money/2), teamIndex)
				chatbot.chat(msg)
				GameData.write_log(user + ",bet,ok_halfin", "command")
				return
			_:
				# Validate money string
				if regex_valid.search(betMoney) != null:
					chatbot.chat(thisUser.name + ", that's not a valid number.")
					GameData.write_log(user + ",bet,err_syntax", "command")
					return
				if thisUser.money < int(betMoney):
					chatbot.chat("Sorry, " + thisUser.name + ", you don't have enough money.")
					GameData.write_log(user + ",bet,err_nomoney", "command")
					return
				else:
					var msg = thisUser.name + " bet " + str(betMoney) + " on " + betTeam
					add_bet("user", thisUser.name, int(betMoney), teamIndex)
					chatbot.chat(msg)
					GameData.write_log(user + ",bet,ok_bet", "command")
					return


# !fight {pilot (0-3)} {skill}: Register a pilot to fight
# Will default to pilot0 if no pilot slot is given
# Can only use during team generation at the start of a tournament.
func cmd_fight(cmd_info : CommandInfo, arg_ary : PoolStringArray = []):
	# Get user ID from first param to validate
	var user = cmd_info.sender_data.user
	var user_id = UserDB.get_user_id(user)
	if user_id != "":
		if state == GameState.START:
			for entry in tournament.fight_queue:
				if entry.user == user_id:
					chatbot.chat(user + ", you have already signed up to fight.")
					return
		else:
			for entry in next_queue:
				if entry.user == user_id:
					chatbot.chat(user + ", you are already queued for the next tournament.")
					return
		var this_user = UserDB.users[user_id]
		if arg_ary.size() == 0:
			if state == GameState.START:
				signup(user_id, this_user.pilot0)
				chatbot.chat(user + " signed up to fight!")
			else:
				next_queue.append({"user":user_id, "pilot":this_user.pilot0})
				chatbot.chat(user + " signed up for the next tournament!")
			GameData.write_log(user + ",fight,ok_rand", "command")
			return
		if arg_ary.size() == 1:
			if tournament.PILOT_CLASS.keys().has(arg_ary[0]):
				if state == GameState.START:
					signup(user_id, this_user["pilot" + arg_ary[0]])
					chatbot.chat(user + " signed up to fight! Chosen class: " + arg_ary[0])
				else:
					next_queue.append({"user":user_id, "pilot":this_user["pilot" + arg_ary[0]]})
					chatbot.chat(user + " signed up for the next tournament! Chosen class: " + arg_ary[0])
				GameData.write_log(user + ",fight,ok_" + arg_ary[0], "command")
				return
			else:
				chatbot.chat("Invalid pilot slot")
				GameData.write_log(user + ",fight,err_nopilot", "command")
				return
		if arg_ary.size() > 1:
			if ["l", "h", "light", "heavy"].has(arg_ary[1]):
				pass
			chatbot.chat("Skill/equip setting not supported yet.")
			GameData.write_log(user + ",fight,err_noskill", "command")
			return
	else:
		chatbot.chat("Please register before signing up.")
		GameData.write_log(user + ",fight,err_noreg", "command")
		return


func buffer_screen():
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	var screenshot = ImageTexture.new()
	screenshot.create_from_image(img)
	scrn_buffer.texture = screenshot
	scrn_buffer.visible = true


func start_transition(next):
	state = GameState.TRANSITION
	next_state = next
	match next_state:
		GameState.START:
			$Transition/Bootup.start(tournament.tour_count)
		GameState.PREFIGHT:
			bets.clear()
			autoBet = false
			bet_warned = false
			ui_bracket.update_info(tournament.matches)
			buffer_screen()
			mid_transition()
		GameState.FIGHT:
			active_users.clear()
			var mech_list = []
			for team in tournament.current_match.teams:
				mech_list += team.mechs
			for mech in mech_list:
				if mech.user_id != "drone":
					active_users.append(mech.user_id)
			var message = ("Tournament " + str(tournament.current_match.tour) + ", " +
			tournament.current_match.name + " start, " +
			tournament.current_match.teams[0].name.capitalize() + " vs. " +
			tournament.current_match.teams[1].name.capitalize())
			if GameData.offline_mode:
				print(message)
			else:
				chatbot.chat(message)
			$Transition/AnimationPlayer.play("door_close")
		GameState.POSTFIGHT:
			$Transition/AnimationPlayer.play("door_close")
		GameState.TOUR_END:
			buffer_screen()
			mid_transition()
		GameState.RESET:
			tournament.fight_queue.clear()
			ui_signup.clear_users()
			ui_signup.counter.text = msg_signup_counter % [prep_timer]
			$Transition/AnimationPlayer.play("door_close")


func mid_transition():
	match next_state:
		GameState.START:
			did_comment = false
			$UI.visible = true
			$UI/Background.texture = tex_bg1
			$UI/Background.visible = true
			ui_signup.message.text = msg_signup % tournament.tour_count
			ui_signup.counter.text = msg_signup_counter % [prep_timer]
			ui_signup.visible = true
			ui_bracket.visible = false
			header_versus.visible = false
			prefight.visible = false
			stats.visible = false
			$UI/TourStats.visible = false
			$Transition/AnimationPlayer.play("door_open")
		GameState.PREFIGHT:
			$UI.visible = true
			$Hangar.load_mechs(tournament.current_match.teams)
			$UI/Background.texture = $Hangar/HangarView.get_texture() #tex_bg2
			var view_tex = $Hangar/HangarView.get_texture()
			$UI/PreFight/MechInfo.set_view(view_tex)
			var next_map = arena.roll_map()
			header_versus.match_info.text = msg_match_next % [
				tournament.current_match.tour,
				tournament.current_match.name
				]
			header_versus.set_teams(tournament.current_match.teams[0], tournament.current_match.teams[1])
			mech_info.focus_mech = tournament.current_match.teams[0].mechs[0]
			mech_info.update_info()
			header_versus.map_info.text = msg_map_info % [next_map.name, next_map.light]
			header_versus.counter.text = msg_next_counter % [bet_timer]
			header_versus.visible = true
			ui_signup.visible = false
			ui_bracket.visible = true
			prefight.visible = true
			stats.visible = false
			$UI/TourStats.visible = false
			ui_update()
			scrn_buffer.material.shader = shader_dissolve
			$Transition/AnimationPlayer.play("dissolve")
		GameState.FIGHT:
			arena.load_map(tournament)
			$UI/VersusHeader.modulate = Color(1, 1, 1, 1)
			$UI/PreFight.modulate = Color(1, 1, 1, 1)
			$UI.visible = false
			$Hangar.visible = false
			$Transition/AnimationPlayer.play("door_open")
		GameState.POSTFIGHT:
			$UI.visible = true
			arena.clear_map()
			$Hangar.visible = true
			$Hangar._ready()
			header_versus.match_info.text = msg_match_result % [
				tournament.current_match.tour,
				tournament.current_match.name
				]
			header_versus.counter.text = msg_next_counter % [pay_timer]
			ui_signup.visible = false
			ui_bracket.visible = false
			header_versus.visible = true
			prefight.visible = false
			stats.visible = true
			$UI/TourStats.visible = false
			ui_update()
			$Transition/AnimationPlayer.play("door_open")
		GameState.TOUR_END:
			ui_signup.visible = false
			ui_bracket.visible = false
			header_versus.visible = false
			prefight.visible = false
			stats.visible = false
			$Hangar.visible = true
			$UI/TourStats.visible = true
			scrn_buffer.material.shader = shader_dissolve
			$Transition/AnimationPlayer.play("dissolve")
		GameState.RESET:
			commentary("tour_outro")
			yield(get_tree().create_timer(5), "timeout")
			$Transition/AnimationPlayer.play("fade_out")


func end_transition():
	state = next_state
	match state:
		GameState.START:
			bgm_player.play_clip("new_tournament")
			bgm_player.play_track()
			if !GameData.offline_mode:
				chatbot.chat("A new tournament has begun! Sign ups are now open!")
			commentary("tour_intro")
			$Timer.start(prep_timer)
			for entry in next_queue:
				signup(entry.user, entry.pilot)
			next_queue.clear()
		GameState.PREFIGHT:
			bgm_player.play_clip("new_bet")
			if !GameData.offline_mode:
				chatbot.chat("Betting is now open!")
			ui_update()
			$Timer.start(bracket_timer)
		GameState.FIGHT:
			arena.start_match()
		GameState.POSTFIGHT:
			ui_update()
			commentary("post_fight_%s" % arena.match_result)
			$Timer.start(pay_timer)
		GameState.TOUR_END:
			bgm_player.play_clip("end_tournament")
			$Timer.start(prep_timer)
		GameState.RESET:
			state = GameState.TRANSITION
			next_state = GameState.START
			$Transition/Bootup.start(tournament.tour_count)


# EVENT HANDLERS
# Bootup sequence done playing
func _on_Bootup_boot_done():
	$Transition/AnimationPlayer.play("fade_in")


# Timer finished
func _on_Timer_timeout():
	match state:
		GameState.START:
			for corp in bet_ai.corps:
				var this_corp = bet_ai.corps[corp]
				this_corp.funds = stepify(rand_range(this_corp.budget[0], this_corp.budget[1]), this_corp.budget[2])
			tournament.new_tournament()
			start_transition(GameState.PREFIGHT)
		GameState.PREFIGHT:
			if ui_bracket.visible:
				ui_bracket.visible = false
				buffer_screen()
				scrn_buffer.material.shader = shader_melt
				$Transition/AnimationPlayer.play("dissolve")
			else:
				if !GameData.offline_mode:
					chatbot.chat("Betting is closed! Next match starts now!")
				$TweenUI.interpolate_property($UI/VersusHeader, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1.0)
				$TweenUI.interpolate_property($UI/PreFight, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1.0)
				$TweenUI.start()
				yield($TweenUI, "tween_all_completed")
				$Hangar.move_out()
		GameState.POSTFIGHT:
			tournament.next_match()
		GameState.TOUR_END:
			start_transition(GameState.RESET)


# Transition between game states
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name in ["door_open", "fade_out", "dissolve_in"]:
		end_transition()
	elif anim_name in ["door_close", "fade_in", "dissolve_out"]:
		mid_transition()
	elif anim_name == "dissolve":
		scrn_buffer.material.set_shader_param("progress", 0)
		if state == GameState.PREFIGHT:
			commentary("pre_fight")
			$Timer.start(bet_timer)
		else:
			end_transition()

