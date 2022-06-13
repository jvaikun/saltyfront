extends HBoxContainer

onready var rank = $Rank
onready var label = $Label
onready var num = $Number

func set_rank(rnk, lbl, val):
	rank.text = str(rnk)
	label.text = lbl
	num.text = str(val)
