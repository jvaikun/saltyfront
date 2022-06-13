extends Node2D

var team_color = null

func hit_body():
	$Body.self_modulate = Color(1, 1, 1)
	$Body/Pack.self_modulate = Color(1, 1, 1)

func hit_armr():
	$Body/ArmR.self_modulate = Color(1, 1, 1)
	$Body/ArmR/PodR.self_modulate = Color(1, 1, 1)
	$Body/ArmR/WeaponR.self_modulate = Color(1, 1, 1)

func hit_arml():
	$Body/ArmL.self_modulate = Color(1, 1, 1)
	$Body/ArmL/PodL.self_modulate = Color(1, 1, 1)
	$Body/ArmL/WeaponL.self_modulate = Color(1, 1, 1)

func hit_legs():
	$Body/LegR.self_modulate = Color(1, 1, 1)
	$Body/LegL.self_modulate = Color(1, 1, 1)

func reset_color():
	if team_color != null:
		set_color(team_color)

func set_color(rgb_color):
	team_color = rgb_color
	$Body.material.set_shader_param("active", false)
	$Body.self_modulate = rgb_color
	$Body/Pack.self_modulate = rgb_color
	$Body/ArmR.material.set_shader_param("active", false)
	$Body/ArmR.self_modulate = rgb_color
	$Body/ArmR/PodR.self_modulate = rgb_color
	$Body/ArmR/WeaponR.self_modulate = rgb_color
	$Body/ArmL.material.set_shader_param("active", false)
	$Body/ArmL.self_modulate = rgb_color
	$Body/ArmL/PodL.self_modulate = rgb_color
	$Body/ArmL/WeaponL.self_modulate = rgb_color
	$Body/LegR.material.set_shader_param("active", false)
	$Body/LegR.self_modulate = rgb_color
	$Body/LegL.material.set_shader_param("active", false)
	$Body/LegL.self_modulate = rgb_color

