extends Control

const msg_no_champ = "The Champion's throne sits empty..."
const msg_champ = "The reigning Champions, %s Team!\nWith a %d match winning streak!"

onready var teams = [
	{"team":$LeftSide/Team1, "line":$Lines/Team1},
	{"team":$LeftSide/Team2, "line":$Lines/Team2},
	{"team":$LeftSide/Team3, "line":$Lines/Team3},
	{"team":$LeftSide/Team4, "line":$Lines/Team4},
	{"team":$RightSide/Team5, "line":$Lines/Team5},
	{"team":$RightSide/Team6, "line":$Lines/Team6},
	{"team":$RightSide/Team7, "line":$Lines/Team7},
	{"team":$RightSide/Team8, "line":$Lines/Team8}
]


func set_teams(roster, champ):
	for line in $Lines.get_children():
		line.default_color = Color(0,0,0)
	for i in teams.size():
		teams[i].team.set_team(i, roster[i].data)
		teams[i].line.default_color = Color(0,1,0)
	$Champ.caption.visible = true
	if champ.data.empty():
		$Champ.set_team(8, [])
		$Champ.caption.text = msg_no_champ
	else:
		$Champ.set_team(8, champ.data)
		$Champ.caption.text = msg_champ % [GameData.teamNames[champ.team].capitalize(), champ.streak]


func eliminate(team):
	if team == 8:
		$Champ.set_loss(true)
		$Champ.caption.visible = false
	else:
		teams[team].team.set_loss(true)
		teams[team].line.default_color = Color(0,0,0)


func update_info(matches):
	if matches[4].teams[0] != -1:
		$Lines/QF1Win.default_color = Color(0,1,0)
	if matches[4].teams[1] != -1:
		$Lines/QF2Win.default_color = Color(0,1,0)
	if matches[5].teams[0] != -1:
		$Lines/QF3Win.default_color = Color(0,1,0)
	if matches[5].teams[1] != -1:
		$Lines/QF4Win.default_color = Color(0,1,0)
	if matches[6].teams[0] != -1:
		$Lines/SF1Win.default_color = Color(0,1,0)
		if matches[4].teams[0] != matches[6].teams[0]:
			$Lines/QF1Win.default_color = Color(0,0,0)
		if matches[4].teams[1] != matches[6].teams[0]:
			$Lines/QF2Win.default_color = Color(0,0,0)
	if matches[6].teams[1] != -1:
		$Lines/SF2Win.default_color = Color(0,1,0)
		if matches[5].teams[0] != matches[6].teams[1]:
			$Lines/QF3Win.default_color = Color(0,0,0)
		if matches[5].teams[1] != matches[6].teams[1]:
			$Lines/QF4Win.default_color = Color(0,0,0)
	if matches[7].teams[0] != -1:
		$Lines/FinalWin.default_color = Color(0,1,0)
		if matches[6].teams[0] != matches[7].teams[0]:
			$Lines/SF1Win.default_color = Color(0,0,0)
		if matches[6].teams[1] != matches[7].teams[0]:
			$Lines/SF2Win.default_color = Color(0,0,0)

