extends MarginContainer

onready var tournament = $PanelRow/Versus/MatchInfo/Tournament
onready var match_name = $PanelRow/Versus/MatchInfo/Round
onready var team1_group = $PanelRow/Team1/TeamInfo
onready var team1_name = $PanelRow/Team1/TeamInfo/TeamName
onready var team1_count = $PanelRow/Team1/TeamInfo/TeamCount
onready var team2_group = $PanelRow/Team2/TeamInfo
onready var team2_name = $PanelRow/Team2/TeamInfo/TeamName
onready var team2_count = $PanelRow/Team2/TeamInfo/TeamCount

var team1_index = null
var team2_index = null

func setup(tour, round_name, team1, team2):
	tournament.text = "Tournament " + str(tour)
	match_name.text = round_name
	team1_index = team1.index
	team1_group.modulate = team1.color
	team1_name.text = team1.name.capitalize()
	team1_count.value = 4
	team2_index = team2.index
	team2_group.modulate = team2.color
	team2_name.text = team2.name.capitalize()
	team2_count.value = 4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
