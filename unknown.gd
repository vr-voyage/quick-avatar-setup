extends Spatial

var blendshapes:PoolStringArray = PoolStringArray()
var blendshapes_values:PoolRealArray = PoolRealArray()

onready var model_container:Spatial = $"Model"

func get_blendshapes_names() -> PoolStringArray:
	return blendshapes
func get_blendhsapes_values() -> PoolRealArray:
	return blendshapes_values

func _get_model_mesh_instances(node:Spatial, arr:Array):
	if node is MeshInstance:
		arr.append(node)
	for child in node.get_children():
		_get_model_mesh_instances(child, arr)

func get_model_mesh_instances() -> Array:
	var returned_array:Array = Array()
	for child in model_container:
		_get_model_mesh_instances(child, returned_array)
	return returned_array

func get_model_meshes_with_shapekeys() -> Dictionary:
	var returned_dic:Dictionary = Dictionary()
	var mesh_instances:Array = get_model_mesh_instances()
	for mi_ in mesh_instances:
		var mi:MeshInstance = mi_
		if mi.mesh is ArrayMesh:
			var mi_mesh:ArrayMesh = mi.mesh
			var blendshapes_names:PoolStringArray = PoolStringArray()
			for i in range(0, mi_mesh.get_blend_shape_count()):
				blendshapes_names.append(mi_mesh.get_blend_shape_name(i))
			if blendshapes_names.size() > 0:
				returned_dic[mi.get_path()] = blendshapes_names
	return returned_dic

func refresh_model_blend_shapes() -> void:
	var mesh : ArrayMesh = get_model_mesh()
	var shapes : PoolStringArray = PoolStringArray()
	for i in range(0, mesh.get_blend_shape_count()):
		shapes.append(mesh.get_blend_shape_name(i))
	blendshapes = shapes

func blendshapes_reset() -> void:
	var body = get_model_body()
	for blendshape_name in blendshapes:
		_set_model_shapekey(blendshape_name, 0, body)

func _set_model_shapekey(blendshape_name:String, blendshape_value:float, body) -> void:
	var idx:int = HelpersArrays.array_find_value(blendshapes, blendshape_name)
	if idx != -1:
		body.set("blend_shapes/" + blendshape_name, blendshape_value)
		blendshapes_values[idx] = blendshape_value

func blendshapes_set_with_names(blendshapes_names:Dictionary):
	var body = get_model_body()
	for blendshape_name in blendshapes_names:
		blendshape_value = blendshapes_names[blendshape_name]
		body.set("blend_shapes/" + blendshape_name, blendshape_value)

func _ready():
	refresh_model_blend_shapes()
	pass

func set_model_shapekey(shapekey_name:String, shapekey_level:float = 1.0) -> void:
	var idx:int = HelpersArrays.array_find_value(blendshapes)
	get_model_body().set("blend_shapes/" + shapekey_name, shapekey_level)
