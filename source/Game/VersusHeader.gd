extends MarginContainer

onready var match_info = $PanelRow/Countdown/Body/Match
onready var counter = $PanelRow/Countdown/Body/Counter
onready var map_info = $PanelRow/Countdown/Body/Map
onready var team1 = $PanelRow/Team1
onready var team2 = $PanelRow/Team2


func set_teams(first : Dictionary, second : Dictionary) -> void:
	team1.set_team(first.index, first.mechs)
	team2.set_team(second.index, second.mechs)
