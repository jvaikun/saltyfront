extends Spatial

const mat_mech = preload("res://scenes/parts/mat_mech.material")
const mat_team = preload("res://scenes/parts/mat_team.material")
const source_dirs = [
	"res://scenes/parts/arml/models/",
	"res://scenes/parts/armr/models/",
	"res://scenes/parts/body/models/",
	"res://scenes/parts/legs/models/",
]
const model_paths = [
	"res://scenes/parts/arml/models/mech_%s.glb",
	"res://scenes/parts/armr/models/mech_%s.glb",
	"res://scenes/parts/body/models/mech_%s.glb",
	"res://scenes/parts/legs/models/mech_%s.glb",
]
const tex_paths = [
	"res://scenes/parts/arml/textures/tex_%s.png",
	"res://scenes/parts/armr/textures/tex_%s.png",
	"res://scenes/parts/body/textures/tex_%s.png",
	"res://scenes/parts/legs/textures/tex_%s.png",
]
const out_paths = [
	"res://scenes/parts/arml/mech_%s.tscn",
	"res://scenes/parts/armr/mech_%s.tscn",
	"res://scenes/parts/body/mech_%s.tscn",
	"res://scenes/parts/legs/mech_%s.tscn",
]
const bone_list = {
	"hand":"Hand",
	"shoulder":"Shoulder",
	"root":"Hip",
	"arm.r":"ArmR",
	"arm.l":"ArmL",
	"pack":"Pack"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Go through directories and build file lists
	var dir = Directory.new()
	var file_lists = []
	for path in source_dirs:
		var err = dir.open(path)
		if err:
			print("Couldn't open directory!")
		else:
			dir.list_dir_begin()
			var file_list = []
			var file_name = dir.get_next()
			while file_name != "":
				if !dir.current_is_dir() and file_name.ends_with(".glb"):
					file_list.append(file_name.trim_prefix("mech_").trim_suffix(".glb"))
				file_name = dir.get_next()
			dir.list_dir_end()
			file_lists.append(file_list)
	
	# Load objects from file and save to PackedScene
	for i in source_dirs.size():
		for file in file_lists[i]:
			var load_inst = load(model_paths[i] % file).instance()
			add_child(load_inst)
			
			var skel = load_inst.get_node("Armature/Skeleton")
			if is_instance_valid(skel):
				# Set mesh materials to mech base material and team color
				var this_mesh = skel.get_child(0).mesh
				var tex_path = tex_paths[i] % file
				mat_mech.albedo_texture = load(tex_path)
				this_mesh.surface_set_material(0, mat_mech.duplicate())
				if this_mesh.get_surface_count() > 1:
					mat_team.albedo_color = Color(1, 0, 0)
					this_mesh.surface_set_material(1, mat_team.duplicate())
				# Add BoneAttachments to Armature/Skeleton
				for bone in bone_list.keys():
					if skel.find_bone(bone) >= 0:
						var attach = BoneAttachment.new()
						skel.add_child(attach)
						attach.owner = load_inst
						attach.name = bone_list[bone]
						attach.bone_name = bone
			
			# Save object to PackedScene file then free it
			var scene = PackedScene.new()
			var result = scene.pack(load_inst)
			if result == OK:
				var file_path = out_paths[i] % file
				var error = ResourceSaver.save(file_path, scene)
				if error != OK:
					push_error("An error occurred while saving the scene to disk.")
			load_inst.free()
