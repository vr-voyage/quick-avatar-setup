extends Spatial

export(float) var rotate_speed = 0.5

onready var model_container:Spatial = $"Model"

var model_helpers = preload("res://helpers/model_helpers.gd")
onready var camera_pivot:Spatial = $"CameraPivot"
onready var camera_body:Camera = $"CameraPivot/CameraFullBody"
onready var camera_face:Camera = $"CameraPivot/CameraFace"

class Blendshape:
	# Serialized
	var rel_path:NodePath       = ""
	var blendshape_name:String  = ""
	var current_value:float     = 0
	var short_path:String       = ""

	# Private
	var cached_body:MeshInstance = null

	func set_to(val:float) -> bool:
		var body_valid:bool = (cached_body != null)
		if body_valid:
			cached_body.set("blend_shapes/" + blendshape_name, val)
		return body_valid

	func apply_current() -> bool:
		return set_to(current_value)

	func read_current_value() -> bool:
		var body_valid:bool = (cached_body != null)
		if body_valid:
			current_value = cached_body.get("blend_shapes/" + blendshape_name)
		return body_valid


	# Search for rel_path in the provided root_node and cache
	# the node, if it's the right type
	func attach_to(root_node:Node) -> bool:
		var node = root_node.get_node(rel_path)
		var got_the_right_node:bool = (node is MeshInstance)
		if node is MeshInstance:
			cached_body = node
		else:
			printerr(
				"Could not attach " + rel_path + 
				"(" + blendshape_name + ") to "
				+ str(root_node))
		return got_the_right_node

	func reset() -> void:
		set_to(0)

	func _init(
		body_rel_path:NodePath,
		new_blendshape_name:String):

		rel_path = body_rel_path
		blendshape_name = new_blendshape_name
		short_path = body_rel_path.get_name(body_rel_path.get_name_count() - 1)

	func serialize() -> Dictionary:
		return {
			"blendshape_name": blendshape_name,
			"rel_path": rel_path,
			"current_value": current_value,
			"short_path": short_path
		}

	static func from_serialized(serialized_values:Dictionary) -> Blendshape:
		var blendshape = Blendshape.new(
			serialized_values["rel_path"],
			serialized_values["blendshape_name"])
		blendshape.current_value = serialized_values["current_value"]
		return blendshape


class Blendshapes:
	var data:Array = []

	func add(blendshape:Blendshape):
		data.append(blendshape)

	func count() -> int:
		return data.size()

	func reset() -> void:
		for blendshape in data:
			blendshape.reset()

	func get_idx(blendshape_idx:int) -> Blendshape:
		return data[blendshape_idx]

	func attach_to(root_node:Node) -> int:
		var i = 0
		for blendshape in data:
			if blendshape.attach_to(root_node):
				i += 1
		return i

	func apply_values() -> int:
		var i = 0
		for blendshape in data:
			if blendshape.apply_current():
				i += 1
		return i

	func refresh_values() -> int:
		var i = 0
		for blendshape in data:
			if blendshape.read_current_value():
				i += 1
		return i

	func serialize() -> Array:
		var serialized_blendshapes = []
		for blendshape in data:
			serialized_blendshapes.append(blendshape.serialize())
		return serialized_blendshapes

	static func from_serialized(serialized_array:Array) -> Blendshapes:
		var blendshapes:Blendshapes = Blendshapes.new()

		for serialized_blendshape in serialized_array:
			blendshapes.add(Blendshape.from_serialized(serialized_blendshape))
		return blendshapes

class Emotion:
	var emotion_name:String
	var blendshapes:Blendshapes

	func _init(
		new_emotion_name:String,
		emotion_blendshapes:Blendshapes):

		emotion_name = new_emotion_name
		blendshapes = emotion_blendshapes

	func serialize() -> Dictionary:
		return {
			"emotion_name": emotion_name, 
			"blendshapes": blendshapes.serialize()
		}

	static func from_serialized(serialized_emotion:Dictionary) -> Emotion:
		return Emotion.new(
			serialized_emotion["emotion_name"],
			Blendshapes.from_serialized(serialized_emotion["blendshapes"])
		)

class Emotions:
	var data:Array = []

	func add_new(base_blendshapes:Blendshapes) -> Emotion:
		var emotion:Emotion = Emotion.new("untitled", base_blendshapes)
		data.append(emotion)
		return emotion

	func serialize() -> Dictionary:
		var serialized_emotions:Array = []
		for emotion in data:
			serialized_emotions.append(emotion.serialize())
		# FIXME Make the whole thing a real dictionary
		return {"data": serialized_emotions}

	func get_emotion(emotion_idx:int) -> Emotion:
		return data[emotion_idx]

	static func from_serialized(serialized_emotions:Dictionary) -> Emotions:
		var emotions = Emotions.new()
		# FIXME Make the whole thing a dictionary
		for serialized_emotion in serialized_emotions["data"]:
			emotions.data.append(Emotion.from_serialized(serialized_emotion))
		return emotions

	func delete_emotion(emotion_idx:int) -> bool:
		var can_remove:bool = emotion_idx < len(data)
		if can_remove:
			data.remove(emotion_idx)
		return can_remove

class AvatarSetup:
	const CURRENT_VERSION = 1
	var emotions:Emotions
	var version:int = CURRENT_VERSION

	static func from_serialized(serialized_avatar_setup:Dictionary) -> AvatarSetup:
		var avatar_setup = AvatarSetup.new()
		avatar_setup.emotions = Emotions.from_serialized(serialized_avatar_setup["emotions"])
		avatar_setup.version = int(serialized_avatar_setup["version"])
		return avatar_setup

	func serialize() -> Dictionary:
		return {
			"version": version,
			"emotions": emotions.serialize()
		}

	func _init():
		emotions = Emotions.new()

var model_blendshapes:Blendshapes

func get_blendshapes() -> Blendshapes:
	if model_blendshapes == null:
		refresh_model_blend_shapes()
	return model_blendshapes

func get_new_blendshapes() -> Blendshapes:
	var new_blendshapes:Blendshapes = Blendshapes.new()
	if $Model.get_child_count() > 0:
		var child = $Model.get_child(0)
		_search_for_blendshapes_from(child, new_blendshapes, child)
	return new_blendshapes

func get_blendshapes_reset(attached:bool) -> Blendshapes:
	var blendshapes:Blendshapes = get_blendshapes()
	attach_blendshapes(blendshapes)
	blendshapes.reset()
	return blendshapes

func _list_blendshapes(
	mesh_instance:MeshInstance,
	blendshapes_list:Blendshapes,
	root_node:Node) -> void:

	if mesh_instance.mesh is ArrayMesh:
		var array_mesh:ArrayMesh = mesh_instance.mesh
		for i in range(0, array_mesh.get_blend_shape_count()):
			var blendshape:Blendshape = Blendshape.new(
				root_node.get_path_to(mesh_instance),
				array_mesh.get_blend_shape_name(i))
			blendshapes_list.add(blendshape)

func _search_for_blendshapes_from(
	node:Node,
	blendshapes_list:Blendshapes,
	root_node:Node):

	if node is MeshInstance:
		_list_blendshapes(node, blendshapes_list, root_node)

	for child in node.get_children():
		_search_for_blendshapes_from(child, blendshapes_list, root_node)

func refresh_model_blend_shapes() -> void:

	model_blendshapes = get_new_blendshapes()

func attach_blendshapes(blendshapes:Blendshapes) -> int:
	var attached_blendshapes:int = 0
	if $Model.get_child_count() > 0:
		var child = $Model.get_child(0)
		attached_blendshapes = blendshapes.attach_to(child)
	return attached_blendshapes

signal model_loading_start()
signal model_loading_ended()

signal blendshapes_list_changed()

func add_vrm_model(filepath:String) -> void:
	var vrm_loader = load("res://addons/vrm/vrm_loader.gd").new()

	print("Pouiping VRM very much !")
	var result:Spatial = vrm_loader.import_vrm(filepath) as Spatial
	if result == null:
		printerr("Could not import " + filepath)
		return

	$Model.remove_child($Model.get_child(0))
	$Model.add_child(result)
	result.rotate_y(deg2rad(180))
	#result.transform.rotated(Vector3.UP, 180)
	#model_helpers.set_all_mats_to_unshaded(result)
	refresh_model_blend_shapes()
	emit_signal("blendshapes_list_changed")
	emit_signal("model_loading_ended")

func add_glb_model(filepath:String) -> void:
	var loader:PackedScene = null
	var gstate:Resource = null
	var result:Node = null
	if type_exists("GLTFState") and type_exists("PackedSceneGLTF"):
		print("GLTF: Using builtin gltf module")
		gstate = ClassDB.instance("GLTFState")
		loader = ClassDB.instance("PackedSceneGLTF")
		emit_signal("model_loading_start")
		result = loader.import_gltf_scene(filepath, 0, 1000.0, 0, gstate)
	else:
		gstate = load("res://addons/godot_gltf/GLTFState.gdns").new()
		loader = load("res://addons/godot_gltf/PackedSceneGLTF.gdns").new()
		emit_signal("model_loading_start")
		result = loader.import_gltf_scene(filepath, 0, 1000.0, gstate)

	if result is Node:
		if $Model.get_child_count() > 0:
			$Model.remove_child($Model.get_child(0))
		$Model.add_child(result)
		model_helpers.set_all_mats_to_unshaded(result)
		refresh_model_blend_shapes()
		emit_signal("blendshapes_list_changed")
	else:
		printerr("Bad result ?")
		print(result)
	emit_signal("model_loading_ended")

func reset_emotion() -> void:
	# FIXME ...
	if model_blendshapes == null:
		refresh_model_blend_shapes()
	attach_blendshapes(model_blendshapes)
	model_blendshapes.reset()

func current_emotion(emotion:Emotion) -> int:
	reset_emotion()
	attach_blendshapes(emotion.blendshapes)
	return emotion.blendshapes.apply_values()

var current_camera
onready var ui_camera_slider_y = $VBoxContainer/CameraSliderY
onready var ui_camera_slider_z = $VBoxContainer/CameraSliderZ

func _register_current_camera():
	current_camera = get_viewport().get_camera()

func _ready():
	select_camera_face()

func _on_camera_slider_y_value_changed(val:float):
	current_camera.transform.origin.y = val

func _on_camera_slider_z_value_changed(val:float):
	current_camera.transform.origin.z = val

func _setup_sliders_for_current_camera() -> void:
	# FIXME ... This should not be set here
	_register_current_camera()
	if (current_camera == null):
		printerr("!!!? There's no camera !?")
		ui_camera_slider_y.visible = false
		ui_camera_slider_z.visible = false
		return

	ui_camera_slider_y.disconnect("value_changed", self, "_on_camera_slider_y_value_changed")
	ui_camera_slider_z.disconnect("value_changed", self, "_on_camera_slider_z_value_changed")
	var camera_pos:Vector3 = current_camera.transform.origin
	ui_camera_slider_y.value = camera_pos.y
	ui_camera_slider_z.value = camera_pos.z
	ui_camera_slider_y.connect("value_changed", self, "_on_camera_slider_y_value_changed")
	ui_camera_slider_z.connect("value_changed", self, "_on_camera_slider_z_value_changed")

func select_camera_face():
	camera_body.current = false
	camera_face.current = true
	_setup_sliders_for_current_camera()

func select_camera_full_body():
	
	camera_face.current = false
	camera_body.current = true
	_setup_sliders_for_current_camera()

var dragging:bool = false
var panning:bool = false
var tilting:bool = false
var click_position:Vector2 = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		var mouse_press:InputEventMouseButton = event as InputEventMouseButton
		var mouse_button:int = mouse_press.button_index
		match mouse_button:
			1:
				dragging = mouse_press.pressed
				click_position = mouse_press.position
			2:
				tilting = mouse_press.pressed
			3:
				panning = mouse_press.pressed
			5:
				ui_camera_slider_z.value += (ui_camera_slider_z.step)
			4:
				ui_camera_slider_z.value += -(ui_camera_slider_z.step)


	if event is InputEventMouseMotion:
		var motion:InputEventMouseMotion = event
		if dragging:
			camera_pivot.rotate_y(deg2rad(-motion.relative.x * rotate_speed))
		if tilting:
			current_camera.rotate_x(deg2rad(-motion.relative.y * rotate_speed))
		if panning:
			#var direction:float = 1.0 if motion.relative.y > 0 else -1.0
			ui_camera_slider_y.value += (-motion.relative.y * 0.01)
		#var current_offset:Vector2 = event.position - click_position
		#if (current_offset.y < -30) || (current_offset.y > 30):
			#current_camera.rotate_x(deg2rad(motion.relative.y * rotate_speed))
		#else:

		

