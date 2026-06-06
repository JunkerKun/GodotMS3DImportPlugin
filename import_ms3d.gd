tool
extends EditorImportPlugin

class MS3DHeader:
	var id: String
	var version: int
	
class MS3DVertex:
	var flags: int
	var vertex: Array
	var boneId: int
	var referenceCount: int

	var boneIds: Array
	var weights: Array
	
class MS3DTriangle:
	var flags: int
	var vertexIndices: Array
	var vertexNormals: Array
	var s: Array
	var t: Array
	var smoothingGroup: int
	var groupIndex: int
	
class MS3DGroup:
	var flags: int
	var name: String
	var numTriangles: int
	var triangleIndices: Array
	var materialIndex: int
	
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
	
class MS3DKeyRot:
	var time: float
	var rotation: Array  
	
class MS3DKeyPos:
	var time: float
	var position: Array 
	
class MS3DJoint:
	var flags: int
	var name: String
	var parentName: String
	var rotation: Array
	var position: Array
	var numKeyFramesRot: int
	var numKeyFramesTrans: int
	var keyFramesRot: Array
	var keyFramesTrans: Array
	
class MS3DVertExt:
	var boneIds: Array
	var weights: Array
	var extra: Array

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
		{"name": "scale_modifier", "default_value": 1.0}
	]

func get_preset_count():
	return 1

func get_preset_name(preset):
	return "Default"
	
func addBone(skeleton, name, parentName):
	skeleton.add_bone(name)
	
	var parentId = skeleton.find_bone(parentName)
	var boneId = skeleton.find_bone(name) 
	
	skeleton.set_bone_parent(boneId, parentId)

	var boneTransform = Transform()
	boneTransform.origin = Vector3(0, 1, 0)

	skeleton.set_bone_rest(boneId, boneTransform)

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	#Reading file
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return ERR_FILE_CANT_OPEN
	
	var header = MS3DHeader.new()
	header.id = file.get_buffer(10).get_string_from_utf8()
	header.version = file.get_32()
	
	var numVertices = file.get_16()
	var vertices = Array()
	for i in range(numVertices):
		var vertex = MS3DVertex.new()
		vertex.flags = file.get_8()
		vertex.vertex = Array()
		vertex.vertex.append(file.get_float())
		vertex.vertex.append(file.get_float())
		vertex.vertex.append(file.get_float())
		vertex.boneId = file.get_8()
		vertex.referenceCount = file.get_8()
		vertices.append(vertex)
		
	var numTriangles = file.get_16()
	var triangles = Array()
	for i in range(numTriangles):
		var triangle = MS3DTriangle.new()
		triangle.flags = file.get_16()
		triangle.vertexIndices = Array()
		triangle.vertexIndices.append(file.get_16())
		triangle.vertexIndices.append(file.get_16())
		triangle.vertexIndices.append(file.get_16())
		triangle.vertexNormals = Array()
		var n1 = Array()
		n1.append(file.get_float())
		n1.append(file.get_float())
		n1.append(file.get_float())
		triangle.vertexNormals.append(n1)
		var n2 = Array()
		n2.append(file.get_float())
		n2.append(file.get_float())
		n2.append(file.get_float())
		triangle.vertexNormals.append(n2)
		var n3 = Array()
		n3.append(file.get_float())
		n3.append(file.get_float())
		n3.append(file.get_float())
		triangle.vertexNormals.append(n3)
		triangle.s = Array()
		triangle.s.append(file.get_float())
		triangle.s.append(file.get_float())
		triangle.s.append(file.get_float())
		triangle.t = Array()
		triangle.t.append(file.get_float())
		triangle.t.append(file.get_float())
		triangle.t.append(file.get_float())
		triangle.smoothingGroup = file.get_8()
		triangle.groupIndex = file.get_8()
		triangles.append(triangle)
	
	var numGroups = file.get_16()
	var groups = Array()
	for i in range(numGroups):
		var group = MS3DGroup.new()
		group.flags = file.get_8()
		group.name = file.get_buffer(32).get_string_from_utf8()
		group.numTriangles = file.get_16()
		group.triangleIndices = Array()
		for j in range(group.numTriangles):
			group.triangleIndices.append(file.get_16())
		group.materialIndex = file.get_8()
		groups.append(group)
		
	var numMaterials = file.get_16()
	var materials = Array()
	for i in range(numMaterials):
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
		
	var fAnimationFPS = file.get_float()
	var fCurrentTime = file.get_float()
	var iTotalFrames = file.get_float()

	var nNumJoints = file.get_16()
	var joints = Array()
	for i in range(nNumJoints):
		var joint = MS3DJoint.new()
		joint.flags = file.get_8()
		joint.name = file.get_buffer(32).get_string_from_utf8()
		joint.parentName = file.get_buffer(32).get_string_from_utf8()
		joint.rotation = Array()
		joint.rotation.append(file.get_float())
		joint.rotation.append(file.get_float())
		joint.rotation.append(file.get_float())
		joint.position = Array()
		joint.position.append(file.get_float())
		joint.position.append(file.get_float())
		joint.position.append(file.get_float())
		joint.numKeyFramesRot = file.get_16()
		joint.numKeyFramesTrans = file.get_16()
		joint.keyFramesRot = Array()
		for j in range(joint.numKeyFramesRot):
			var keyFrameRot = MS3DKeyRot.new()
			keyFrameRot.time = file.get_float()
			keyFrameRot.rotation = Array()
			keyFrameRot.rotation.append(file.get_float())
			keyFrameRot.rotation.append(file.get_float())
			keyFrameRot.rotation.append(file.get_float())
			joint.keyFramesRot.append(keyFrameRot)
		joint.keyFramesTrans = Array()
		for j in range(joint.numKeyFramesTrans):
			var keyFrameTrans = MS3DKeyPos.new()
			keyFrameTrans.time = file.get_float()
			keyFrameTrans.position = Array()
			keyFrameTrans.position.append(file.get_float())
			keyFrameTrans.position.append(file.get_float())
			keyFrameTrans.position.append(file.get_float())
			joint.keyFramesTrans.append(keyFrameTrans)
		
		joints.append(joint)
		
	#Skipping comments
	var subVersion = file.get_32()
	var nNumGroupComments = file.get_32()
	for i in range(nNumGroupComments):
		var index = file.get_32()
		var commentLength = file.get_32()
		var comment = file.get_buffer(commentLength).get_string_from_utf8()
		
	var nNumMaterialComments = file.get_32()
	for i in range(nNumMaterialComments):
		var index = file.get_32()
		var commentLength = file.get_32()
		var comment = file.get_buffer(commentLength).get_string_from_utf8()
		
	var nNumJointComments = file.get_32()
	for i in range(nNumJointComments):
		var index = file.get_32()
		var commentLength = file.get_32()
		var comment = file.get_buffer(commentLength).get_string_from_utf8()
		
	var nHasModelComment = file.get_32()
	for i in range(nHasModelComment):
		var index = file.get_32()
		var commentLength = file.get_32()
		var comment = file.get_buffer(commentLength).get_string_from_utf8()
		
	subVersion = file.get_32()
	var weights: Array
	for i in range(numVertices):
		var weight = MS3DVertExt.new()
		weight.boneIds = Array()
		weight.boneIds.append(0)
		var id = file.get_8()
		if id & 128:
			id = id - 256
		weight.boneIds.append(id)
		id = file.get_8()
		if id & 128:
			id = id - 256
		weight.boneIds.append(id)
		id = file.get_8()
		if id & 128:
			id = id - 256
		weight.boneIds.append(id)
		weight.weights = Array()
		weight.weights.append(file.get_8() / 100.0)
		weight.weights.append(file.get_8() / 100.0)
		weight.weights.append(file.get_8() / 100.0)
		weight.extra = Array()
		if subVersion == 2:
			weight.extra.append(file.get_32())
		weights.append(weight)
		
	for i in range(numVertices):
		var weight = weights[i]
		weight.boneIds[0] = vertices[i].boneId
		if weight.boneIds[1] == -1:
			weight.boneIds[1] = 0
		if weight.boneIds[2] == -1:
			weight.boneIds[2] = 0
		if weight.boneIds[3] == -1:
			weight.boneIds[3] = 0
		weight.weights.append(1.0 - weight.weights[0] - weight.weights[1] - weight.weights[2])
		
	file.close()
		
	#Creating nodes structure
	var rootNode = Spatial.new()
	rootNode.name = source_file.get_file().get_basename()
	
	var skeletonNode = Spatial.new()
	skeletonNode.name = "Skeleton"
	rootNode.add_child(skeletonNode)
	skeletonNode.set_owner(rootNode)
	
	var skeleton = Skeleton.new()
	skeleton.name = "Skeleton3D"
	for i in range(joints.size()):
		addBone(skeleton, joints[i].name, joints[i].parentName)
		
		var boneId = skeleton.find_bone(joints[i].name)
		var boneTransform = Transform()

		boneTransform = boneTransform.rotated(Vector3(1, 0, 0), joints[i].rotation[0])
		boneTransform = boneTransform.rotated(Vector3(0, 1, 0), joints[i].rotation[1])
		boneTransform = boneTransform.rotated(Vector3(0, 0, 1), joints[i].rotation[2])
		
		boneTransform.origin = Vector3(
			joints[i].position[0], 
			joints[i].position[1], 
			joints[i].position[2]
		)
		
		skeleton.set_bone_rest(boneId, boneTransform)
		
	skeletonNode.add_child(skeleton)
	skeleton.set_owner(rootNode)
	
	var meshInstance = MeshInstance.new()
	meshInstance.name = "Mesh"
	meshInstance.mesh = ArrayMesh.new()
	
	var v = PoolVector3Array()
	var n = PoolVector3Array()
	var st = PoolVector2Array()
	var b = PoolIntArray()
	var w = PoolRealArray()
	for i in range(triangles.size()):
		var tri = triangles[i]
		var v1 = vertices[tri.vertexIndices[0]].vertex
		var v2 = vertices[tri.vertexIndices[1]].vertex
		var v3 = vertices[tri.vertexIndices[2]].vertex
		var w1 = weights[tri.vertexIndices[0]]
		var w2 = weights[tri.vertexIndices[1]]
		var w3 = weights[tri.vertexIndices[2]]
		var n1 = tri.vertexNormals[0]
		var n2 = tri.vertexNormals[1]
		var n3 = tri.vertexNormals[2]
		
		n.append(Vector3(n1[0], n1[1], n1[2]))
		v.append(Vector3(v1[0], v1[1], v1[2]))
		st.append(Vector2(tri.s[0], tri.t[0]))
		b.append_array([w1.boneIds[0], w1.boneIds[1], w1.boneIds[2], w1.boneIds[3]])
		w.append_array([w1.weights[0], w1.weights[1], w1.weights[2], w1.weights[3]])
		
		n.append(Vector3(n2[0], n2[1], n2[2]))
		v.append(Vector3(v2[0], v2[1], v2[2]))
		st.append(Vector2(tri.s[1], tri.t[1]))
		b.append_array([w2.boneIds[0], w2.boneIds[1], w2.boneIds[2], w2.boneIds[3]])
		w.append_array([w2.weights[0], w2.weights[1], w2.weights[2], w2.weights[3]])
		
		n.append(Vector3(n3[0], n3[1], n3[2]))
		v.append(Vector3(v3[0], v3[1], v3[2]))
		st.append(Vector2(tri.s[2], tri.t[2]))
		b.append_array([w3.boneIds[0], w3.boneIds[1], w3.boneIds[2], w3.boneIds[3]])
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
	meshInstance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	skeleton.add_child(meshInstance)
	meshInstance.set_owner(rootNode)
	
	var animation = Animation.new()
	animation.length = joints[0].keyFramesRot.size()
	
	for i in range(nNumJoints):
		var joint = joints[i]
		var boneName = skeleton.get_bone_name(i)
		var path = str(rootNode.get_path_to(skeleton)) + ":" + boneName
		var nodePath = NodePath(path)
		var trackId = animation.find_track(nodePath)
		if trackId == -1:
			trackId = animation.add_track(Animation.TYPE_TRANSFORM)
			animation.track_set_path(trackId, nodePath)
			
		for j in range(joint.keyFramesTrans.size()):
			var keyPos = joint.keyFramesTrans[j].position
			var keyRot = joint.keyFramesRot[j].rotation
			
			var position = Vector3(keyPos[0], keyPos[1], keyPos[2])
			var boneTransform = Transform()
			boneTransform = boneTransform.rotated(Vector3(1, 0, 0), keyRot[0])
			boneTransform = boneTransform.rotated(Vector3(0, 1, 0), keyRot[1])
			boneTransform = boneTransform.rotated(Vector3(0, 0, 1), keyRot[2])
			var rotation = boneTransform.basis.get_rotation_quat()
			var scale = Vector3(1, 1, 1)
			
			animation.transform_track_insert_key(trackId, joint.keyFramesTrans[j].time, position, rotation, scale)

	var animationPlayer = AnimationPlayer.new()
	animationPlayer.add_animation("Animation", animation)
	
	rootNode.add_child(animationPlayer)
	animationPlayer.set_owner(rootNode)
	
	rootNode.scale = Vector3.ONE * options.get("scale_modifier")
	
	#Loading material
	var materialPath = source_file
	materialPath.erase(materialPath.length() - 5, 5)
	var materialFile = File.new()
	if file.open(materialPath + ".png", File.READ) == OK:
		var newMat = SpatialMaterial.new()
		newMat.albedo_texture = load(materialPath + ".png")
		meshInstance.set_surface_material(0, newMat)

	var packedScene = PackedScene.new()
	var result = packedScene.pack(rootNode)
	if result == OK:
		return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packedScene)
		
	return ERR_CANT_CREATE
