extends VBoxContainer

const obj_label = preload("res://ui/obj_label.tscn")
const format_team = "- %s TEAM -"
const format_odds = "ODDS: %.2f%% PAYOUT: x%.2f"
const format_bets = "%d BETS, %d TOTAL (%.2f%%)"
const format_bet = "%s, %d (%.2f%%)"

onready var labels = [
	{ 
		"team":$Body/Team1/TeamName,
		"odds":$Body/Team1/Odds,
		"bets":$Body/Team1/Bets,
		"list":$Body/Team1/BetList,
		"toplist":$TopBets/Team1/Body/BetList,
	},
	{
		"team":$Body/Team2/TeamName,
		"odds":$Body/Team2/Odds,
		"bets":$Body/Team2/Bets,
		"list":$Body/Team2/BetList,
		"toplist":$TopBets/Team2/Body/BetList
	}
]


func update_info(books, bets):
	for i in books.size():
		labels[i].team.text = format_team % GameData.teamNames[books[i].team].to_upper()
		labels[i].team.get("custom_styles/normal").bg_color = GameData.teamColors[books[i].team]
		labels[i].odds.text = format_odds % [books[i].percent * 100, books[i].odds]
		labels[i].bets.text = format_bets % [books[i].count, books[i].total, books[i].percent * 100]
		for label in labels[i].list.get_children():
			label.free()
		labels[i].toplist.text = ""
	for bet in bets:
		var inst_lbl = obj_label.instance()
		var ind = 0
		if bet.team != books[0].team:
			ind = 1
		var pct = float(bet.money) / books[ind].total * 100
		inst_lbl.text = format_bet % [bet.name, bet.money, pct]
		match bet.type:
			"drone":
				inst_lbl.modulate = Color(1,1,1)
			"corp":
				inst_lbl.modulate = Color(1,0.85,0)
			"user":
				inst_lbl.modulate = Color(0,1,0)
			_:
				inst_lbl.modulate = Color(0,1,0)
		labels[ind].list.add_child(inst_lbl)
		labels[ind].toplist.text += format_bet % [bet.name, bet.money, pct] + "\n"

