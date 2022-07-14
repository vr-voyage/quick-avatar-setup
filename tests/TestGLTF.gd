extends Spatial

func _manage_dropped_files(filepaths:PoolStringArray, screen) -> void:
	if len(filepaths) < 1:
		printerr("WTF ? filepaths length is %d" % len(filepaths))
		return

	var gltf_importer:PackedSceneGLTF = PackedSceneGLTF.new()
	var gltf_filepath:String = filepaths[0]
	var node:Node = gltf_importer.import_gltf_scene(gltf_filepath)
	if node != null:
		add_child(node)
	else:
		printerr("Could not load %s" % gltf_filepath)

func _ready():
	get_tree().connect("files_dropped", self, "_manage_dropped_files")


