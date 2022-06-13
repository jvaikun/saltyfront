extends VBoxContainer

onready var bars = [
	$Body/Teams/Body/ChartBar,
	$Body/Teams/Body/ChartBar2,
	$Body/Teams/Body/ChartBar3,
	$Body/Teams/Body/ChartBar4,
	$Body/Teams/Body/ChartBar5,
	$Body/Teams/Body/ChartBar6,
	$Body/Teams/Body/ChartBar7,
	$Body/Teams/Body/ChartBar8
]
onready var ranks = [
	$Body/Leaderboard/Body/RankItem,
	$Body/Leaderboard/Body/RankItem2,
	$Body/Leaderboard/Body/RankItem3,
	$Body/Leaderboard/Body/RankItem4,
	$Body/Leaderboard/Body/RankItem5,
	$Body/Leaderboard/Body/RankItem6,
	$Body/Leaderboard/Body/RankItem7,
	$Body/Leaderboard/Body/RankItem8,
	$Body/Leaderboard/Body/RankItem9,
	$Body/Leaderboard/Body/RankItem10
]


func update_head(tourinfo):
	$Header/Title.text = "Tournament Overview\nAverage Turns: %d\nAverage Time: %d" % [tourinfo.avg_turns, tourinfo.avg_time]


func update_stats(info, stats):
	$Body/Teams/Body/Title.text = "Team Stats: %s" % info[0]
	$Body/Leaderboard/Body/Title.text = "%s\nPilot Ranking" % info[0]
	var maxval = 0
	# Go thru stat array, get name, selected stat, 
	for stat in stats.teams:
		if stat[info[1]] > maxval:
			maxval = stat[info[1]]
	for i in bars.size():
		bars[i].set_color(GameData.teamColors[i])
		bars[i].val_name = stats.teams[i].name.capitalize()
		bars[i].val_max = maxval
		bars[i].val_num = stats.teams[i][info[1]]
		$Tween.interpolate_property(bars[i], "val_num", 0, stats.teams[i][info[1]], 0.5)
	for i in ranks.size():
		ranks[i].set_rank(i+1, stats.ranking[info[1]][i].label, stats.ranking[info[1]][i].value)
	$Tween.start()
