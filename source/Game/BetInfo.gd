extends VBoxContainer

const format_bet = "%s, %d (%.2f%%)\n"
const team_info = "%s\nPAYOUT\nx%.2f"
const team_percent = "%dC"
const list_header = "TOP 10 BETS: %s"

onready var labels = [
	{ 
		"teaminfo":$Header/Body/Team1/TeamName,
		"teamcolor":$Header/Body/BetRatio/TeamColor1,
		"percent":$Header/Body/BetRatio/TeamColor1/Label,
		"listhead":$TopBets/Team1/Body/Header,
		"toplist":$TopBets/Team1/Body/BetList,
	},
	{
		"teaminfo":$Header/Body/Team2/TeamName,
		"teamcolor":$Header/Body/BetRatio/TeamColor2,
		"percent":$Header/Body/BetRatio/TeamColor2/Label,
		"listhead":$TopBets/Team2/Body/Header,
		"toplist":$TopBets/Team2/Body/BetList,
	}
]


# Custom sort class for sorting list vars
class CustomSort:
	# Sort by bet size, descending
	static func money(a, b):
		if a["money"] > b["money"]:
			return true
		return false


func update_info(books, bets):
	bets.sort_custom(CustomSort, "money")
	for i in books.size():
		labels[i].teaminfo.text = team_info % [
			GameData.teamNames[books[i].team].to_upper(),
			books[i].odds,
		]
		labels[i].teamcolor.color = GameData.teamColors[books[i].team]
		labels[i].percent.text = team_percent % books[i].total
		labels[i].listhead.get("custom_styles/normal").bg_color = GameData.teamColors[books[i].team]
		labels[i].listhead.text = list_header % GameData.teamNames[books[i].team].to_upper()
		labels[i].toplist.text = ""
	if books[1].total != 0:
		labels[0].teamcolor.size_flags_stretch_ratio = float(books[0].total) / books[1].total
	var count1 = 0
	var count2 = 0
	for bet in bets:
		var ind = 0
		if bet.team != books[0].team:
			ind = 1
		var pct = float(bet.money) / books[ind].total * 100
		if ind == 0:
			count1 += 1
			if count1 <= 10:
				labels[ind].toplist.text += format_bet % [bet.name, bet.money, pct]
		else:
			count2 += 1
			if count2 <= 10:
				labels[ind].toplist.text += format_bet % [bet.name, bet.money, pct]

