extends PanelContainer

const icon_w = 64
const icon_h = 16
const ICONS = {
	"melee":preload("res://ui/icons/icon_melee.png"),
	"mgun":preload("res://ui/icons/icon_mgun.png"),
	"sgun":preload("res://ui/icons/icon_sgun.png"),
	"rifle":preload("res://ui/icons/icon_rifle.png"),
	"flame":preload("res://ui/icons/icon_flame.png"),
	"missile":preload("res://ui/icons/icon_missile.png"),
}

# Accessor variables for UI elements
onready var wpn_info = $InfoCont/WeaponInfo
onready var wpn_icon = $InfoCont/WeaponIcon

# Weapon used in current attack action
var curr_wpn = null
var types = ["mgun", "rifle", "sgun", "flame", "grenade", "missile"]

# Update current weapon
func update_info(weapon):
	curr_wpn = weapon
	if curr_wpn != null:
		$InfoCont.visible = true
		$NoAction.visible = false
		wpn_icon.texture = ICONS[curr_wpn.type]
		wpn_info.text = (curr_wpn.name + "\n" + curr_wpn.type + " : " + 
		str(curr_wpn.fire_rate) + " x " + str(curr_wpn.damage))
		if "ammo" in curr_wpn:
			wpn_info.text += "\nAmmo: " + str(curr_wpn.ammo)
		else:
			wpn_info.text += "\nAmmo: N/A"
	else:
		$InfoCont.visible = false
		$NoAction.visible = true
