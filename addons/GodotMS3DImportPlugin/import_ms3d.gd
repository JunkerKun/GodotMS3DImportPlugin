tool
extends EditorImportPlugin

class MS3DHeader:
	var id: String
	var version: int
	
class MS3DVertex:
	var flags: int
	var vertex: Array
	var bone_id: int
	var reference_count: int

	var bone_ids: Array
	var weights: Array
	
class MS3DTriangle:
	var flags: int
	var vertex_indices: Array
	var vertex_normals: Array
	var s: Array
	var t: Array
	var smoothing_group: int
	var group_index: int
	
class MS3DGroup:
	var flags: int
	var name: String
	var num_triangles: int
	var triangle_indices: Array
	var material_index: int
	
class MS3DMaterial:
	var name: String
	var ambient: Array
	var diffuse: Array
	var specular: Array
	var emissive: Array
	var shininess: float
	var transparency: float
	var mode: int
	var texture: String
	var alphamap: String
	
class MS3Dkey_rot:
	var time: float
	var rotation: Array  
	
class MS3Dkey_pos:
	var time: float
	var position: Array 
	
class MS3DJoint:
	var flags: int
	var name: String
	var parent_name: String
	var rotation: Array
	var position: Array
	var num_key_frames_rot: int
	var num_key_frames_trans: int
	var key_frames_rot: Array
	var key_frames_trans: Array
	
class MS3DVertExt:
	var bone_ids: Array
	var weights: Array
	var extra: Array
	
class AnimFrame:
	var frame: int
	var duration: float
	
class AnimData:
	var name: String
	var frames: Array
	var is_looped: bool

func get_importer_name():
	return "jessicochan.ms3d"

func get_visible_name():
	return "MS3D Model Importer"

func get_recognized_extensions():
	return ["ms3d"]

func get_save_extension():
	return "scn"

func get_resource_type():
	return "PackedScene"

func get_import_options(preset):
	return [
		{"name": "scale_modifier", "default_value": 1.0},
		{"name": "wrap_loop", "default_value": false}
	]

func get_preset_count():
	return 1

func get_preset_name(preset):
	return "Default"
	
func addBone(skeleton, name, parent_name):
	skeleton.add_bone(name)
	
	var parent_id = skeleton.find_bone(parent_name)
	var bone_id = skeleton.find_bone(name) 
	
	skeleton.set_bone_parent(bone_id, parent_id)

	var bone_transform = Transform()
	bone_transform.origin = Vector3(0, 1, 0)

	skeleton.set_bone_rest(bone_id, bone_transform)

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	#Reading animations file
	var anim_data: Dictionary
	var anim_file = File.new()
	var anim_path = source_file
	anim_path.erase(anim_path.length() - 5, 5)
	anim_path += ".anims"
	if anim_file.open(anim_path, File.READ) != OK:
		print("Warn: No animation file found. Creating animation for entire timeline")
	else:
		var current_animation: AnimData = null
		while !anim_file.eof_reached():
			var line = anim_file.get_line()
			if line.empty():
				continue
			
			var params = line.split(" ")
			if params[0] == "animation":
				current_animation = AnimData.new()
				current_animation.name = params[1]
				current_animation.is_looped = params.size() > 2 && params[2] == "loop"
				anim_data[params[1]] = current_animation
				continue
			
			if params[0] == "frame":
				var frame = AnimFrame.new()
				frame.frame = int(params[1])
				frame.duration = float(params[2])
				current_animation.frames.push_back(frame)
				
			if params[0] == "frameset":
				var begin = int(params[1])
				var end = int(params[2]) + 1
				
				for i in range(begin, end):
					var frame = AnimFrame.new()
					frame.frame = i
					frame.duration = float(params[3])
					current_animation.frames.push_back(frame)
		
	#Reading file
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return ERR_FILE_CANT_OPEN
	
	var header = MS3DHeader.new()
	header.id = file.get_buffer(10).get_string_from_utf8()
	header.version = file.get_32()
	
	var num_vertices = file.get_16()
	var vertices = Array()
	for i in range(num_vertices):
		var vertex = MS3DVertex.new()
		vertex.flags = file.get_8()
		vertex.vertex = Array()
		vertex.vertex.append(file.get_float())
		vertex.vertex.append(file.get_float())
		vertex.vertex.append(file.get_float())
		vertex.bone_id = file.get_8()
		vertex.reference_count = file.get_8()
		vertices.append(vertex)
		
	var num_triangles = file.get_16()
	var triangles = Array()
	for i in range(num_triangles):
		var triangle = MS3DTriangle.new()
		triangle.flags = file.get_16()
		triangle.vertex_indices = Array()
		triangle.vertex_indices.append(file.get_16())
		triangle.vertex_indices.append(file.get_16())
		triangle.vertex_indices.append(file.get_16())
		triangle.vertex_normals = Array()
		var n1 = Array()
		n1.append(file.get_float())
		n1.append(file.get_float())
		n1.append(file.get_float())
		triangle.vertex_normals.append(n1)
		var n2 = Array()
		n2.append(file.get_float())
		n2.append(file.get_float())
		n2.append(file.get_float())
		triangle.vertex_normals.append(n2)
		var n3 = Array()
		n3.append(file.get_float())
		n3.append(file.get_float())
		n3.append(file.get_float())
		triangle.vertex_normals.append(n3)
		triangle.s = Array()
		triangle.s.append(file.get_float())
		triangle.s.append(file.get_float())
		triangle.s.append(file.get_float())
		triangle.t = Array()
		triangle.t.append(file.get_float())
		triangle.t.append(file.get_float())
		triangle.t.append(file.get_float())
		triangle.smoothing_group = file.get_8()
		triangle.group_index = file.get_8()
		triangles.append(triangle)
	
	var num_groups = file.get_16()
	var groups = Array()
	for i in range(num_groups):
		var group = MS3DGroup.new()
		group.flags = file.get_8()
		group.name = file.get_buffer(32).get_string_from_utf8()
		group.num_triangles = file.get_16()
		group.triangle_indices = Array()
		for j in range(group.num_triangles):
			group.triangle_indices.append(file.get_16())
		group.material_index = file.get_8()
		groups.append(group)
		
	var num_materials = file.get_16()
	var materials = Array()
	for i in range(num_materials):
		var material = MS3DMaterial.new()
		material.name = file.get_buffer(32).get_string_from_utf8()
		material.ambient = Array()
		material.ambient.append(file.get_float())
		material.ambient.append(file.get_float())
		material.ambient.append(file.get_float())
		material.ambient.append(file.get_float())
		material.diffuse = Array()
		material.diffuse.append(file.get_float())
		material.diffuse.append(file.get_float())
		material.diffuse.append(file.get_float())
		material.diffuse.append(file.get_float())
		material.specular = Array()
		material.specular.append(file.get_float())
		material.specular.append(file.get_float())
		material.specular.append(file.get_float())
		material.specular.append(file.get_float())
		material.emissive = Array()
		material.emissive.append(file.get_float())
		material.emissive.append(file.get_float())
		material.emissive.append(file.get_float())
		material.emissive.append(file.get_float())
		material.shininess = file.get_float()
		material.transparency = file.get_float()
		material.mode = file.get_8()
		material.texture = file.get_buffer(128).get_string_from_utf8()
		material.alphamap = file.get_buffer(128).get_string_from_utf8()
		materials.append(material)
		
	var animation_fps = file.get_float()
	var current_time = file.get_float()
	var total_frames = file.get_float()

	var num_joints = file.get_16()
	var joints = Array()
	for i in range(num_joints):
		var joint = MS3DJoint.new()
		joint.flags = file.get_8()
		joint.name = file.get_buffer(32).get_string_from_utf8()
		joint.parent_name = file.get_buffer(32).get_string_from_utf8()
		joint.rotation = Array()
		joint.rotation.append(file.get_float())
		joint.rotation.append(file.get_float())
		joint.rotation.append(file.get_float())
		joint.position = Array()
		joint.position.append(file.get_float())
		joint.position.append(file.get_float())
		joint.position.append(file.get_float())
		joint.num_key_frames_rot = file.get_16()
		joint.num_key_frames_trans = file.get_16()
		joint.key_frames_rot = Array()
		for j in range(joint.num_key_frames_rot):
			var key_frame_rot = MS3Dkey_rot.new()
			key_frame_rot.time = file.get_float()
			key_frame_rot.rotation = Array()
			key_frame_rot.rotation.append(file.get_float())
			key_frame_rot.rotation.append(file.get_float())
			key_frame_rot.rotation.append(file.get_float())
			joint.key_frames_rot.append(key_frame_rot)
		joint.key_frames_trans = Array()
		for j in range(joint.num_key_frames_trans):
			var key_frame_trans = MS3Dkey_pos.new()
			key_frame_trans.time = file.get_float()
			key_frame_trans.position = Array()
			key_frame_trans.position.append(file.get_float())
			key_frame_trans.position.append(file.get_float())
			key_frame_trans.position.append(file.get_float())
			joint.key_frames_trans.append(key_frame_trans)
		
		joints.append(joint)
		
	#Skipping comments
	var sub_version = file.get_32()
	var num_group_comments = file.get_32()
	for i in range(num_group_comments):
		var index = file.get_32()
		var comment_length = file.get_32()
		var comment = file.get_buffer(comment_length).get_string_from_utf8()
		
	var nNumMaterialComments = file.get_32()
	for i in range(nNumMaterialComments):
		var index = file.get_32()
		var comment_length = file.get_32()
		var comment = file.get_buffer(comment_length).get_string_from_utf8()
		
	var nNumJointComments = file.get_32()
	for i in range(nNumJointComments):
		var index = file.get_32()
		var comment_length = file.get_32()
		var comment = file.get_buffer(comment_length).get_string_from_utf8()
		
	var nHasModelComment = file.get_32()
	for i in range(nHasModelComment):
		var index = file.get_32()
		var comment_length = file.get_32()
		var comment = file.get_buffer(comment_length).get_string_from_utf8()
		
	sub_version = file.get_32()
	var weights: Array
	for i in range(num_vertices):
		var weight = MS3DVertExt.new()
		weight.bone_ids = Array()
		weight.bone_ids.append(0)
		var id = file.get_8()
		if id & 128:
			id = id - 256
		weight.bone_ids.append(id)
		id = file.get_8()
		if id & 128:
			id = id - 256
		weight.bone_ids.append(id)
		id = file.get_8()
		if id & 128:
			id = id - 256
		weight.bone_ids.append(id)
		weight.weights = Array()
		weight.weights.append(file.get_8() / 100.0)
		weight.weights.append(file.get_8() / 100.0)
		weight.weights.append(file.get_8() / 100.0)
		weight.extra = Array()
		if sub_version == 2:
			weight.extra.append(file.get_32())
		weights.append(weight)
		
	for i in range(num_vertices):
		var weight = weights[i]
		weight.bone_ids[0] = vertices[i].bone_id
		if weight.bone_ids[1] == -1:
			weight.bone_ids[1] = 0
		if weight.bone_ids[2] == -1:
			weight.bone_ids[2] = 0
		if weight.bone_ids[3] == -1:
			weight.bone_ids[3] = 0
		weight.weights.append(1.0 - weight.weights[0] - weight.weights[1] - weight.weights[2])
		
	file.close()
		
	#Creating nodes structure
	var root_node = Spatial.new()
	root_node.name = source_file.get_file().get_basename()
	
	var skeleton_node = Spatial.new()
	skeleton_node.name = "Skeleton"
	root_node.add_child(skeleton_node)
	skeleton_node.set_owner(root_node)
	
	var skeleton = Skeleton.new()
	skeleton.name = "Skeleton3D"
	for i in range(joints.size()):
		addBone(skeleton, joints[i].name, joints[i].parent_name)
		
		var bone_id = skeleton.find_bone(joints[i].name)
		var bone_transform = Transform()

		bone_transform = bone_transform.rotated(Vector3(1, 0, 0), joints[i].rotation[0])
		bone_transform = bone_transform.rotated(Vector3(0, 1, 0), joints[i].rotation[1])
		bone_transform = bone_transform.rotated(Vector3(0, 0, 1), joints[i].rotation[2])
		
		bone_transform.origin = Vector3(
			joints[i].position[0], 
			joints[i].position[1], 
			joints[i].position[2]
		)
		
		skeleton.set_bone_rest(bone_id, bone_transform)
		
	skeleton_node.add_child(skeleton)
	skeleton.set_owner(root_node)
	
	var mesh_instance = MeshInstance.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = ArrayMesh.new()
	
	var v = PoolVector3Array()
	var n = PoolVector3Array()
	var st = PoolVector2Array()
	var b = PoolIntArray()
	var w = PoolRealArray()
	for i in range(triangles.size()):
		var tri = triangles[i]
		var v1 = vertices[tri.vertex_indices[0]].vertex
		var v2 = vertices[tri.vertex_indices[1]].vertex
		var v3 = vertices[tri.vertex_indices[2]].vertex
		var w1 = weights[tri.vertex_indices[0]]
		var w2 = weights[tri.vertex_indices[1]]
		var w3 = weights[tri.vertex_indices[2]]
		var n1 = tri.vertex_normals[0]
		var n2 = tri.vertex_normals[1]
		var n3 = tri.vertex_normals[2]
		
		n.append(Vector3(n1[0], n1[1], n1[2]))
		v.append(Vector3(v1[0], v1[1], v1[2]))
		st.append(Vector2(tri.s[0], tri.t[0]))
		b.append_array([w1.bone_ids[0], w1.bone_ids[1], w1.bone_ids[2], w1.bone_ids[3]])
		w.append_array([w1.weights[0], w1.weights[1], w1.weights[2], w1.weights[3]])
		
		n.append(Vector3(n2[0], n2[1], n2[2]))
		v.append(Vector3(v2[0], v2[1], v2[2]))
		st.append(Vector2(tri.s[1], tri.t[1]))
		b.append_array([w2.bone_ids[0], w2.bone_ids[1], w2.bone_ids[2], w2.bone_ids[3]])
		w.append_array([w2.weights[0], w2.weights[1], w2.weights[2], w2.weights[3]])
		
		n.append(Vector3(n3[0], n3[1], n3[2]))
		v.append(Vector3(v3[0], v3[1], v3[2]))
		st.append(Vector2(tri.s[2], tri.t[2]))
		b.append_array([w3.bone_ids[0], w3.bone_ids[1], w3.bone_ids[2], w3.bone_ids[3]])
		w.append_array([w3.weights[0], w3.weights[1], w3.weights[2], w3.weights[3]])
		
	v.invert()
	n.invert()
	st.invert()
	b.invert()
	w.invert()

	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = v
	arrays[ArrayMesh.ARRAY_NORMAL] = n
	arrays[ArrayMesh.ARRAY_TEX_UV] = st
	arrays[ArrayMesh.ARRAY_BONES] = b
	arrays[ArrayMesh.ARRAY_WEIGHTS] = w
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	skeleton.add_child(mesh_instance)
	mesh_instance.set_owner(root_node)
	
	#Adding animations
	var animation_offsets: Dictionary
	var animation_player = AnimationPlayer.new()
	if anim_data.size() == 0:
		var newanim_data = AnimData.new()
		newanim_data.name = "Animation"
		anim_data["Animation"] = newanim_data
		
		var new_animation = Animation.new()
		new_animation.length = joints[0].key_frames_rot.size()
		animation_player.add_animation("Animation", new_animation)
		var new_dictionary: Dictionary
		animation_offsets["Animation"] = new_dictionary
		var anm = anim_data["Animation"]
		for j in range(num_joints):
			var joint = joints[j]
			var bone_name = skeleton.get_bone_name(j)
			new_dictionary[bone_name] = 0
			if anm.frames.empty():
				for t in range(joint.num_key_frames_trans):
					var new_frame = AnimFrame.new()
					new_frame.frame = t
					new_frame.duration = 0.1
					anm.frames.push_back(new_frame)
			
	else:
		for i in anim_data.values():
			var new_animation = Animation.new()
			var totalLength = 0
			var end = i.frames.size() - 1
			if options["wrap_loop"]:
				end = i.frames.size()
			for t in range(end):
				totalLength += i.frames[t].duration
			new_animation.length = totalLength
			animation_player.add_animation(i.name, new_animation)
			animation_player.get_animation(i.name).loop = i.is_looped
			var new_dictionary: Dictionary
			animation_offsets[i.name] = new_dictionary
			
			for j in range(num_joints):
				var joint = joints[j]
				var bone_name = skeleton.get_bone_name(j)
				new_dictionary[bone_name] = 0
	
	for i in range(num_joints):
		var joint = joints[i]
		var bone_name = skeleton.get_bone_name(i)
		var path = str(root_node.get_path_to(skeleton)) + ":" + bone_name
		var node_path = NodePath(path)
		for a in anim_data.values():
			var animation = animation_player.get_animation(a.name)
			if animation == null:
				animation = animation_player.get_animation("Animation")
				if animation == null:
					continue
						
			for fr in a.frames:
				for j in range(joint.key_frames_trans.size()):
					if fr.frame == j:
						var trackId = animation.find_track(node_path)
						if trackId == -1:
							trackId = animation.add_track(Animation.TYPE_TRANSFORM)
							animation.track_set_path(trackId, node_path)
						
						var key_pos = joint.key_frames_trans[j].position
						var rotIndex = j
						if j >= joint.key_frames_rot.size():
							rotIndex = joint.key_frames_rot.size() - 1
						var key_rot = joint.key_frames_rot[rotIndex].rotation
						
						var position = Vector3(key_pos[0], key_pos[1], key_pos[2])
						var bone_transform = Transform()
						bone_transform = bone_transform.rotated(Vector3(1, 0, 0), key_rot[0])
						bone_transform = bone_transform.rotated(Vector3(0, 1, 0), key_rot[1])
						bone_transform = bone_transform.rotated(Vector3(0, 0, 1), key_rot[2])
						var rotation = bone_transform.basis.get_rotation_quat()
						var scale = Vector3(1, 1, 1)
						
						if a.name == "Animation":
							animation.transform_track_insert_key(trackId, joint.key_frames_trans[j].time, position, rotation, scale)
						else:	
							animation.transform_track_insert_key(trackId, animation_offsets[a.name][bone_name], position, rotation, scale)
							animation_offsets[a.name][bone_name] += fr.duration
	
	root_node.add_child(animation_player)
	animation_player.set_owner(root_node)
	
	root_node.scale = Vector3.ONE * options.get("scale_modifier")
	
	#Loading material
	var material_path = source_file
	material_path.erase(material_path.length() - 5, 5)
	var material_file = File.new()
	if file.open(material_path + ".png", File.READ) == OK:
		var new_mat = SpatialMaterial.new()
		new_mat.albedo_texture = load(material_path + ".png")
		mesh_instance.set_surface_material(0, new_mat)

	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(root_node)
	if result == OK:
		return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)
		
	return ERR_CANT_CREATE
