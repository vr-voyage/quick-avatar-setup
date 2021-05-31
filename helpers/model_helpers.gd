extends Spatial

onready var model_mesh = $Model/Armature/Skeleton/Body

static func _set_mat_to_unshaded(mat:Material):
	if (mat == null):
		printerr("Mat is null :C")
		return
	if not mat is SpatialMaterial:
		printerr("I don't know how to set 'unshaded on " + str(mat))
		return
	var spatialmat:SpatialMaterial = mat
	spatialmat.flags_unshaded = true

static func _set_array_mesh_mats_to_unshaded(mesh:ArrayMesh):
	var n_surfaces_count:int = mesh.get_surface_count()
	for i in range(0, n_surfaces_count):
		_set_mat_to_unshaded(mesh.surface_get_material(i))

static func set_all_mats_to_unshaded(node:Node):
	if node is MeshInstance:
		if node.mesh is ArrayMesh:
			_set_array_mesh_mats_to_unshaded(node.mesh)

	for child in node.get_children():
		set_all_mats_to_unshaded(child)

# Unused, since the MeshInstance materials are typically
# overrides for a specific instance
static func _set_mesh_instance_mats_to_unshaded(mi:MeshInstance):
	var n_mat_count:int = mi.get_surface_material_count()
	for i in range(0, n_mat_count):
		_set_mat_to_unshaded(mi.get_surface_material(i))

# Used for testing
#func _ready():
	# model_mesh.mesh.get_surface_count()
	#set_all_mats_to_unshaded($Model)
	#pass # Replace with function body.
