extends Spatial

const hitspark_obj = preload("res://Effects/HitSpark.tscn")
const dmgnum_obj = preload("res://Effects/DamageNum.tscn")

var mat_base = null
var mat_team = null
var tex_normal = null
var tex_broken = load("res://scenes/parts/tex_damage.png")
var spark_damage


func _ready():
	var this_mesh = $Armature/Skeleton.get_child(0).mesh
	mat_base = this_mesh.surface_get_material(0)
	tex_normal = mat_base.albedo_texture
	if this_mesh.get_surface_count() > 1:
		mat_team = this_mesh.surface_get_material(1)
	spark_damage = find_node("Sparks")


func impact(type, damage, crit):
	var spark_inst = hitspark_obj.instance()
	spark_damage.add_child(spark_inst)
	var dmgnum = dmgnum_obj.instance()
	spark_damage.add_child(dmgnum)
	if type == "repair":
		dmgnum.label.modulate = Color(0, 1, 0, 1)
	dmgnum.label.text = str(damage)
	if crit > 1:
		dmgnum.label.modulate = Color(1, 0, 0, 1)


func set_state(state):
	match state:
		"normal":
			mat_base.albedo_texture = tex_normal
			spark_damage.emitting = false
		"critical":
			mat_base.albedo_texture = tex_normal
			spark_damage.emitting = true
		"broken":
			mat_base.albedo_texture = tex_broken
			spark_damage.emitting = true
