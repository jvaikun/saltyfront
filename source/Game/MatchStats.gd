extends Control

# Accessor vars
onready var pilots = [
	{"pilot":$Rankings/Body/List/Team1Mech1/PilotInfo, 
	"bonus":$Rankings/Body/List/Team1Mech1/Label},
	{"pilot":$Rankings/Body/List/Team1Mech2/PilotInfo, 
	"bonus":$Rankings/Body/List/Team1Mech2/Label},
	{"pilot":$Rankings/Body/List/Team1Mech3/PilotInfo, 
	"bonus":$Rankings/Body/List/Team1Mech3/Label},
	{"pilot":$Rankings/Body/List/Team1Mech4/PilotInfo, 
	"bonus":$Rankings/Body/List/Team1Mech4/Label},
	{"pilot":$Rankings/Body/List/Team2Mech1/PilotInfo, 
	"bonus":$Rankings/Body/List/Team2Mech1/Label},
	{"pilot":$Rankings/Body/List/Team2Mech2/PilotInfo, 
	"bonus":$Rankings/Body/List/Team2Mech2/Label},
	{"pilot":$Rankings/Body/List/Team2Mech3/PilotInfo, 
	"bonus":$Rankings/Body/List/Team2Mech3/Label},
	{"pilot":$Rankings/Body/List/Team2Mech4/PilotInfo, 
	"bonus":$Rankings/Body/List/Team2Mech4/Label},
]

func update_info(team1, team2):
	var results1 = {"id":0, "hits":0, "crits":0, "misses":0, "dmg_out":0, "dmg_in":0, "part_dest":0, "part_lost":0}
	var results2 = {"id":0, "hits":0, "crits":0, "misses":0, "dmg_out":0, "dmg_in":0, "part_dest":0, "part_lost":0}
	for mech in team1.mechs:
		results1.id = mech.team
		results1.hits += mech.hit
		results1.crits += mech.crit
		results1.misses += mech.miss
		results1.dmg_out += mech.dmg_out
		results1.dmg_in += mech.dmg_in
		results1.part_dest += mech.part_dest
		results1.part_lost += mech.part_lost
	for mech in team2.mechs:
		results2.id = mech.team
		results2.hits += mech.hit
		results2.crits += mech.crit
		results2.misses += mech.miss
		results2.dmg_out += mech.dmg_out
		results2.dmg_in += mech.dmg_in
		results2.part_dest += mech.part_dest
		results2.part_lost += mech.part_lost
	# Update Team 1 stats
	$SideBox/TeamStats/Body/Team1/TeamHeader/Name.text = team1.name.capitalize()
	$SideBox/TeamStats/Body/Team1/TeamHeader/TeamColor.modulate = team1.color
	$SideBox/TeamStats/Body/Team1/Hits.text = str(results1.hits)
	$SideBox/TeamStats/Body/Team1/Crits.text = str(results1.crits)
	$SideBox/TeamStats/Body/Team1/Misses.text = str(results1.misses)
	$SideBox/TeamStats/Body/Team1/DamageOut.text = str(results1.dmg_out)
	$SideBox/TeamStats/Body/Team1/DamageIn.text = str(results1.dmg_in)
	$SideBox/TeamStats/Body/Team1/PartDest.text = str(results1.part_dest)
	$SideBox/TeamStats/Body/Team1/PartLost.text = str(results1.part_lost)
	# Update Team 2 stats
	$SideBox/TeamStats/Body/Team2/TeamHeader/Name.text = team2.name.capitalize()
	$SideBox/TeamStats/Body/Team2/TeamHeader/TeamColor.modulate = team2.color
	$SideBox/TeamStats/Body/Team2/Hits.text = str(results2.hits)
	$SideBox/TeamStats/Body/Team2/Crits.text = str(results2.crits)
	$SideBox/TeamStats/Body/Team2/Misses.text = str(results2.misses)
	$SideBox/TeamStats/Body/Team2/DamageOut.text = str(results2.dmg_out)
	$SideBox/TeamStats/Body/Team2/DamageIn.text = str(results2.dmg_in)
	$SideBox/TeamStats/Body/Team2/PartDest.text = str(results2.part_dest)
	$SideBox/TeamStats/Body/Team2/PartLost.text = str(results2.part_lost)
	# Create rankings
	var all_mechs = team1.mechs + team2.mechs
	for i in all_mechs.size():
		pilots[i].bonus.text = ""
		pilots[i].pilot.set_focus(all_mechs[i])
		if all_mechs[i].bonuses.empty():
			pilots[i].bonus.text = "No Bonus"
		else:
			for item in all_mechs[i].bonuses:
				pilots[i].bonus.text += "%s +%d\n" % [item.title, item.pay]
